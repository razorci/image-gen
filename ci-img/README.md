## Overview

`ci-img` is a general purpose docker image containing core utilities and C/C++ tooltain which can be used to create Custom Build environment on Razorops platform.

To know more about "[Custom build environment][1]", please follow to the link.

### How to build

* Bump up the `IMAGE_TAG` in Makefile

* Build and push the container image

        make build-<IMAGE_TAG> DOCKER_PUSH=true

For example `make build-22.04` and `make build-20.04`

### How to use in Razorops

To execute the jobs in a custom build environment, you need to assign `runner` property in `.razorops.yaml` file - 

```
tasks:
  unit-test:
    # any container image having required tools installed
    runner: razorci/img:22.04
    steps:
    - echo hello world
```

[1]: https://docs.razorops.com/pipeline/docker/custom-environment/