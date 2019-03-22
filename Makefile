DOCKER_TAG=cuda-caps-`grep TF_CUDA_COMPUTE_CAPABILITIES .tf_configure.bazelrc | cut -d '=' -f 2 | tr -d '"'`
CUDA_VERSION=`grep ARG Dockerfile | grep CUDA_VERSION | cut -d '=' -f 2`
TENSORFLOW_VERSION=`grep ARG Dockerfile | grep TENSORFLOW_VERSION | cut -d '=' -f 2`
IMAGE_NAME="cuda-$(CUDA_VERSION)-tensorflow-$(TENSORFLOW_VERSION)"

build:
	docker build -t $(IMAGE_NAME):$(DOCKER_TAG) .
        
extract-libraries:
	mkdir -p shared-$(DOCKER_TAG)
	docker run --rm -v `pwd`/shared-$(DOCKER_TAG):/shared -v `pwd`/ccache:/ccache $(IMAGE_NAME):$(DOCKER_TAG) \
                                    bash -c 'cp /work/tensorflow/bazel-bin/tensorflow/libtensorflow_cc.so /shared && \
                                    		cp /work/tensorflow/bazel-bin/tensorflow/libtensorflow_framework.so /shared '
