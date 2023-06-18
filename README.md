
### Overview

This repo contains scripts to generate language specific dockerfiles and building VM/container images for CI environment.

Mainly it contains two `rake` commands.

### 1. Getting Started

Install the dependencies using `bundle`

        bundle install

### 2. Generating Dockerfile

The list of supported progamming languages can be found under `languages` folder. These files defines the base docker image 
and common system libraries needed in a CI environment. 

To generate dockerfiles for a language

        rake generate:dockerfile[<lang>] DIRECTORY=generated

It would also generate a `manifest.json` while consists the docker image name, it's variants and tags.

You can bump following tools before generating the dockerfiles -

        GRADLE_VERSION
        ANT_VERSION
        lein_tag / LEIN_VERSION
        SBT_VERSION
        MAVEN_VERSION

### 3. Building container images

Step2 will generate various manifest files along with dockerfiles for the latest versions/tags. To build the customized
container images 

        rake generate:build[<lang>] DIRECTORY=generated

The above commands supports following environment variables -
|   Name       |  Default Value     |      Description                                                |
|--------------|--------------------|------------------------|
|`CI`          |     N/A            | If present, it will build the container images 
|`DIRECTORY`   |   `dockerfiles`    | The directory path where manifests are generated |
|`TAGS`        |     `ALL`          | Optionally specify which tags to consider
|`DOCKER_PUSH` |      N/A           | Push to dockerhub if present

Example: `rake generate:build[ruby] CI=true DOCKER_PUSH=true DIRECTORY=generated TAGS=2`

### Updating base image

Please follow [ci-img](./ci-img/README.md) README for upgrading.
### Updating dependencies in language runtimes

We also add few dependencies along with standard language tooling - docker, docker-compose, git. You might want to change the versions before re-generating the Dockerfile(s).

For `nodejs` variants, we fetch the lts version from the github (nodejs) and try to infer the extracted version.
