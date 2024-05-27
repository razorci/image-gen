require "excon"
require_relative "consts"

def exit_with(mesg)
  puts mesg
  exit(1)
end

def exit_excon(message, resp)
  puts(message)
  resp.pp
  exit(1)
end

def build_regex(*tags)
  tags.map do |tag|
    case tag
    when Regexp
      tag
    when String
      Regexp.new(tag, Regexp::IGNORECASE)
    else 
      puts "Incorrect regexp: #{tag}"
    end
  end.compact
end

def write_header(out)
  out.puts <<~EOL
             ### !!! DO NOT EDIT
             ### It is auto-generated by http://github.com/razorci/image-gen
           EOL
end

def write_base(out, base, tag)
  out.puts <<~EOL
             FROM #{base}:#{tag}
           EOL
end

def write_install_standard(out)
  out.puts <<~EOL
             # Make APT non-interactive
             RUN mkdir -p /etc/apt/apt.conf.d && \
                echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/99razorci && \
                echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/99razorci
             ENV DEBIAN_FRONTEND=noninteractive

             # Install Packages
             RUN mkdir -p /usr/share/man/man1
             RUN apt-get update
             RUN echo 'Acquire::Check-Valid-Until no;' >> /etc/apt/apt.conf
             RUN apt-get install -y -m \\
                 git \\
                 mercurial \\
                 xvfb \\
                 vim \\
                 apt \\
                 locales \\
                 sudo \\
                 apt-transport-https \\
                 ca-certificates \\
                 openssh-client \\
                 software-properties-common \\
                 build-essential \\
                 tar \\
                 lsb-release \\
                 gzip \\
                 parallel \\
                 net-tools \\
                 netcat-traditional \\
                 unzip \\
                 zip \\
                 bzip2 \\
                 lftp \\
                 gnupg \\
                 curl \\
                 wget \\
                 build-essential \\
                 tree \\
                 jq
             RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
             RUN locale-gen C.UTF-8 || true
             ENV LANG=C.UTF-8
           EOL
end

def write_ci_user(out)
  out.puts <<~EOL
             ENV USER_NAME=#{CI_USER} GROUP_NAME=#{CI_GROUP}

             RUN groupadd --gid 2001 #{CI_GROUP} && \\
                 useradd --uid 2001 --gid #{CI_GROUP} --shell #{CI_SHELL} --create-home #{CI_USER} && \\
                 usermod -a -G sudo,docker #{CI_USER} && \\
                 echo "%#{CI_GROUP} ALL=(root) NOPASSWD:ALL" >>/etc/sudoers

             USER #{CI_USER}
           EOL
end

def write_cmd(out)
  out.puts(%Q{CMD ["/bin/sh"]})
end

def write_official_nodejs(out)
  info = official_lts_reference("node", /^lts$/)
  return unless info.have_commit_directory?

  write_node_variant(out, info.commit, info.directory)
end

def write_gradle(out, version_regex)
  info = official_lts_reference("gradle", version_regex)
  return unless info.have_commit_directory?

  out.puts <<~EOL
    USER root
    
    ENV GRADLE_VERSION=#{info.tag} GRADLE_HOME=/opt/gradle
    RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/gradle.zip \\
      https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \\
      && unzip -d /opt /tmp/gradle.zip \\
      && rm /tmp/gradle.zip \\
      && ln -s /opt/gradle-* $GRADLE_HOME \\
      && $GRADLE_HOME/bin/gradle -version

    USER #{CI_USER}
  EOL
end

def write_ant(out, version_regex)
  tag = ANT_VERSION
  out.puts <<~EOL
    USER root
    ENV ANT_VERSION=#{tag} ANT_HOME=/opt/apache-ant

    # Install Ant Version: #{tag}
    RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/apache-ant.tar.gz \\
        https://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \\
      && tar xf /tmp/apache-ant.tar.gz -C /opt/ \\
      && ln -s /opt/apache-ant-* $ANT_HOME \\
      && rm -rf /tmp/apache-ant.tar.gz \\
      && $ANT_HOME/bin/ant -version
    
    USER #{CI_USER}
  EOL
