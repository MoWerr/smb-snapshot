FROM mowerr/ubuntu-base:20.04

# Default user and user group will be adapted to those values
ARG UID=1000
ARG GID=1000

# Adapt UID and GID values
RUN set -x && \
    usermod -o -u ${UID} husky && \
    groupmod -o -g ${GID} husky

# Variables for smb authentication
# Those values can be supplied via docker secrets instead
ENV HOSTNAME="" \
    USERNAME="" \
    PASSWORD="" \
    # Defines what shares we want to backup and what sign will be used
    # as a delimiter between provided values
    DELIMITER=":" \
    SHARES="" \
    # Defines how many snapshots of given level we want to maintain
    # Empty value or 0 will disable this snapshot level
    HOURLY_SNAPSHOTS="" \
    DAILY_SNAPSHOTS="7" \
    WEEKLY_SNAPSHOTS="8" \
    MONTHLY_SNAPSHOTS="6" \
    YEARLY_SNAPSHOTS="" \
    # Defines custom cron expression for each snapshot level (when the snapshot will be taken)
    # Empty value will distable this snapshot level
    HOURLY_CRON="0 * * * *" \
    DAILY_CRON="10 0 * * *" \
    WEEKLY_CRON="20 0 * * 1" \
    MONTHLY_CRON="30 0 1 * *" \
    YEARLY_CRON="40 0 1 1 *"

# Update the package and install all dependencies
RUN set -x && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        fuse \
        smbnetfs \
        rsnapshot \
    && \
    # Cleanup
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Define volume for generated snapshots
VOLUME ["/data/destination"]

COPY root/ /