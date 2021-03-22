#!/bin/bash
source /common.sh

# Adds retain entry to the rsnapshot configuration file
function add_retain {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo -e "retain\t$1\t$2" >> ~/rsnapshot.conf
        msg "Added '$1' retain config entry"
    fi
}

# Adds backup entry to the rsnapshot configuration file
function add_backup {
    echo -e "backup\t/data/shares/./$1/\t." >> ~/rsnapshot.conf
    msg "Added '$1' backup location to the rsnapshot configuration"
}

# Adds cron entry to the crontab file
function add_cron_entry {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo "$3 /usr/bin/rsnapshot -c /data/rsnapshot.conf $1" >> ~/cron-tasks
        msg "Added $1 cron entry"
    fi
}

# Adds 'empty' line to make a valid cron file
function finish_cron_file {
    echo "# This line makes a valid cron" >> ~/cron-tasks
}

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

# Remove old log file
if [[ -f ~/destination/rsnapshot.log ]]; then
    rm -f ~/destination/rsnapshot.log
fi

# Create log file up-front
touch ~/destination/rsnapshot.log

# Display current log file on output
tail -f ~/destination/rsnapshot.log