#!/usr/bin/with-contenv bash
source /common.sh

# Adds cron entry to the crontab file
function add_cron_entry {
    if [[ ! -z $2 && $2 > 0 && ! -z $3 ]]; then
        echo "$3 /usr/bin/rsnapshot -c /etc/rsnapshot/rsnapshot.conf $1" >> /etc/crontabs/husky
        msg "Added $1 cron entry"
    fi
}

# Adds 'empty' line to make a valid cron file
function finish_cron_file {
    echo "# This line makes a valid cron" >> /etc/crontabs/husky
}

# Remove old crontab file from previous run
if [[ -f /etc/crontabs/husky ]]; then
    rm /etc/crontabs/husky
    msg "Removed old crontab file"
fi

touch /etc/crontabs/husky

# Add all cron entries
add_cron_entry "hourly" "$HOURLY_SNAPSHOTS" "$HOURLY_CRON"
add_cron_entry "daily" "$DAILY_SNAPSHOTS" "$DAILY_CRON"
add_cron_entry "weekly" "$WEEKLY_SNAPSHOTS" "$WEEKLY_CRON"
add_cron_entry "monthly" "$MONTHLY_SNAPSHOTS" "$MONTHLY_CRON"
add_cron_entry "yearly" "$YEARLY_SNAPSHOTS" "$YEARLY_CRON"
finish_cron_file

# Make sure that default user has access to the crontab file
chown husky:husky /etc/crontabs/husky