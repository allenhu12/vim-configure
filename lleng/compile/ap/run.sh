#!/bin/bash
# set -x
#########################################
# include common shell script
##########################################
COMM_SH="../../comm.sh"
if [ -f $COMM_SH ];then
. $COMM_SH
fi

CUR_DIR=`pwd`
PORT_FOWARD=""
RUN_IN_DIR="$CUR_DIR/start_in"

#########################################
# This may need change in your env. 
#########################################
SHARE_DIR="/tftpboot"
TOOLCHAIN_DIR="/code/ext_toolchain_"
#########################################

CONTAINER_SHARE_DIR="/opt/tftpboot"
name=mytest
. config.txt
HOST_CFG="$SHARE_DIR/docker_compile_config.txt"
mount_name=mycompile
CONTAINER_WORKSPACE="/home/hubo/workspace"
HOST_WORKSPACE="$CONTAINER_WORKSPACE"
CONTAINER_IMAGE="/home/hubo/images"
HOST_IMAGE="$CONTAINER_IMAGE"
CONTAINER_TOOLS="/home/hubo/tools"
HOST_TOOLS="$CONTAINER_TOOLS"



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
fi
cp -f $RUN_IN_DIR/docker-entrypoint.sh $SHARE_DIR 
if [ -f "$SHARE_DIR/p4config" ];then
 cat $SHARE_DIR/p4config >> $SHARE_DIR/docker-entrypoint.sh
fi
echo "echo \"Start bash\" " >>  $SHARE_DIR/docker-entrypoint.sh
if [[ "${type}" =~ 'make' ]]; then
    echo "./make.sh" >>  $SHARE_DIR/docker-entrypoint.sh
fi
echo "/bin/bash" >>  $SHARE_DIR/docker-entrypoint.sh

}
start_compile_contain(){
    local name=$1
    local run_shell=/bin/bash 
    run_shell=/opt/tftpboot/docker-entrypoint.sh
    copy_run_in_file
    
    echo "Start new container ($name)"
    echo "Image name :(${IMAGE})"
    echo "Run shell script: ($run_shell)"
    docker run -it -d $PORT_FOWARD  --name ${name} -v ${dir}:/opt/${mount_name} \
                                        $COMTAINER_MOUNT_DIR \
                                        -v ${HOST_WORKSPACE}:${CONTAINER_WORKSPACE} \
                                        -v ${HOST_IMAGE}:${CONTAINER_IMAGE} \
                                        -v ${HOST_TOOLS}:${CONTAINER_TOOLS} \
                                        ${IMAGE} $run_shell  & 
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

show_usage(){   
echo "
Version 2.0
usage:  $0 cmd filename [-m|--make]
        $0 -c|--compile  filename      ;Compile with container.
        $0 -f|--force    filename      ;Stop and remove existed container and start new compile with container.
Ex 1:   $0 -c config.txt
Ex 2:   $0 -f config.txt
Ex 1:   $0 -c config.txt -m
Ex 2:   $0 -f config.txt -m
Notice:
    -m|--make: Directly run make command in docker build directory. 
"
show_comm_usage
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

if [ "$cmd" != "-h" ];then

echo "Name: $name"
echo "Command: $cmd"
load_config_file "$name"
echo "Image name: ($IMAGE)"
echo "contain_name: ($contain_name)"
fi
HOST_CFG="$SHARE_DIR/docker_compile_config.txt"
COMTAINER_MOUNT_DIR="-v $SHARE_DIR:$CONTAINER_SHARE_DIR -v $TOOLCHAIN_DIR:/root/ext_toolchain_ "
COMTAINER_MOUNT_DIR="$COMTAINER_MOUNT_DIR -v /var/run/docker.sock:/var/run/docker.sock "
compile_type=""
if [ "--make" == "$op" ] || [ "-m" = "$op" ] ;then
compile_type="make"
fi

if [ "--force" == "$cmd" ] || [ "-f" = "$cmd" ] ;then
    echo "start start_container($contain_name) by force "
    compile_type="force${compile_type}"
    start_container "$contain_name" "$compile_type"
elif [ "--compile" == "$cmd" ] || [ "-c" = "$cmd" ] ;then
    echo "tar_branch:$tar_branch dir: $dir"
    #get_tar_file "$BUILD_DIR" "$PROFILE" "$dir" "$tar_branch" 
    start_container "$contain_name" "$compile_type"
else
    show_usage
fi
