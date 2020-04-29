
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

        rake generate:dockerfile[<lang>] DIRECTORY=/tmp/dockerfiles

It would also generate a `manifest.json` while consists the docker image name, it's variants and tags.

### 3. Building container images

Step2 will generate various manifest files along with dockerfiles for the latest versions/tags. To build the customized
container images 

        rake generate:build[<lang>]

The above commands supports following environment variables -
|   Name       |  Default Value      |      Description                                                |
|--------------|---------------------|------------------------|
|`CI`          |     N/A            |  If present, it will push the container images into the docker registry 
|`DIRECTORY`   |   `dockerfiles`    | The directory path where manifests are generated |
|`TAGS`        |     `ALL`          | Optionally specify which tags to consider
