#!/bin/bash

. /opt/tftpboot/docker_compile_config.txt
if [ "$TFTP_SUB" != "" ];then
	export TFTP_SUB=$TFTP_SUB
fi

export PROFILE=$MY_PROFILE
if [ "$TOOLCHAIN_OPT" = "FALSE" ] ;then
	export TOOLCHAIN_OPT=FALSE 
fi
export CDIR=$CDIR
export COMPILE_NAME=$COMPILE_NAME
echo "$CDIR"
echo "COMPILE_NAME=$COMPILE_NAME"
echo "PROFILE=$PROFILE"
echo "TFTP_SUB=$TFTP_SUB"
echo "TOOLCHAIN_OPT=$TOOLCHAIN_OPT"

cat /etc/resolv.conf | grep "domain video54.local"
if [ $? -ne 0 ];then
echo "domain video54.local" >> /etc/resolv.conf
fi
cat /etc/resolv.conf | grep "search video54.local"
if [ $? -ne 0 ];then
echo "search video54.local" >> /etc/resolv.conf
fi

cd $CDIR
echo "Now current:$CDIR"
