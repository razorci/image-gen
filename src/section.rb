
def write_section(out, key, lang, tag)
  puts "Writing section #{key} for #{lang}-#{tag}"
  case key
  when :docker, "docker"
    out.puts <<~EOL
               # Install Docker
               ARG DOCKER_GID=999
               RUN set -ex \\
                   && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*\.tgz' | sort -r | head -n 1) \\
                   && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \\
                   && echo Docker URL: $DOCKER_URL \\
                   && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \\
                   && ls -lha /tmp/docker.tgz \\
                   && tar -xz -C /tmp -f /tmp/docker.tgz \\
                   && mv /tmp/docker/* /usr/bin \\
                   && rm -rf /tmp/docker /tmp/docker.tgz \\
                   && which docker \\
                   && (docker version || true) \\
                   && groupadd -g "$DOCKER_GID" -r docker -f
             EOL
  when "docker-compose", :"docker-compose", "compose", "docker_compose", :"docker_compose"
    out.puts <<~EOL
              # Install Compose
              ENV DOCKER_COMPOSE=1.29.2
              RUN wget -q \\
                  https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose \\
                  && chmod +x /usr/local/bin/docker-compose \\
                  && docker-compose --version
              
              ENV DOCKER_COMPOSE_PLUGIN=2.29.7
              RUN dockerPluginDir=/usr/local/lib/docker/cli-plugins && \
                mkdir -p $dockerPluginDir && \
                curl -sSL "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_PLUGIN/docker-compose-linux-$(uname -m)" -o $dockerPluginDir/docker-compose && \
                chmod +x $dockerPluginDir/docker-compose && \
                docker compose version
             EOL
  when "dockerize", :dockerize
    out.puts <<~EOG
               ENV DOCKERIZE_VERSION v0.8.0
               RUN if grep -q Debian /etc/os-release; then \
                    wget -q https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
                    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
                    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \\
                  ; fi
             EOG
  when :maven, "maven"
    write_maven(out, /^\d+\.\d+\.\d+-#{lang}-#{tag}/)
  when :gradle, "gradle"
    write_gradle(out, /^\d+\.\d+$/)
  when :ant, "ant"
    write_ant(out, /^\d+\.\d+\.\d+$/)
  when :sbt, "sbt"
    write_sbt(out, tag)
  when :lein, "lein"
    write_lein(out, tag)  
  else
    puts "Unsupported section: #{key}"
  end

  out.puts
end
