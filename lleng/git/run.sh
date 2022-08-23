#!/bin/bash
# set -x
#########################################
# include common shell script
##########################################
COMM_SH="../comm.sh"
if [ -f $COMM_SH ];then
. $COMM_SH
fi

#################################################
# 1. copy id_rsa and id_rsa.pub to start in.
# 2. Modify  below value match your env.

# DOCKER_USER please same with run this script in host.
DOCKER_USER=git

# The configuration floder in Host.
# If running user is not root, This folder should own by user. it is better this folder own by running user.
SHARE_DIR="/sdd/tftpboot/"
# It is your code top directory.
WORKER_DIR=/sdd/git_un

# It is for share toolchain, this folder own by running user.
TOOLCHAIN_DIR="/sdd/git_ext_toolchain_"
# It is for worktree, if you want start in script create git worktree 
WORKTREE_DIR="/sdd/git/worktree"

#################################################

if [ $DOCKER_USER != "root" ];then
TOOLCHAIN_OPT="/home/$DOCKER_USER/ext_toolchain_"
else
TOOLCHAIN_OPT="/root/ext_toolchain_"
fi
#copy id_rsa and id_rsa.pub to start in.

#################################################

declare -r CUR_DIR=`pwd`

declare -r RUN_IN_DIR="$CUR_DIR/start_in"

declare -r HOST_CFG="$SHARE_DIR/docker_compile_config.txt"
declare -r CONTAINER_SHARE_DIR="/opt/tftpboot"
declare -r CONTAINER_WORKTREE_DIR="/opt/worktree"
declare -r CONTAINER_SHELL="$CONTAINER_SHARE_DIR/docker-entrypoint.sh"
declare -r GIT_SHARE_DIR=$SHARE_DIR/gitshare/

name=git3
OS=ubuntu:14.04
IMAGE=ruckus/git_u_1404
mount_name=mycompile
. config.txt

#C_DIR=buildroot/
C_DIR=""
BUILD_DIR=${dir}/$C_DIR
TFTP_SUB=11axun
#PROFILE=directorx86
#PROFILE=vmva
PROFILE=ap-arm-qca-unleashed
#PROFILE=ap-arm-11ax-unleashed
PROFILE=ap-arm-dakota
PROFILE=ap-arm-qca
PROFILE=ap-arm-11ax-wsg
#PROFILE=ap-11n-scorpion
PROFILE=ap-arm-11ax-unleashed

# echo "Image name : ${IMAGE}"

copy_run_in_file(){
echo "Copy script to BUILD_DIR:(${BUILD_DIR}) for docker"
# BUILD_DIR come from configuration file    
cp -pf $RUN_IN_DIR/make.sh ${BUILD_DIR}
cp -pf $RUN_IN_DIR/all.sh ${BUILD_DIR}

cp -pf $RUN_IN_DIR/gen_appweb_patch.sh ${BUILD_DIR}
cp -pf $RUN_IN_DIR/gen_lldp_ptach.sh ${BUILD_DIR}
cp -pf $RUN_IN_DIR/patch-kernel.sh ${BUILD_DIR}
cp -pf $RUN_IN_DIR/print_kernel_version_per_profile.py ${BUILD_DIR}
}

copy_run_conf_file(){
local name="$1"
local type="$2"
echo "Docker compile dir:(/opt/${mount_name}/$C_DIR)"
# echo "Start container name:$name"
echo "TFTP_SUB:$TFTP_SUB"
echo "PROFILE:$PROFILE"
echo "TOOLCHAIN_OPT:$TOOLCHAIN_OPT"
#
echo "CDIR=/opt/${mount_name}/$C_DIR" > $HOST_CFG
# TFTP_SUB come from configuration file
if [ "$TFTP_SUB" != "" ];then
        echo "TFTP_SUB=${TFTP_SUB}" >> $HOST_CFG
fi
echo "MY_PROFILE=$PROFILE" >>$HOST_CFG
echo "COMPILE_NAME=${name} " >>$HOST_CFG
if [ "$TOOLCHAIN_OPT" = "FALSE" ] ;then
echo "TOOLCHAIN_OPT=FALSE" >> $HOST_CFG
else
echo "TOOLCHAIN_OPT=$TOOLCHAIN_OPT" >> $HOST_CFG
fi
echo "HOST_BUILD_DIR=$BUILD_DIR" >> $HOST_CFG
echo "HOST_SHARE_DIR=$SHARE_DIR" >> $HOST_CFG

cp -f $RUN_IN_DIR/docker-entrypoint.sh $SHARE_DIR 
if [ -f "$SHARE_DIR/p4config" ];then
 cat $SHARE_DIR/p4config >> $SHARE_DIR/docker-entrypoint.sh
fi
echo "echo \"Start bash\" " >>  $SHARE_DIR/docker-entrypoint.sh
if [[ "${type}" =~ 'make' ]]; then
    echo "./make.sh" >>  $SHARE_DIR/docker-entrypoint.sh
fi
echo "/bin/bash" >>  $SHARE_DIR/docker-entrypoint.sh

echo "copy git relate configuation"
[ -d $GIT_SHARE_DIR ] &&  rm -rf ${GIT_SHARE_DIR}
mkdir -p $GIT_SHARE_DIR
cp start_in/.git* $GIT_SHARE_DIR
cp start_in/id_rsa* $GIT_SHARE_DIR
cp start_in/.alias $GIT_SHARE_DIR
cp start_in/.bashrc $GIT_SHARE_DIR
cp start_in/create_worktree.sh $GIT_SHARE_DIR

}

