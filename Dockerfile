FROM mowerr/ubuntu-base:20.04

# Default user and user group will be adapted to those values
ARG UID=1000
ARG GID=1000

# Adapt UID and GID values
RUN set -x && \
    usermod -o -u ${UID} husky && \
    groupmod -o -g ${GID} husky

# Update the package and install all dependencies
RUN set -x && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        fuse \
        smbnetfs \
    && \
    # Cleanup
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Directory that will be used as a base for our all snapshots
ENV SNAPSHOTS_DIR="/data/snapshots"

# Define volume for generated snapshots
VOLUME ["${SNAPSHOTS_DIR}"]

COPY root/ /