#!/bin/bash

myfile=".myprofile"
rm -rf $myfile

cmd=$1

if [ "$cmd" = "" ] || [ "$cmd" = "ap" ] ;then
# compile ap image
echo "MY_PROFILE=ap-11n-ppc" > $myfile
./make.sh

fi

if [ "$cmd" = "" ];then
export ZF_SOURCE="local"
rm -rf build/director1200/build_i386_release/controller/ac/etc/apimages
fi

if [ "$cmd" = "" ] || [ "$cmd" = "zd" ] ;then

# compile zd image
echo "MY_PROFILE=director1200" > $myfile
./make.sh
fi

