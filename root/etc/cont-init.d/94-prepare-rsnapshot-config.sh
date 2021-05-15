#!/usr/bin/with-contenv bash
source /common.sh

# Adds retain entry to the rsnapshot configuration file
function add_retain {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo -e "retain\t$1\t$2" >> /etc/rsnapshot/rsnapshot.conf
        msg "Added '$1' retain config entry"
    fi
}

# Adds backup entry to the rsnapshot configuration file
function add_backup {
    echo -e "backup\t/data/shares/./$1/\t." >> /etc/rsnapshot/rsnapshot.conf
    msg "Added '$1' backup location to the rsnapshot configuration"
}

# Remove old snapshot config file
# We create new config file each time as the env variables may be entirely different
if [[ -f /etc/rsnapshot/rsnapshot.conf ]]; then
    rm /etc/rsnapshot/rsnapshot.conf
    msg "Removed old snapshot configuration file"
fi

cp /etc/rsnapshot/rsnapshot.conf.default /etc/rsnapshot/rsnapshot.conf
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

# Make sure that default user has access to the rsnapshot config file
chown husky:husky /etc/rsnapshot/rsnapshot.conf