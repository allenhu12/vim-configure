CUR_DIR=`pwd`
export JAVA_HOME=/etc/alternatives/java_sdk/
#export PROFILE=ap-11n-scorpion-unleashed

 
if [ -f ".myprofile" ];then
. .myprofile
	if [ -n "$MY_PROFILE" ] ;then
		export PROFILE=$MY_PROFILE
	fi
fi
NO_OUT_XXX="
/root/ext_toolchain_/ext_Toolchain/ap-arm-11ax/tools
BR2_UCLIBC_CONFIG          = /opt/mycompile/release/ap_114.1/buildroot/build/4.4.60_gcc-linaro-4.8-2014.04/toolchain_build_arm_release/uClibc-0.9.33.2
STRIP                      = /opt/mycompile/release/ap_114.1/buildroot/tools/4.4.60_gcc-linaro-4.8-2014.04/bin/arm-linux-uclibc-strip --remove-section=.comment --remove-section=.note
mkdir -p /opt/mycompile/release/ap_114.1/buildroot/

ap-arm-11ax
mv /opt/mycompile/release/ap_114.1/buildroot/build/4.4.60_gcc-linaro-4.8-2014.04 /root/ext_toolchain_/ext_Toolchain/ap-arm-11ax/build/
mv /opt/mycompile/release/ap_114.1/buildroot/tools/4.4.60_gcc-linaro-4.8-2014.04 /root/ext_toolchain_/ext_Toolchain/ap-arm-11ax/tools/


ap-arm-dakota
/opt/mycompile/release/ap_114.0_p1/buildroot/build/3.14.43_gcc-linaro-4.8-2014.04 /root/ext_toolchain_/ext_Toolchain/ap-arm-dakota/build/
/opt/mycompile/release/ap_114.0_p1/buildroot/tools/3.14.43_gcc-linaro-4.8-2014.04 /root/ext_toolchain_/ext_Toolchain/ap-arm-dakota/tools/

root@lester-desktop:~# ls -l /sdd/ext_toolchain_/ext_Toolchain/ap-arm-11ax/ 
total 8
drwxr-xr-x 3 root root 4096 Jul 22 09:39 build
drwxr-xr-x 3 root root 4096 Jul  9 20:00 tools
"

if [ "$TOOLCHAIN_OPT" = "FALSE" ] ;then
    export TOOLCHAIN_OPT=FALSE
fi

echo "profile: ${PROFILE}"
#if director start for ZD use opt toolchain.
if [ "${PROFILE:0:8}" = "director" ] || [ "${PROFILE:0:6}" = "ap-11n" ];then
     echo "it is ZD or ap-11n profile use buildroot tool chian."
     export TOOLCHAIN_OPT=FALSE
fi  

export_tftp_dir() {
# goto the parent directory and get the code_tree name
cd $CUR_DIR/..
BINBLD_TREE=`pwd`
CODE_TREE=`if [ -d ${BINBLD_TREE}/../../release ]; \
		   then basename ${BINBLD_TREE}; \
		   else if [ -d ${BINBLD_TREE}/../../../private ]; \
		        then echo ${BINBLD_TREE} | sed 's/^.*depot\///g'; \
		        else echo mainline; \
				fi \
		   fi`



TAR_NAME=`cat $CUR_DIR/profiles/$PROFILE/build_bin`
TAR_VER=${TAR_NAME%_*}
TAR_VER=${TAR_VER#*_}
SUB_VER=${TAR_VER%\.*}

if [ "$TFTP_SUB" != "" ];then
	tftp_sub_dir="$TFTP_SUB"
else
	tftp_sub_dir="${COMPILE_NAME%\.*}"
fi

echo 

echo "TFTPBOOT            = $BIN_DEPOT/$CODE_TREE"
echo 
echo "compilename: $COMPILE_NAME $tftp_sub_dir"

if [ "$TFTP_SUB" != "" ];then
	export TFTPBOOT=/opt/tftpboot/$CODE_TREE/${TFTP_SUB}
else
	export TFTPBOOT=/opt/tftpboot/$CODE_TREE
fi	
echo "TFTPBOOT            = $TFTPBOOT"
# goto current dir to make
cd $CUR_DIR
}

export_tftp_dir
cd $CUR_DIR

make $@

if [ "${PROFILE: -9}" == "unleashed" ];then
	echo "rm unleash not used image"
	echo "find $TFTPBOOT -name \"zd1k_*.no_ap.img\" | xargs rm -f"
	find $TFTPBOOT -name "zd1k_*.no_ap.img" | xargs rm -f
fi
