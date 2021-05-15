#!/usr/bin/with-contenv bash
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

# Mounts given share
function mount_share {
    check_dir /data/shares/"$4"
    mount -t cifs -o username="$2",password="$3",uid=$(id husky -u),gid=$(id husky -g) //"$1"/"$4" /data/shares/"$4"

    if [[ $? != 0 ]]; then
        err "Failed to mount '$4' share"
        exit 1
    fi

    msg "Mounted '$4' share"
}

# Create directory for all mounted shares
check_dir /data/shares

# Read secrets
hostname=$(read_secret hostname)
username=$(read_secret username)
password=$(read_secret password)

# Check for required 'hostname' parameter
if [[ -z $hostname ]]; then
    err "Required parameter 'hostname' was not provided"
    exit 1
fi

# We need to mount our smb shares while still being the root
IFS=$DELIMITER read -ra shares_array <<< "$SHARES"
for share_dir in "${shares_array[@]}"; do
    mount_share "$hostname" "$username" "$password" "$share_dir"
done