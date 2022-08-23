#!/bin/sh
# get host user id
USER_ID=${LOCAL_USER_ID:-9001}
#DOCKER_USER=git
cat /etc/sudoers | grep "$DOCKER_USER        ALL=(ALL)"
if [ $? -ne 0 ];then
echo "$DOCKER_USER        ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers 
fi

# create user in docker
useradd --shell /bin/bash -u $USER_ID -o -c "${DOCKER_USER}" -m ${DOCKER_USER}
usermod -a -G root ${DOCKER_USER}
export HOME=/home/${DOCKER_USER}
exec /usr/local/bin/gosu ${DOCKER_USER} "$@"
