ARG CUDA_VERSION=10.0
ARG UBUNTU_VERSION=18.04

FROM nvidia/cuda:$CUDA_VERSION-cudnn7-devel-ubuntu$UBUNTU_VERSION
ARG TENSORFLOW_VERSION=1.10.0


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
                ccache \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir /work
WORKDIR /work

# If you want to install TensorRT, uncomment the following lines. Keep in mind that TensorRT accelerates
# only Python code and not code that uses the C++ API.
# For more information please check this: https://docs.nvidia.com/deeplearning/dgx/integrate-tf-trt/index.html
#
#ADD nv-tensorrt-repo-ubuntu1804-cuda10.0-trt5.0.2.6-ga-20181009_1-1_amd64.deb /work
#RUN dpkg -i nv-tensorrt-repo-ubuntu1804-cuda10.0-trt5.0.2.6-ga-20181009_1-1_amd64.deb
#RUN apt update && apt install -y tensorrt

RUN wget https://github.com/bazelbuild/bazel/releases/download/0.18.0/bazel_0.18.0-linux-x86_64.deb \
        && dpkg -i bazel_0.18.0-linux-x86_64.deb \
        && rm bazel_0.18.0-linux-x86_64.deb

RUN wget https://github.com/tensorflow/tensorflow/archive/v$TENSORFLOW_VERSION.tar.gz -O tensorflow.tar.gz \
        && tar zxvf tensorflow.tar.gz \
        && rm tensorflow.tar.gz \
        && mv tensorflow-$TENSORFLOW_VERSION tensorflow

ADD .bazelrc /work/tensorflow
ADD .tf_configure.bazelrc /work/tensorflow
ADD infeed_manager.cc.patch /work/tensorflow
RUN cat /work/tensorflow/.tf_configure.bazelrc

ENV TMP /tmp

RUN mkdir /ccache
ENV CCACHE_DIR /ccache
ENV CC_PREFIX ccache

RUN cd /work/tensorflow && patch -p1 < infeed_manager.cc.patch
RUN cd /work/tensorflow && bazel build --config=opt --config=monolithic //tensorflow:libtensorflow_cc.so
