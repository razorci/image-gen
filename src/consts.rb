DOCKER_REPO = "razorci"
CI_USER = "razor"
CI_GROUP = "razor"
DOCKER_BRANCH = "master"
CI_SHELL = "/bin/bash"

REJECT_TAGS = [
  /slim/,
  /onbuild/,
  /windows/,
  /nanoserver/,
  /alpine/,
  /alpha/,
  /preview/,
  /rc/,
  /wheezy/,
  /jessie/,
]

ANT_VERSION = "1.9.4"

ANT_HOME = "/opt/apache-ant"
SBT_HOME = "/opt/sbt"
GRADLE_HOME = "/opt/gradle"