end

def write_lein(out, tag)
  # https://codeberg.org/leiningen/leiningen/tags
  
  lein_tag = case tag.strip
  when /^[8]/, /^[9]/, /^[11]/
    "2.9.5"
  when /^[16]/, /^[17]/
    "2.9.5"
  when /^[20]/
    "2.9.10"
  end

  exit_with("No compatible lein version found for tag: '#{tag}'") unless lein_tag

  out.puts <<~EOL
    USER root

    ENV LEIN_VERSION=#{lein_tag} LEIN_INSTALL=/usr/local/bin/
    
    RUN mkdir -p LEIN_INSTALL && \
      curl -sSL -o $LEIN_INSTALL/lein "https://raw.githubusercontent.com/technomancy/leiningen/${LEIN_VERSION}/bin/lein" && \
      chmod +x $LEIN_INSTALL/lein
   
    ENV PATH=$PATH:$LEIN_INSTALL
    ENV LEIN_ROOT 1

    # Install clojure 1.10.1 so users don't have to download it every time
    RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.1"]])' > project.clj \
      && lein deps && rm project.clj
      
    USER #{CI_USER}
  EOL
end

def write_sbt(out, tag)
  sbt_tag = case tag.strip
  when /^[8]/, /^[9]/, /^[11]/, /^[16]/, /^17/
    "1.5.8"
  when /^[20]/
    "1.6.2"
  end

  exit_with("No compatible sbt version found for tag: '#{tag}'") unless sbt_tag

  ## detect java version https://stackoverflow.com/questions/7334754/correct-way-to-check-java-version-from-bash-script
  
  out.puts <<~EOL
    USER root

    # Install sbt #{sbt_tag}
    ENV SBT_VERSION=#{sbt_tag}
       
    RUN if grep -q Debian /etc/os-release; then \\
      curl --silent --show-error --location --fail --retry 3 --output \\
        sbt-$SBT_VERSION.deb https://scala.jfrog.io/artifactory/debian/sbt-$SBT_VERSION.deb \\
        && dpkg -i sbt-$SBT_VERSION.deb \\
        && rm sbt-$SBT_VERSION.deb \\
        && apt-get update \\
        && apt-get install sbt \\
      ; fi

    USER #{CI_USER}
  EOL
end

