#!/bin/bash
docker run --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined "$@" mowerr/smb-snapshot