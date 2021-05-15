#!/usr/bin/with-contenv bash
source /common.sh

# Waits for given hostname
function wait_for_host {
    ping -c 2 -w 60 -q "$1" &> /dev/null
}

# Wait for host. It may be useful when running this container along others with docker-compose
msg "Waiting for hostname to be reachable"
wait_for_host "$hostname"

if [[ $? != 0 ]]; then
    err "Provided hostname is unreachable"
    exit 1
fi