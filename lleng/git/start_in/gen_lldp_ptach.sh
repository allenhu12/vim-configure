
# please this in buildroot directory

CUR_DIR=`pwd`

WORK_DIR=$CUR_DIR/lldp_for_gen_patch
LLDPD_DIR=$CUR_DIR/package/lldpd
patch_file="06-lldpd.patch"
branch_patch_file="branch-lldpd.patch"
new_patch_file="new_lldpd.patch"
if [ ! -d "$WORK_DIR" ] ; then
echo "create work directory"
mkdir -vp $WORK_DIR
ls -al $WORK_DIR
fi

cd $WORK_DIR
TEMP_DIR="temp_dir"
TEST_DIR="test_dir"
type=$1







apply_patch(){
local dst_dir=$1
echo "curent dictory: `pwd`"
zcat ${CUR_DIR}/dl/lldpd-0.7.1.tar.gz | tar -C $WORK_DIR/ -xf -
${CUR_DIR}/patch-kernel.sh ${WORK_DIR}/lldpd-0.7.1 ../package/lldpd/ "*lldpd.patch"

if [ -n "$dst_dir" ] && [ "$dst_dir" != "lldpd-0.7.1" ];then
    mv lldpd-0.7.1 $dst_dir
fi
}

apply_patch_3(){
local dst_dir=$1
echo "curent dictory: `pwd`"
if [ -n "$dst_dir" ] ;then
mkdir -p ${TEMP_DIR}
zcat ${CUR_DIR}/dl/lldpd-0.7.1.tar.gz | tar -C $WORK_DIR/${TEMP_DIR}/ -xf -
${CUR_DIR}/patch-kernel.sh ${WORK_DIR}/${TEMP_DIR}/lldpd-0.7.1 ../package/lldpd/ "*lldpd.patch"
mv ${WORK_DIR}/${TEMP_DIR}/lldpd-0.7.1 ${WORK_DIR}/${dst_dir}
rm -rf  ${TEMP_DIR}
else
echo "please give the dictory!!!"
fi

}

apply_patch_2(){
local dst_dir=$1
echo "curent dictory: `pwd`"
if [ -n "$dst_dir" ] ;then
mkdir -p "$dst_dir"
zcat ${CUR_DIR}/dl/lldpd-0.7.1.tar.gz | tar -C $WORK_DIR/$dst_dir/ -xf -
${CUR_DIR}/patch-kernel.sh ${WORK_DIR}/${dst_dir}/lldpd-0.7.1 ../package/lldpd/ "*lldpd.patch"
#this have error.
#mv: `/opt/mycompile/release/ap_100.0.1.0_mr1/buildroot/lldp_for_gen_patch/lldpd-0.7.1-mc/lldpd-0.7.1' and `lldpd-0.7.1-mc/lldpd-0.7.1' are the same file
mv ${WORK_DIR}/${dst_dir}/lldpd-0.7.1 ${dst_dir}
else
echo "please give the dictory!!!"
fi

}

extract_dir(){
apply_patch_3 "lldpd-0.7.1-old"
apply_patch_3 "lldpd-0.7.1-new"
}



show_usage(){

echo "$0 -d		:  all directory patch"
echo "$0 -p		:  pepare directory"
echo "$0 -f [file list]	:  file name list"
echo "$0 -c|change 	:  for change the code"
echo "$0 rm  :  rm work dir"
echo "$0 clean		:  clean all directory"
echo "$0 show		:  show patch "
echo "1. first to run $0 -p prepare"
echo "2 run $0 pc"
echo "3. apply change into $dst_dir_tail"
echo "4. run $0 -d"
echo "5. merge the chagne from $appweb_patch  $patch_file_change"
echo "6. run $0 mc apply to $mc_change_dir"
echo "6. run $0 mb apply to $branch_change_dir"
echo "7. run $0 -c apply new patch file"

}

if [ -z "$type" -o "$type" = "-d" ];then
    diff -rupN lldpd-0.7.1-old lldpd-0.7.1-new > $patch_file
	cd $CUR_DIR
elif [ "$type" = "-h" ];then
show_usage
elif [ "$type" = "rm" ];then
echo  "rm $WORK_DIR"
rm -rf $WORK_DIR
elif [ "$type" = "-p" ];then
rm -rf $WORK_DIR/*
extract_dir
elif [ "$type" = "apply" ] || [ "$type" = "-a" ];then

if [ -f "$patch_file" ];then 
echo "$patch_file $LLDPD_DIR"
echo "remove lldpd-0.7.1"
rm -rf ${TEST_DIR}
mkdir -p ${TEST_DIR}
rm -rf lldpd-0.7.1-branch
rm -f  $LLDPD_DIR/$patch_file
apply_patch_3 lldpd-0.7.1-branch

mv lldpd-0.7.1-branch ${TEST_DIR}/lldpd-0.7.1-old
rm -rf lldpd-0.7.1-mc
cp $patch_file $LLDPD_DIR/
apply_patch_3 lldpd-0.7.1-mc

mv lldpd-0.7.1-mc ${TEST_DIR}/lldpd-0.7.1-new
cd ${TEST_DIR}
diff -rupN lldpd-0.7.1-old lldpd-0.7.1-new > $new_patch_file
diff "$new_patch_file" "../$patch_file"
cd ${CUR_DIR}

else
echo "$patch_file not existed, plese generate it!"
fi


elif [ "$type" = "branch" ] || [ "$type" = "-b" ];then

if [ -f "$LLDPD_DIR/$patch_file" ];then 
echo "$patch_file $LLDPD_DIR"
echo "remove lldpd-0.7.1"
rm -rf ${TEST_DIR}
mkdir -p ${TEST_DIR}
rm -rf lldpd-0.7.1-branch
cp $LLDPD_DIR/$patch_file $branch_patch_file
rm -f  $LLDPD_DIR/$patch_file
apply_patch_3 lldpd-0.7.1-branch

mv lldpd-0.7.1-branch ${TEST_DIR}/lldpd-0.7.1-old
rm -rf lldpd-0.7.1-mc
cp $branch_patch_file $LLDPD_DIR/$patch_file
apply_patch_3 lldpd-0.7.1-mc

mv lldpd-0.7.1-mc ${TEST_DIR}/lldpd-0.7.1-new

else
echo "$patch_file not existed, plese generate it!"
fi

fi

chmod -R 777 $WORK_DIR
 	

