#!/bin/bash

env
# . /opt/tftpboot/docker_compile_config.txt
# 
# sudo chown -R $DOCKER_USER $HOME
# 
# GIT_SHARE_DIR=/opt/tftpboot/gitshare/
# if [ "$TFTP_SUB" != "" ];then
# 	export TFTP_SUB=$TFTP_SUB
# fi
# export HOST_BUILD_DIR=$HOST_BUILD_DIR
# export HOST_SHARE_DIR=$HOST_SHARE_DIR
# 
# export PROFILE=$MY_PROFILE
# if [ "$TOOLCHAIN_OPT" = "FALSE" ] ;then
# 	export TOOLCHAIN_OPT=FALSE 
# fi
# export TOOLCHAIN_OPT=$TOOLCHAIN_OPT
# 
# export CDIR=$CDIR
# export COMPILE_NAME=$COMPILE_NAME
# echo "$CDIR"
# echo "COMPILE_NAME=$COMPILE_NAME"
# echo "PROFILE=$PROFILE"
# echo "TFTP_SUB=$TFTP_SUB"
# echo "TOOLCHAIN_OPT=$TOOLCHAIN_OPT"
# 
# if [ -d $GIT_SHARE_DIR ];then
# 	rm -rf ~/.ssh/id_rsa*
# 	[ -d "~/.ssh/" ] || mkdir -p ~/.ssh/
# 	cp -R $GIT_SHARE_DIR/id_rsa*  ~/.ssh/
# 	chmod 400  ~/.ssh/id_rsa
# 
# 	rm -f ~/.gitconfig
# 	rm -rf ~/.gitmessage
# 	cp $GIT_SHARE_DIR/.git* ~/
# 	cp $GIT_SHARE_DIR/.alias ~/
# 	cp $GIT_SHARE_DIR/.bashrc ~/
# fi
# 
# cd $CDIR
echo "Now current:$CDIR"

