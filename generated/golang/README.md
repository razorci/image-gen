## Razorops Convenience Image for GO

Razorops is a modern Docker-native CI/CD platform to build, test and deploy your applications faster. This repository contains the pre-built convenience images for GO programming language which includes most common tools and maintained by our engineers.

The source-code for Dockerfiles are available on [Github](https://github.com/razorci/image-gen/tree/master/generated/golang).

### How to use

We have provided detailed instructions to write [CI spec](https://docs.razorops.com/guides/golang) for GO and [example projects](https://docs.razorops.com/guides/examples/) which you can fork to get started quickly.

You can refer these images in Razorops YAML file like -

```
tasks:
  hello-job:
    runner: razorci/golang:<version>
    steps:
    - git --version
    - checkout
    - echo "Hello World"
```

To more about Razorops YAML, please refer [here](https://docs.razorops.com/config/spec/).

### Contribution

If you have any problems with this image, please contact us over email (support@razorops.com).
