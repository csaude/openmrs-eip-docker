# Image for the openmrs-eip (dbsync) remote container.
#
# Replaces the old hub.csaude.org.mz/base/java:17-debian-11 base, whose Debian 11
# apt repositories are no longer available. Everything that install.sh /
# apt_install.sh used to install at container start is installed here at build
# time, the release jars are downloaded and checksum-verified into the image, and
# release_stuff (with install.sh) is copied into /home/openmrs-eip-docker.
#
# Build (docker-compose.yml only references the resulting image):
#   docker build -t hub.csaude.org.mz/base/java:17-debian-13 .
#   docker push hub.csaude.org.mz/base/java:17-debian-13

# Debian 13 (trixie) no longer packages OpenJDK 17, so the JDK is taken from the
# official Eclipse Temurin 17 image (glibc based, runs on Debian 13).
FROM eclipse-temurin:17-jdk AS jdk

FROM debian:trixie-slim

ARG EIP_RELEASE_TAG=V11.1.0
ARG EIP_RELEASE_BASE_URL=https://github.com/csaude/openmrs-eip-docker/releases/download
# Jars from the release referenced by release_stuff/scripts/release_info.sh
# (the eip app version is chosen at runtime from the MySQL version: 5.x -> 1.6.9, 8.x -> 1.9.0)
ARG EIP_RELEASE_JARS="openmrs-eip-app-1.6.9.jar openmrs-eip-app-1.9.0.jar epts-etl-api-1.0.jar centralization-features-manager-1.0.jar"
# Should match the uid/gid of the eip user on the host (see README "Setup")
ARG EIP_UID=1000
ARG EIP_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    JAVA_HOME=/opt/java/openjdk \
    EIP_RELEASE_TAG=${EIP_RELEASE_TAG} \
    EIP_RELEASES_DIR=/opt/eip/releases
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Packages previously installed by release_stuff/scripts/apt_install.sh, plus the
# tools the other scripts rely on (nc, pgrep/pkill, rev, ssh, sudo, tzdata).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bsdextrautils \
        ca-certificates \
        cron \
        curl \
        expect \
        git \
        mariadb-client \
        netcat-openbsd \
        openssh-client \
        openssl \
        procps \
        sshpass \
        sudo \
        tzdata \
        vim \
        wget \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* \
    && printf '[client]\nssl-verify-server-cert=off\n' > /etc/mysql/conf.d/eip-client.cnf \
    && groupadd -g "$EIP_GID" eip \
    && useradd -m -d /home/eip -s /bin/bash -u "$EIP_UID" -g eip -G sudo eip


COPY --from=jdk /opt/java/openjdk /opt/java/openjdk
# cron jobs run with a minimal PATH and the scripts derive JAVA_HOME from `which java`
RUN for bin in java keytool; do ln -s "$JAVA_HOME/bin/$bin" "/usr/bin/$bin"; done \
    && chmod 777 "$JAVA_HOME/lib/security/cacerts" \
    && java -version

# apt_install.sh skips package installation when this marker exists
RUN mkdir -p /home/eip/logs/apt \
    && echo "Packages installed at image build time" > /home/eip/logs/apt/finished \
    && chown -R eip:eip /home/eip/logs

WORKDIR /home/eip

