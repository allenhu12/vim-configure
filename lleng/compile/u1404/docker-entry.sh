#!/bin/sh
# This is inspired by fpco/stack-build images

[ $# -eq 0 ] && exit 0
[ -n "$DEV_UID" ] || { echo "You have to set \$DEV_UID through -e DEV_UID=\$(id -u)"; exit 1; }
# Detect vagrant account exists or not.

useradd -s /bin/bash -u $DEV_UID -d /vagrant -o vagrant >/dev/null 2>&1
chown -R vagrant:vagrant /tftpboot

#vagrant_exist=$(id -u vagrant &>/dev/null)
#[ "$?" -eq 0 ] || useradd -s /bin/bash -u $DEV_UID -d /vagrant -o vagrant >/dev/null 2>&1

exec sudo -EHu vagrant /usr/bin/env "$@"
