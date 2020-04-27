
This repo contains scripts to generate language specific dockerfiles, building docker images.

To generate manifests for a language (under `language` directory), run

        rake generate:dockerfile[<lang>] DIR=/tmp/dockerfiles