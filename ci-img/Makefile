IMAGE_NAME ?= razorci/img

# docker image publishing options
DOCKER_PUSH=false
LATEST_TAG=22.04

build := $(patsubst %/Dockerfile,build-%, $(wildcard */Dockerfile))
	
build-%: %/Dockerfile
	docker build -f $*/Dockerfile -t ${IMAGE_NAME}:$* .
	@if [ $* = $(LATEST_TAG) ]; then \
		docker tag ${IMAGE_NAME}:$* ${IMAGE_NAME}:latest; \
	fi

	@if [ "$(DOCKER_PUSH)" = "true" ]; then \
		docker push ${IMAGE_NAME}:$*; \
		if [ $* = $(LATEST_TAG) ]; then \
			docker push ${IMAGE_NAME}:latest; \
		fi; \
	fi
