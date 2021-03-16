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

# Create all necessary directories
check_dir ~/.smb
check_dir ~/share
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

smbnetfs -o auto_unmount ~/share

if [[ $? != 0 ]]; then
    err "Failed to mount a smb share directory"
    exit 1
fi

if [[ -f ~/remote ]]; then
    rm ~/remote
fi

ln -s ~/share/$hostname/ ~/remote

msg "Mounted remote location"
msg "You can access your shares as: /data/remote/<share name>"

ls ~/remote/backup