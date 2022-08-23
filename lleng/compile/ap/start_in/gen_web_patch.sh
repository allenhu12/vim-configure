#!/bin/sh

# please this in buildroot directory

curr_dir=

type=$1

src_dir=

if [ -z "$type" -o "$type" = "-d" ];then
diff -aur --exclude ajs.lst --exclude buildConfig.h
elif [ "$type" = "-f" ];then
shift 1
echo "$*"
fi 
