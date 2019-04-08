# Introduction
Tensorflow (by default 1.12.0) build inside a Docker container with CUDA (by default 10.0), based on Ubuntu (by default 18.04) . Used to build `libensorflow_cc.so` (without`tensorflow_framework.so` because the build is monolithic i.e. static). Can be adapted to build the PIP package - just change the bazel target

## How to use

### Find out which CUDA Capabilities you need
To find out which capabilities are for you check [Wikipedia's CUDA article](https://en.wikipedia.org/wiki/CUDA). Then edit `.tf_configure.bazelrc` and set `TF_CUDA_COMPUTE_CAPABILITIES` to whatever suits you.

### Tweaking the Build
To change different aspects of the build, please change them in `.tf_configure.bazelrc-$TENSORFLOW_VERSION`. If you dont' want to build with TensorRT check the Dockerfile and comment the appropriate portion of code. TensorRT is installed by default for CUDA 10.0 in version 5.1.2. See the Dockerfile for the installation of the dev and the runtime deb packages.

### Building
Tensorflow is built with Bazel 0.15.0. Just run `make build`. This will build a container with the tag `cuda-CX.CY-tensorflow-TX.TY:cuda-caps-X.Y`. `CX.CY` is the CUDA version and `TX.TY` is the Tensorflow version. The official documentation lists Bazel 0.15.0 as tested for TF 1.10.0, 1.10.1, 1.11.0 and 1.12.0. For TF 1.13.1 they list Bazel 0.19.2 . I was able to build everything but 1.13.1 (with switched off TRT) with many different Bazel versions. 0.18.0 seems to work without probs. Even 0.20 works for some versions. Probably the best is to stick with the officially listed versions.

### Build times
It takes 40 minutes to build the C++ library on a 6-core Intel(R) Xeon(R) CPU E5-1660 v2 @ 3.70GHz. The wheel package takes about 90 minutes to build.


### Extracting the libraries
To get the compiled libraries, just run `make extract-libraries`. libtensorflow_cc.so and libtensorflow_framework.so (in case  when --config=monolithic is NOT used) will be copied into newly created directory called `shared-cuda-caps-X.Y` . If you build with TensorRT suppor also `_trt_engine_op.so` will be in the shared directory. By default also the wheel package for Python is built. It will also be copied to the shared directory.
