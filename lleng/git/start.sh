#!/bin/bash
# set -x
#########################################
# include common shell script
##########################################
COMM_SH="../comm.sh"
if [ -f $COMM_SH ];then
. $COMM_SH
fi

#########################################
# 1. add your ssh pub key to profile
# ssh-keygen -t ed25519 -C "usernamel@ruckuswireless.com"
# https://ruckus-git.ruckuswireless.com/plugins/servlet/ssh/account/keys

# 2. configure git configuration
# git config --global user.name username
# git config --global user.email username@ruckuswireless.com
# git config --global core.editor "vim"
# git config --global color.ui true

# 3. change WORKER_DIR and HOME_DIR(user home direcory will share with contanier) 
# and docker-entry.sh username same with your host.

#########################################

#name is the contain name
name=git3
WORKER_DIR=/sdd/git_un
HOME_DIR=/home/git
DOCKER_USER=git


cmd=$1
# add user
add_user(){
    useradd -ms /bin/bash -g root git
    echo "git:git" | chpasswd && \
    echo "git ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 
    usermod -aG docker git
}

echo "cmd:$cmd name=$name "

start_docker_container(){
local name=$1
echo "start container $name"
MOUNT_DIR="-v $WORKER_DIR:/git -v $HOME_DIR:/home/${DOCKER_USER}"
echo "mount $MOUNT_DIR"
echo "docker run -it -d -P --name $name -e LOCAL_USER_ID=$(id -u $USER) -e DOCKER_USER=$DOCKER_USER  $MOUNT_DIR  ruckus/git_u_1404 /bin/bash &"
docker run -it -d -P --name $name -e LOCAL_USER_ID=$(id -u $USER) -e DOCKER_USER=$DOCKER_USER $MOUNT_DIR --entrypoint "/usr/local/bin/docker-entry.sh" ruckus/git_u_1404 /bin/bash &

}

start_docker_func(){
local name=$1
echo ""
remove_container $name
MOUNT_DIR="-v $WORKER_DIR:/git -v $HOME_DIR:/home/${DOCKER_USER}"
start_docker_container $name
docker attach  $name

}


show_usage(){
show_comm_usage    
echo "
Version 1.0
usage: $0   -g  [name]                    ;start with container.
            -gi [name]                    ;stop and remove existed container and start with container.
            -f  [name]                    ;stop and remove existed container and start with container.
            "
}

if [ -n "$2" ];then
name=$2
fi

if [ -u == $cmd ];then
    add_user
elif [ $cmd == -g ];then
    cmm_start_container "start_docker_container" "$name"
elif [ $cmd == -f ];then
    cmm_start_container "start_docker_container" "$name" "force"
elif [ $cmd == -gi ];then    
    start_docker_func "$name" 
else
    show_usage
fi

start_docker_func_back(){
docker cp docker-entry.sh $name:/usr/local/bin/docker-entry.sh
docker exec -it $name /usr/local/bin/docker-entry.sh 

# docker create --name $name -e LOCAL_USER_ID=$(id -u $USER) --entrypoint "/usr/local/bin/docker-entry.sh"  $MOUNT_DIR ruckus/git_u_1404 

# docker cp docker-entry.sh $name:/usr/local/bin/docker-entry.sh

# docker start $name
# # docker exec $name /bin/bash 
# MOUNT_DIR="-v $WORKER_DIR:/git -v $HOME_DIR:/home/git"

# docker run -d -P --name $name  $MOUNT_DIR ruckus/git_u_1404 &
# docker exec cp docker-entry.sh $name:/usr/local/bin/docker-entry.sh
# docker run -it -e LOCAL_USER_ID=$(id -u $USER)  --entrypoint "/usr/local/bin/docker-entry.sh" /bin/bash &

}

#docker run -it -d -P --name git4 -e LOCAL_USER_ID=$(id -u $USER)   --entrypoint "/usr/local/bin/docker-entry.sh" -v /sdd/git_un:/git -v /home/git:/home/git   ruckus/git_u_1404 /bin/bash &

# docker run -it -d -P --name git2 -e LOCAL_USER_ID=$(id -u $USER) --entrypoint "/usr/local/bin/docker-entry.sh" -v /ssd/git:/git -v /ssd/root/ext_toolchain_:/root/ext_toolchain_ docker-for-git2 /bin/bash &