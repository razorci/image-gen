FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# COnfigure environment
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90razor && \
	echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90razor && \
	apt-get update && apt-get install -y locales && \
	locale-gen en_US.UTF-8 && \
	rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US:en \
	LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
		ca-certificates \
		curl \
		git \
		gnupg \
		gzip \
		jq \
		make \
		net-tools \
		netcat \
		sudo \
		tar \
		tzdata \
		unzip \
		wget \
		zip && \
	rm -rf /var/lib/apt/lists/*

## Install Docker
ENV DOCKER_VERSION=27.2.0
ARG DOCKER_GID=999
RUN DIR=$(mktemp -d) \
	&& DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
	&& echo Docker URL: ${DOCKER_URL} \
	&& curl -sL --output ${DIR}/docker.tgz ${DOCKER_URL} \
	&& echo "Downloaded at $DIR" \
	&& ls -lha ${DIR}/docker.tgz \
	&& tar -xz -C ${DIR} -f ${DIR}/docker.tgz \
	&& mv ${DIR}/docker/* /usr/bin \
	&& rm -rf ${DIR} \
	&& groupadd -g "$DOCKER_GID" -r docker \
	&& which docker \
	&& (docker version || true)

# Install Docker Compose - see prerequisite above
ENV COMPOSE_VER 2.29.2
ENV COMPOSE_SWITCH_VERSION 1.0.5
RUN dockerPluginDir=/usr/local/lib/docker/cli-plugins && \
	mkdir -p $dockerPluginDir && \
	curl -sSL "https://github.com/docker/compose/releases/download/v${COMPOSE_VER}/docker-compose-linux-$(uname -m)" -o $dockerPluginDir/docker-compose && \
	chmod +x $dockerPluginDir/docker-compose && \
	curl -fL "https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-$(dpkg --print-architecture)" -o /usr/local/bin/compose-switch && \
	# Quick test of the Docker Compose install
	docker compose version && \
	chmod +x /usr/local/bin/compose-switch && \
	update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99 && \
	# Tests if docker-compose for v1 is transposed to v2
	docker-compose version

# Install Dockerize v0.8.0
# Source repo: https://github.com/jwilder/dockerize
RUN curl -sSL --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz "https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" && \
	tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz && \
	rm -rf /tmp/dockerize-linux-amd64.tar.gz && \
	dockerize --version

RUN useradd --uid=3434 --user-group --create-home razor && \
	usermod -a -G sudo,docker razor && \
	echo 'razor ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-razor && \
	echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

USER razor
