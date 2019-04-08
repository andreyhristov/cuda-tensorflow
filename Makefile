$(eval TENSORFLOW_VERSION := "$(shell grep ARG Dockerfile | grep TENSORFLOW_VERSION | cut -d '=' -f 2)")
$(eval CUDA_CAPS := "$(shell grep TF_CUDA_COMPUTE_CAPABILITIES .tf_configure.bazelrc-$(TENSORFLOW_VERSION) | cut -d '=' -f 2 | tr -d '\"')")
$(eval DOCKER_TAG := "$(shell echo cuda-caps-$(CUDA_CAPS))")
$(eval CUDA_VERSION := "$(shell grep ARG Dockerfile | grep CUDA_VERSION | cut -d '=' -f 2)")
$(eval IMAGE_NAME := "$(shell echo cuda-$(CUDA_VERSION)-tensorflow-$(TENSORFLOW_VERSION))")


build: info
	docker build -t $(IMAGE_NAME):$(DOCKER_TAG) .
        
extract-libraries: info
	mkdir -p shared-$(DOCKER_TAG)
	docker run --rm -v `pwd`/shared-$(DOCKER_TAG):/shared $(IMAGE_NAME):$(DOCKER_TAG) \
                                    bash -c 'cp /work/tensorflow/bazel-bin/tensorflow/libtensorflow_cc.so /shared ; \
				             cp /work/tensorflow/bazel-bin/tensorflow/libtensorflow_framework.so /shared ; \
				             cp /work/tensorflow/bazel-bin/tensorflow/contrib/tensorrt/libtrt_engine_op_kernel.so /shared ; \
				             cp /work/tensorflow/bazel-bin/tensorflow/contrib/tensorrt/python/ops/_trt_engine_op.so /shared ; \
				             cp /work/tensorflow/bazel-bin/tensorflow/contrib/tensorrt/libtrt_resources.so /shared ; \
				             cp /tmp/tensorflow_pkg/tensorflow-*.whl /shared '

info:
	@echo TF_VERSION   :$(TENSORFLOW_VERSION)
	@echo DOCKER_TAG   :$(DOCKER_TAG)
	@echo CUDA_VERSION :$(CUDA_VERSION)
	@echo CUDA_CAPS    :$(CUDA_CAPS)
	@echo IMAGE_NAME   :$(IMAGE_NAME)
