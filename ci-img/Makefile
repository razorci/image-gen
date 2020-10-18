IMAGE_NAME ?= razorci/img
IMAGE_TAG=2004-v2

# docker image publishing options
DOCKER_PUSH=false

${IMAGE_TAG}:
	docker build -f 20.04/Dockerfile -t ${IMAGE_NAME} .
	docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${IMAGE_TAG}

	@if [ "$(DOCKER_PUSH)" = "true" ]; then \
		docker push ${IMAGE_NAME}:latest ;\
		docker push ${IMAGE_NAME}:${IMAGE_TAG} ;\
	fi
