FROM ubuntu:20.04

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
ENV DOCKER_VERSION=19.03.9
RUN DIR=$(mktemp -d) \
	&& DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
	&& echo Docker URL: ${DOCKER_URL} \
	&& curl -sL --output ${DIR}/docker.tgz ${DOCKER_URL} \
	&& echo "Downloaded at $DIR" \
	&& ls -lha ${DIR}/docker.tgz \
	&& tar -xz -C ${DIR} -f ${DIR}/docker.tgz \
	&& mv ${DIR}/docker/* /usr/bin \
	&& rm -rf ${DIR} \
	&& which docker \
	&& (docker version || true)

# Install Docker Compose - see prerequisite above
# Install Compose
ENV DOCKER_COMPOSE=1.23.2
RUN wget -q \
	https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose \
	&& docker-compose --version
	
# Install Dockerize v0.6.1
# Source repo: https://github.com/jwilder/dockerize
RUN curl -sSL --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz "https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" && \
	tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz && \
	rm -rf /tmp/dockerize-linux-amd64.tar.gz && \
	dockerize --version

RUN useradd --uid=3434 --user-group --create-home razor && \
	echo 'razor ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-razor && \
	echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

USER razor
