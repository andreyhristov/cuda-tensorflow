ARG CUDA_VERSION=10.0
ARG UBUNTU_VERSION=18.04

FROM nvidia/cuda:$CUDA_VERSION-cudnn7-devel-ubuntu$UBUNTU_VERSION

RUN sed -i "s/archive.ubuntu.com/bg.archive.ubuntu.com/" /etc/apt/sources.list
RUN \   
        apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libopencv-dev \
                libtinyxml2-6 \
                libtinyxml2-dev \
                libgstreamer1.0-0 \
                libgstreamer1.0-dev \
                libeigen3-dev \
                libc-bin \
                python3-dev \
                python3-pip \
                openjdk-8-jdk-headless \
                curl \
                wget \
                python \
                unzip \
                bash-completion \
                joe less \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir /work
WORKDIR /work

ARG TENSORFLOW_VERSION=1.12.0
ARG BAZEL_VERSION=0.15.0


RUN wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/libnvinfer-dev_5.1.2-1+cuda10.0_amd64.deb && \
    wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/libnvinfer5_5.1.2-1+cuda10.0_amd64.deb && \
    dpkg -i libnvinfer-dev_5.1.2-1+cuda10.0_amd64.deb libnvinfer5_5.1.2-1+cuda10.0_amd64.deb && \
    rm libnvinfer-dev_5.1.2-1+cuda10.0_amd64.deb libnvinfer5_5.1.2-1+cuda10.0_amd64.deb

RUN wget https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel_$BAZEL_VERSION-linux-x86_64.deb \
        && dpkg -i bazel_$BAZEL_VERSION-linux-x86_64.deb \
        && rm bazel_$BAZEL_VERSION-linux-x86_64.deb

RUN wget https://github.com/tensorflow/tensorflow/archive/v$TENSORFLOW_VERSION.tar.gz -O tensorflow.tar.gz \
        && tar zxvf tensorflow.tar.gz \
        && rm tensorflow.tar.gz \
        && mv tensorflow-$TENSORFLOW_VERSION tensorflow

ENV TMP /tmp


ADD .bazelrc /work/tensorflow
ADD .tf_configure.bazelrc-$TENSORFLOW_VERSION /work/tensorflow/.tf_configure.bazelrc
RUN cat /work/tensorflow/.tf_configure.bazelrc

# Only with 1.10.0
#ADD infeed_manager.cc.patch /work/tensorflow
#RUN cd /work/tensorflow && patch -p1 < infeed_manager.cc.patch

ADD BUILD.patch-$TENSORFLOW_VERSION /work/tensorflow/BUILD.patch
RUN cd /work/tensorflow && patch -p0 < BUILD.patch

# The following addition to LD path is needed or the bazel build will break with errors due to undefined references
# See https://github.com/tensorflow/tensorflow/issues/13243
# If you don't want to do this, thenn just build with `bazel build --config=opt --config=monolithic //tensorflow:libtensorflow_cc.so`
# In case of monolithic build there is only one build artefact - libtensorflow_cc.so and there is no libtensorflow_framework.so
RUN echo "/usr/local/cuda/targets/x86_64-linux/lib/stubs" >> /etc/ld.so.conf.d/cuda-10-0.conf && ldconfig

RUN cd /work/tensorflow && bazel build --config=opt --config=monolithic //tensorflow:libtensorflow_cc.so

RUN pip3 install numpy pandas && \
    pip3 install keras_applications==1.0.4 --no-deps && \
    pip3 install keras_preprocessing==1.0.2 --no-deps && \
    pip3 install h5py==2.8.0

RUN cd /work/tensorflow && \
	bazel build --config=opt --config=monolithic \
		//tensorflow/contrib/tensorrt:trt_engine_op_loader \
		//tensorflow/contrib/tensorrt:python/ops/_trt_engine_op.so

RUN cd /work/tensorflow && bazel build --config=opt --config=monolithic //tensorflow/tools/pip_package:build_pip_package

RUN pip3 install virtualenv
RUN virtualenv --system-site-packages -p python3 ./venv
RUN bash -c "source venv/bin/activate && cd tensorflow && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg"
