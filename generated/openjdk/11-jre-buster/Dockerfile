### !!! DO NOT EDIT
### It is auto-generated by http://github.com/razorci/image-gen

FROM openjdk:11-jre-buster

# Make APT non-interactive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/99razorci
RUN echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/99razorci
ENV DEBIAN_FRONTEND=noninteractive

# Install Packages
RUN mkdir -p /usr/share/man/man1
RUN apt-get update
RUN echo 'Acquire::Check-Valid-Until no;' >> /etc/apt/apt.conf
RUN apt-get install -y -m \
    git \
    mercurial \
    xvfb \
    vim \
    apt \
    locales \
    sudo \
    apt-transport-https \
    ca-certificates \
    openssh-client \
    software-properties-common \
    build-essential \
    tar \
    lsb-release \
    gzip \
    parallel \
    net-tools \
    netcat \
    unzip \
    zip \
    bzip2 \
    lftp \
    gnupg \
    curl \
    wget \
    build-essential \
    tree \
    jq
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

# Install Docker
ARG DOCKER_GID=999
RUN set -ex \
    && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*.tgz' | sort -r | head -n 1) \
    && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
    && echo Docker URL: $DOCKER_URL \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/bin \
    && rm -rf /tmp/docker /tmp/docker.tgz \
    && which docker \
    && (docker version || true) \
    && groupadd -g "$DOCKER_GID" -r docker

# Install Compose
ENV DOCKER_COMPOSE=1.27.4
RUN wget -q \
    https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && docker-compose --version

ENV DOCKERIZE_VERSION v0.6.1
RUN if grep -q Debian /etc/os-release; then      wget -q https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
     && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
     && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
   ; fi

ENV USER_NAME=razor GROUP_NAME=razor

RUN groupadd --gid 2001 razor && \
    useradd --uid 2001 --gid razor --shell /bin/bash --create-home razor && \
    usermod -a -G sudo,docker razor && \
    echo "%razor ALL=(root) NOPASSWD:ALL" >>/etc/sudoers

USER razor

USER root
ENV USER_HOME=/home/razor

ARG MAVEN_VERSION=3.6.3
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"


RUN echo maven --version
USER razor


USER root

ENV GRADLE_VERSION=6.8 GRADLE_HOME=/opt/gradle
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/gradle.zip \
  https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip -d /opt /tmp/gradle.zip \
  && rm /tmp/gradle.zip \
  && ln -s /opt/gradle-* $GRADLE_HOME \
  && $GRADLE_HOME/bin/gradle -version

USER razor

USER root
ENV ANT_VERSION=1.9.4 ANT_HOME=/opt/apache-ant

# Install Ant Version: 1.9.4
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/apache-ant.tar.gz \
    https://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
  && tar xf /tmp/apache-ant.tar.gz -C /opt/ \
  && ln -s /opt/apache-ant-* $ANT_HOME \
  && rm -rf /tmp/apache-ant.tar.gz \
  && $ANT_HOME/bin/ant -version

USER razor

USER root

# Install sbt 1.4.1
ENV SBT_VERSION=1.4.1

RUN if grep -q Debian /etc/os-release; then \
  curl --silent --show-error --location --fail --retry 3 --output \
    sbt-$SBT_VERSION.deb http://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb \
    && dpkg -i sbt-$SBT_VERSION.deb \
    && rm sbt-$SBT_VERSION.deb \
    && apt-get update \
    && apt-get install sbt \
  ; fi

USER razor

USER root

ENV LEIN_VERSION=2.9.5 LEIN_INSTALL=/usr/local/bin/

WORKDIR /tmp

# Download the whole repo as an archive
RUN apt-get update && \
  apt-get install -y gnupg && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p $LEIN_INSTALL && \
  wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg && \
  echo "Comparing lein-pkg checksum ..." && \
  sha256sum lein-pkg && \
  echo "3601d55c4b5ac5c654e4ebd0d75abf7ad683f48cba8a7af1a8730b6590187b8a *lein-pkg" | sha256sum -c - && \
  mv lein-pkg $LEIN_INSTALL/lein && \
  chmod 0755 $LEIN_INSTALL/lein && \
  wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip && \
  wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip.asc && \
  gpg --batch --keyserver keys.openpgp.org --recv-key 20242BACBBE95ADA22D0AFD7808A33D379C806C3 &&   echo "Verifying file PGP signature..." && \
  gpg --batch --verify leiningen-$LEIN_VERSION-standalone.zip.asc leiningen-$LEIN_VERSION-standalone.zip &&   rm leiningen-$LEIN_VERSION-standalone.zip.asc && \
  mkdir -p /usr/share/java && \
  mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar &&   apt-get purge -y --auto-remove gnupg

ENV PATH=$PATH:$LEIN_INSTALL
ENV LEIN_ROOT 1

# Install clojure 1.10.1 so users don't have to download it every time
RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.1"]])' > project.clj   && lein deps && rm project.clj
  
USER razor

## Update PATH for Java tools
ENV PATH="/opt/sbt/bin::/opt/apache-ant/bin:/opt/gradle/bin:$PATH"

# smoke test with path
RUN mvn -version \
    && ant -version \
    && gradle -version \
    && lein --version


CMD ["/bin/sh"]
