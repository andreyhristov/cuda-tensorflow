# Introduction
Tensorflow (by default 1.10) build inside a Docker container with CUDA (by default 10.0), based on Ubuntu (by default 18.04) . Used to build `libensorflow_cc.so` (without`tensorflow_framework.so` because the build is monolithic i.e. static). Can be adapted to build the PIP package - just change the bazel target

## How to use

### Find out which CUDA Capabilities you need
To find out which capabilities are for you check [Wikipedia's CUDA article](https://en.wikipedia.org/wiki/CUDA). Then edit `.tf_configure.bazelrc` and set `TF_CUDA_COMPUTE_CAPABILITIES` to whatever suits you.

### Tweaking the Build
To change different aspects of the build, please change them in `.tf_configure.bazelrc`. If you want to build with TensorRT check the Dockerfile and uncomment the appropriate portion of code. You need to download TensorRT's local deb repository file from Nvidia's web site and put it in the directory next to the Dockefile. TensorRT can be downloaded from [here](https://developer.nvidia.com/nvidia-tensorrt-5x-download). You need to have a NVidia developer account to access it.

### Building
Tensorflow is built with Bazel 0.18. Just run `make build`. This will build a container with the tag `cuda-CX.CY-tensorflow-TX.TY:cuda-caps-X.Y`. `CX.CY` is the CUDA version and `TX.TY` is the Tensorflow version.

### Extracting the libraries
To get the compiled libraries, just run `make extract-libraries`. libtensorflow_cc.so and libtensorflow_framework.so will be copied into newly created directory called `shared-cuda-caps-X.Y`