def write_maven(out, version_regex)
  out.puts <<~EOL
    USER root

    ENV MAVEN_VERSION=3.8.8 PATH=/opt/apache-maven/bin:$PATH
    RUN dl_URL="https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" && \
      curl -sSL --fail --retry 3 $dl_URL -o apache-maven.tar.gz && \
      tar -xzf apache-maven.tar.gz -C /opt/ && \
      rm apache-maven.tar.gz && \
      ln -s /opt/apache-maven-* /opt/apache-maven && \
      mvn --version
  EOL

  out.puts %Q{USER #{CI_USER}}
  out.puts
end

class DockerTagInfo
  attr_accessor :repo_url
  attr_accessor :tag
  attr_accessor :commit
  attr_accessor :directory

  def initialize(options={})
    options.each do |key, value| 
      send("#{key}=", value) 
    end
  end

  def have_commit_directory?
    self.commit && self.directory 
  end

  def dockerfile_url
    uri = URI(self.repo_url.chomp('.git'))
    
    [
      uri.path,
      self.commit,
      self.directory,
      "Dockerfile"
    ].compact.join("/")
  end
end

def official_lts_reference(lang, tag_regex)
  path = ["docker-library/official-images", DOCKER_BRANCH, "library", lang].join("/")
  resp = Excon.get("https://raw.githubusercontent.com", path: path)
  raw_github_url = "https://raw.githubusercontent.com/#{path}"

  if resp.status >= 300
    exit_excon("fetching #{tag_regex} tag for #{lang}", resp)
  end

  git_commit = directory = nil
  lookup = nil
  tag = nil
  repo_url = nil
  any_commit = nil

  resp.body.each_line do |line|
    if matched = line.match(/GitRepo: (.*)/)
      repo_url = matched[1]
    end

    if matched = line.match(/GitCommit: (.*)/)
      any_commit = matched[1]
    end

    if matched = line.match(/^Tags: (.*)/)
      tags = find_valid_tags(matched[1], [], [tag_regex])
      if tags.size > 0
        lookup = true 
        tag = tags.last
      end
    end

    if lookup
      if matched = line.match(/GitCommit: (.*)/)
        git_commit = matched[1]
      end

      if matched = line.match(/^Directory: (.*)/)
        directory = matched[1]
      end

      lookup = false if git_commit && directory
    end
  end

  unless (git_commit || any_commit) && directory
    # ignore errors for maven if openjdk tags are not found
    if lang == "maven"
      return
    end

    exit_with("No '#{tag_regex}' tag for #{lang} in #{raw_github_url}")
  end

  DockerTagInfo.new(commit: git_commit, directory: directory, tag: tag).tap do |info|
    info.commit = any_commit unless info.commit
    info.repo_url = repo_url
  end
end

def write_node_variant(out, commit, directory)
  path = [
    "nodejs/docker-node",
    commit,
    directory,
    "Dockerfile",
  ].join("/")

  resp = Excon.get("https://raw.githubusercontent.com", path: path)
  if resp.status >= 300
    exit_excon("fetching Dockerfile for #{commit}/#{directory}", resp)
  end

  out.puts(%Q{USER root})

  resp.body.each_line do |line|
    next if line =~ /^FROM buildpack/
    next if line =~ /^COPY docker-entrypoint/
    next if line =~ /^CMD/
    next if line =~ /^ENTRYPOINT/

    out.puts(line)
  end

  out.puts %Q{RUN echo node --version}
  out.puts %Q{USER #{CI_USER}}
  out.puts
end

def write_file(path, input)
  case input
  when StringIO
    input.flush
    File.open(path, "w") { |f| f.puts(input.string) }
  else
    File.open(path, "w") { |f| f.puts(input) }
  end
end

def docker_exec(command)
  puts("\t===> " + command)
  ENV["CI"] && system(command, exception: true)
end

def find_tags_and_aliases(lang, reject_regex, include_regex)
  resp = Excon.get("https://raw.githubusercontent.com", path: [
                                                          "docker-library/official-images",
                                                          DOCKER_BRANCH,
                                                          "library/#{lang}",
                                                        ].join("/"))

  if resp.status >= 300
    exit_excon("Non-ok HTTP response: (#{resp.status})", resp)
  end

  result = []
  lookup = false
  resp.body.each_line do |line|
    tags = []
    if matched = line.match(/^Tags: (.*)/)
      tags = find_valid_tags(matched[1], reject_regex, include_regex)
      lookup = tags.size > 0
      result << semvar_sort(tags) if lookup
    elsif matched = line.match(/^SharedTags: (.*)/)
      if lookup && shared_tags = find_valid_tags(matched[1], reject_regex, include_regex)
        item = result[-1]
        item |= semvar_sort(shared_tags)
        result[-1] = item
      end

      lookup = false
    end
  end

  result
end

def semvar_sort(tags)
  puts "sorting #{tags}"
  tags.select{|t| t =~ /\d+/ }.sort_by do |t|
    Gem::Version.new(t)
  end
end

def find_valid_tags(line, reject_regex, include_regex)
  tags = line.split(",").map { |t| t.strip }.compact
  tags = tags.reject do |tag|
    REJECT_TAGS.any? { |re| tag =~ re } || tag.size < 2
  end

  selected = included = []
  if reject_regex.size > 0
    selected = tags.reject { |t| reject_regex.any? { |re| t =~ re } }
  end

  if include_regex.size > 0
    included = tags.select { |t| include_regex.any? { |re| t =~ re } }
  end

  if reject_regex.size + include_regex.size > 0
    tags = selected | included
  end

  tags
end
