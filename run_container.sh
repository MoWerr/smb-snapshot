#!/bin/bash
docker run --cap-add SYS_ADMIN --security-opt apparmor:unconfined "$@" smb