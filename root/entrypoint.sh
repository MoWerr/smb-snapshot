#!/bin/bash
source /common.sh

# Reads docker secret of given name (falls back to environment variables)
function read_secret {
    if [[ -f /run/secrets/$1 ]]; then
        echo $(head -n 1 /run/secrets/$1 | tr -d '\n')
    else
        local env_name=${1^^}
        echo ${!env_name}
    fi
}

# Adds retain entry to the rsnapshot configuration file
function add_retain {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo -e "retain\t$1\t$2" >> ~/rsnapshot.conf
        msg "Added $1 retain config entry"
    fi
}

# Adds backup entry to the rsnapshot configuration file
function add_backup {
    echo -e "backup\t/data/remote/$1\tlocalhost/" >> ~/rsnapshot.conf
    msg "Added '$1' backup location to the rsnapshot configuration"
}

# Adds cron entry to the crontab file
function add_cron_entry {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo "$3 rsnapshot -c ~/rsnapshot.conf $1" >> ~/cron-tasks
        msg "Added $1 cron entry"
    fi
}

# Adds 'empty' line to make a valid cron file
function finish_cron_file {
    echo "# This line makes a valid cron" >> ~/cron-tasks
}

# Create all necessary directories
check_dir ~/.smb
check_dir ~/shares
check_dir ~/config

# Copy default smbnetfs.conf if doesn't exist
if [[ ! -f ~/.smb/smbnetfs.conf ]]; then
    cp /etc/smbnetfs.conf ~/.smb/smbnetfs.conf
    msg "Created default smbnetfs configuration file"
fi

# Read auth configuration
hostname=$(read_secret hostname)
username=$(read_secret username)
password=$(read_secret password)

# Check for required 'hostname' parameter
if [[ -z $hostname ]]; then
    err "Required parameter 'hostname' was not provided."
    exit 1
fi

# Delete auth config from previous run
if [[ -f ~/.smb/smbnetfs.auth ]]; then
    rm ~/.smb/smbnetfs.auth
    msg "Removed old auth configuration file"
fi

# Create new auth config if at least username was provided
if [[ ! -z $username ]]; then
    echo "auth $hostname $username $password" > ~/.smb/smbnetfs.auth
    chmod 600 ~/.smb/smbnetfs.auth
    msg "Created new auth configuration file"
fi

# Mount smbnetfs directory
smbnetfs -o auto_unmount ~/shares

if [[ $? != 0 ]]; then
    err "Failed to mount a smb share directory"
    exit 1
fi

# Remove 'easy-access' link from previous runs
if [[ -f ~/remote ]]; then
    rm ~/remote
fi

# Create symbolic link for 'easy-access' to the remote share
ln -s ~/share/$hostname/ ~/remote

msg "Mounted remote location"
msg "You can access your shares in: /data/remote/<share name>"

# Remove old snapshot config file
# We create new config file each time as the env variables may be entirely different
if [[ -f ~/rsnapshot.conf ]]; then
    rm ~/rsnapshot.conf
    msg "Removed old snapshot configuration file"
fi

cp /defaults/rsnapshot.conf.default ~/rsnapshot.conf
msg "Created new rsnapshot configuration file"

# Add all specified backup points
IFS=$DELIMITER read -ra shares_array <<< "$SHARES"
for share_dir in "${shares_array[@]}"; do
    add_backup "$share_dir"
done

# Add all retain configurations
add_retain "hourly" "$HOURLY_SNAPSHOTS" "$HOURLY_CRON"
add_retain "daily" "$DAILY_SNAPSHOTS" "$DAILY_CRON"
add_retain "weekly" "$WEEKLY_SNAPSHOTS" "$WEEKLY_CRON"
add_retain "monthly" "$MONTHLY_SNAPSHOTS" "$MONTHLY_CRON"
add_retain "yearly" "$YEARLY_SNAPSHOTS" "$YEARLY_CRON"

# Remove old crontab file from previous run
if [[ -f /data/cron-tasks ]]; then
    rm /data/cron-tasks
    msg "Removed old crontab file"
fi

# Add all cron entries
add_cron_entry "hourly" "$HOURLY_SNAPSHOTS" "$HOURLY_CRON"
add_cron_entry "daily" "$DAILY_SNAPSHOTS" "$DAILY_CRON"
add_cron_entry "weekly" "$WEEKLY_SNAPSHOTS" "$WEEKLY_CRON"
add_cron_entry "monthly" "$MONTHLY_SNAPSHOTS" "$MONTHLY_CRON"
add_cron_entry "yearly" "$YEARLY_SNAPSHOTS" "$YEARLY_CRON"
finish_cron_file

# Enable crontab file
crontab ~/cron-tasks

# Display current log file on output
tail -f ~/destination/rsnapshot.log