start_compile_contain(){
    local name=$1
    local type=$2
    local run_shell=/bin/bash 
    run_shell=
    copy_run_in_file
    copy_run_conf_file "$name"
    echo "Start new container $name"
    echo "$image name :${IMAGE}"
    echo "$run_shell"
    if [[ "${type}" =~ 'new' ]]; then
        docker exec -it -u ${DOCKER_USER} ${name} $CONTAINER_SHELL
    else
        docker run -it -d -P --name ${name}  \
                    -e LOCAL_USER_ID=$(id -u $USER) \
                    -e DOCKER_USER=$DOCKER_USER ${MOUNT_DIR} \
                    ${IMAGE} $CONTAINER_SHELL  & 
    fi                                     
    #/opt/${name}/buildroot/make.sh; cd ${dir}buildroot

}




start_container(){
local name="$1"
local type="$2"
local n=3
copy_run_conf_file "$name" "$type"
idall=`docker ps -a| grep ${name} | awk '{print($1)}'`
idrun=`docker ps | grep ${name} | awk '{print($1)}'`
if [ -n "$idrun" ];then
        if [[ "${type}" =~ 'force' ]]; then
                echo "stop and remove (${idrun}) existed container"
                docker stop ${idrun}
                docker rm ${idrun}
                sleep 1
        elif [[ "${type}" =~ 'new' ]]; then
                echo "start new /bin/sh"
                start_compile_contain "$name" "$type"
                return
        else
                echo "Keep it attach container"
                docker attach ${idrun}
                return
        fi
elif [ -n "$idall" ];then
        if [[ "${type}" =~ 'force' ]]; then
                echo "Remove (${idall}) existed container"
                docker rm ${idall}
                sleep 1
        else
                echo "Keep it existed container"
                docker start ${idall}
                docker attach ${idall}
                return
        fi
fi
start_compile_contain "$name" "$type"

n=1
while [ $n -le 3 ]; do 
    id=`docker ps | grep ${name} | awk '{print($1)}'`
    if [ -z "$id" ];then
        echo "wait 1 second, and get th id."
        sleep 1
        id=`docker ps | grep ${name} | awk '{print($1)}'`
    else
        break
    fi
n=$(( n+1 ));
done

echo "echo id: $id"
if [ -n "$id" ];then
    docker attach ${id}
fi

}

attach_container_xx(){
local type="$1"
local shell_cmd=/bin/bash

if [ "$type" != "" ];then
        shell_cmd=/opt/tftpboot/docker-entrypoint.sh
fi
echo "CDIR=/opt/${mount_name}/$C_DIR" > /tftpboot/docker_compile_config.txt
cp docker-entrypoint.sh /opt/tftpboot

echo ""
id=`docker ps | grep ${name} | awk '{print($1)}'`
idall=`docker ps -a | grep ${name} | awk '{print($1)}'`
if [ -n "$id" ];then
    docker exec -it "$id" $shell_cmd
elif [ -n "$idall" ];then
        docker start ${idall}
        docker exec -it "$id" $shell_cmd
else
    echo "$name is not runing"
fi

}




cmd=$1
name=$2
op=$3
load_config_file(){
local conf_file_name="$1"
    if [ -n "$conf_file_name" ];then
        if [ -f "$conf_file_name" ];then
            echo "Load configuration: ${conf_file_name}"
            . ${conf_file_name}
        else
            echo "don't load config, use default config"
        fi
        
    fi
    contain_name="${conf_file_name//[\/]/_}"
}




show_usage(){
show_comm_usage    
echo "
Version 1.0
usage: $0   -c|--compile  name           ;compile with container.
            -n|--new    name             ;start new existed container.         
            -f|--force    name           ;stop and remove existed container and start new compile with container.
example 5:  $0 -re name
example 5:  $0 -f name
example 6:  
example 7:  
example 8:  
example 9:  
example 10: 
example 11: 
"
}


if [ "$cmd" != "-h" ];then
echo "Name: $name"
echo "Command: $cmd"
load_config_file "$name"
echo "Image name: ($IMAGE)"
echo "contain_name: ($contain_name)"
fi

MOUNT_DIR=" -v ${WORKER_DIR}:/opt/${mount_name} -v $SHARE_DIR:$CONTAINER_SHARE_DIR"
MOUNT_DIR="$MOUNT_DIR -v $TOOLCHAIN_DIR:$TOOLCHAIN_OPT -v $WORKTREE_DIR:$CONTAINER_WORKTREE_DIR "

echo "image name : ${IMAGE}"
echo "MOUNT_DIR ${MOUNT_DIR}"

echo "command:$cmd"

compile_type=""
if [ "--make" == "$op" ] || [ "-m" = "$op" ] ;then
compile_type="make"
fi

if [ "shell" = "$cmd" ];then
    attach_container "$contain_name"
elif [ "testshell" = "$cmd" ];then
    attach_container "testshell"
elif [ "--force" == "$cmd" ] || [ "-f" = "$cmd" ] ;then
    echo "start start_container($contain_name) by force "
    compile_type="force${compile_type}"
    start_container "$contain_name" "$compile_type"
elif [ "--new" == "$cmd" ] || [ "-n" = "$cmd" ] ;then
     start_container "$contain_name" "new"   
elif [ "--compile" == "$cmd" ] || [ "-c" = "$cmd" ] ;then
    echo "tar_branch:$tar_branch dir: $dir"
    #get_tar_file "$BUILD_DIR" "$PROFILE" "$dir" "$tar_branch" 
    start_container "$contain_name" "$compile_type"
else
    show_usage
fi