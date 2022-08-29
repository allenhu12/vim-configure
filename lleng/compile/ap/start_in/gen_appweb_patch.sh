
# please this in buildroot directory

CUR_DIR=`pwd`

WORK_DIR=$CUR_DIR/appweb_for_gen_patch
if [ ! -d "$WORK_DIR" ] ; then
echo "create work directory"
mkdir -vp $WORK_DIR
ls -al $WORK_DIR
fi

cd $CUR_DIR
appweb_patch=$WORK_DIR/appweb_patch.txt
profile_name=.myprofile
if [ -f "$profile_name" ];then
	. $profile_name
	if [ -n "$MY_PROFILE" ];then
    		export PROFILE=$MY_PROFILE
	fi
fi

type=$1
p4dir="/opt/sda/work/new_work"
p4dir="/sdd/new_watch/depot"
#p4dir="/sdd/new_submit/depot"
p4dir="/new_watch/depot"
all_branch="copenhagen_9.10_mr1 datong_9.12.1_mr1 zd_10.0 zd_10.1_11ax zd_10.2 zd_10.3.0"
PATCH_FILE_NAME=patch_appweb-3.4.2

tar_dir=../controller/ac/usr/appWeb/appweb-3.4.2-0-src.tgz
app_dir=$CUR_DIR/../controller/ac/usr/appWeb
APPWEB_VERSION_FILE_NAME=$app_dir/APPWEB_VERSION
if [ ! -f "$APPWEB_VERSION_FILE_NAME" ];then
	APPWEB_VERSION_FILE_NAME=$p4dir/release/zd_10.0/controller/ac/usr/appWeb/APPWEB_VERSION
	if [ ! -f "$APPWEB_VERSION_FILE_NAME" ];then
		APPWEB_VERSION=3.4.2
	fi
fi
if [ -f "$APPWEB_VERSION_FILE_NAME" ];then
	APPWEB_VERSION=`cat $APPWEB_VERSION_FILE_NAME`
	
	if [ "$APPWEB_VERSION" = "2.4.0" ] ; then
	        VERSION=2.4.0
	        TARGZ=appweb-src-${VERSION}-0.tar.gz
	        EXTRACTED=appweb-src-${VERSION}
	else
	        VERSION=3.4.2
	        TARGZ=appweb-${VERSION}-0-src.tgz
	        EXTRACTED=appweb-${VERSION}
	fi
fi
	echo "APPWEB_VERSION: $APPWEB_VERSION"


src_dir=$WORK_DIR/${EXTRACTED}
dst_dir_tail=appWeb/appWeb-src
dst_dir=$WORK_DIR/$dst_dir_tail
mc_change_dir=$WORK_DIR/appWeb.mc
branch_change_dir=$WORK_DIR/appWeb_branch_change

extract_appweb() {
echo ""
echo "*****************"
local extra_dir=$1
if [ ! -d "$extra_dir" ] ; then
   echo "$extra_dir doesn not exist, extracting ${TARGZ}"
   echo "Going to $WORK_DIR"
   cd $WORK_DIR

   if [ ! -d "$WORK_DIR/${EXTRACTED}" ];then
   	tar -zxf $app_dir/${TARGZ}
   fi
   if [ "$WORK_DIR/${EXTRACTED}" != "$extra_dir" ];then
   	echo "cp -Rf  ${EXTRACTED} $extra_dir"
	cp -Rf ${EXTRACTED} $extra_dir
   fi
   cd $CUR_DIR
fi
echo "*****************"
echo ""
}



patch_file_name=patch_appweb-${VERSION}

patch_file=$app_dir/patches/${patch_file_name}
app_patch_file=$app_dir/patches/${patch_file_name}
work_patch_file=$WORK_DIR/${patch_file_name}.work
patch_file_change=$WORK_DIR/${patch_file_name}.change
patch_file_branch=$WORK_DIR/${patch_file_name}.branch
patch_build_tool=$app_dir/patches/patch_appweb-3.4.2_build_tool


PATCH_FILE_NAME_PATH=controller/ac/usr/appWeb/patches/${PATCH_FILE_NAME}
copy_all_patch_file(){
local v=""
echo $all
local topdir=$p4dir
for v in ${all_branch}; do
    #echo "vv:$v"
    src_file="${topdir}/release/$v/${PATCH_FILE_NAME_PATH}"
    filename="$WORK_DIR/${patch_file_name}_${v}_origin"
    #echo "filename:$filename"
    echo "copy $src_file $filename"
    cp $src_file $filename
done
}

copy_all_patch_file_in_docker(){
local v=""
echo $all

for v in ${all_branch}; do
    #echo "vv:$v"
    src_file="$CUR_DIR/../../$v/controller/ac/usr/appWeb/patches/${patch_file_name}"
    filename="$WORK_DIR/${patch_file_name}_${v}_origin"
    #echo "filename:$filename"
    echo "copy $src_file $filename"
    cp $src_file $filename
done
}
is_same_path(){
find $WORK_DIR -name "patch_appweb-*_origin" | xargs cksum  | sort 
}


p4_sync(){
local v=""
local topdir=$p4dir
for v in ${all_branch}; do
    #echo "vv:$v"
    filename="${topdir}/release/$v/${PATCH_FILE_NAME_PATH}"
    #echo "filename:$filename"
    p4 sync -s $filename
done

}

p4_revert(){
local v=""
local topdir=$p4dir
for v in ${all_branch}; do
    #echo "vv:$v"
    filename="${topdir}/release/$v/${PATCH_FILE_NAME_PATH}"
    #echo "filename:$filename"
    p4 revert $filename
done

}



p4_check_out(){
export P4CLIENT=new_watach
p4 info
local v=""
local topdir=$p4dir
for v in ${all_branch}; do
    #echo "vv:$v"
    filename="${topdir}/release/$v/${PATCH_FILE_NAME_PATH}"
    echo "filename:$filename"
    p4 edit $filename
done

}

apply_patch(){
# go to the directory and do it
cd $dst_dir
# patch common stuff
patch -p0 < $patch_file
cd $CUR_DIR
}

extract_orig(){

extract_appweb "$src_dir"
}

copy_patch(){
cp -f $work_patch_file $patch_file

}
extract_dst(){

if [ ! -d "$WORK_DIR/appWeb" ];then
mkdir -vp $WORK_DIR/appWeb
fi

extract_appweb "$dst_dir"
echo "$dst_dir"
}

gen_change() {
cp -f $patch_file $WORK_DIR/
cp -f $patch_file $work_patch_file
cp -f $app_dir/setup  $WORK_DIR/
apply_patch

}

apply_change(){
echo "***********************************************"
echo "** copy $work_patch_file $patch_file **********"
echo "***********************************************"
rm -rf $patch_file
cp -vf $work_patch_file $patch_file
apply_patch
}

show_usage(){

echo "$0 -d		:  all directory patch"
echo "$0 -p		:  pepare directory"
echo "$0 -f [file list]	:  file name list"
echo "$0 -c|change 	:  for change the code"
echo "$0 rm  :  rm work dir"
echo "$0 clean		:  clean all directory"
echo "$0 show		  :  show patch "
echo "$0 copyp   :  copy all patch in docker "
echo "$0 issame   :  get all patch file checksum"
echo "1. first to run $0 -p prepare"
echo "2 run $0 pc"
echo "3. apply change into $dst_dir_tail"
echo "4. run $0 -d"
echo "5. merge the chagne from $appweb_patch  $patch_file_change"
echo "6. run $0 mc apply to $mc_change_dir"
echo "6. run $0 mb apply to $branch_change_dir"
echo "7. run $0 -c apply new patch file"



echo "$0 sync					:  not run in docker"
echo "$0 checkout		  :  not run in docker"
echo "$0 revert  			:  not run in docker"
echo "$0 copypall			: copy all patch "
}

if [ -z "$type" -o "$type" = "-d" ];then
	extract_orig
	cd $src_dir
	echo "start create new patch"
	echo "cuurent dirtory: $src_dir"
	echo "change dirtory: ../$dst_dir_tail"
	echo "patche file: $appweb_patch"
	ls ../$dst_dir_tail
	diff -aur --exclude ajs.lst --exclude buildConfig.h . ../$dst_dir_tail | grep -e "^Only in" -v > $appweb_patch
	cd $CUR_DIR

elif [ "$type" = "-f" ];then
        shift 1
        extract_orig
        echo "$*"
	cd $src_dir
	rm -rf $appweb_patch
	echo "create patche file $appweb_patch"
	diff -aur ./$1 ../appWeb/appWeb-src/$1 | grep -e "^Only in" -v > $appweb_patch
	cd $CUR_DIR

elif [ "$type" = "-h" ];then
show_usage

elif [ "$type" = "copyp" ];then
copy_all_patch_file_in_docker

elif [ "$type" = "copyall" ];then
copy_all_patch_file

elif [ "$type" = "issame" ];then
is_same_path

elif [ "$type" = "sync" ];then
p4_sync
elif [ "$type" = "revert" ];then
p4_revert
elif [ "$type" = "checkout" ];then
p4_check_out

elif [ "$type" = "show" -o "$type" = "-s" ];then
date
ls -al $appweb_patch
ls -al $WORK_DIR
echo "diff $patch_file  $patch_file_branch"
diff -u $patch_file  $patch_file_branch
ls -al $patch_file

elif [ "$type" = "clean" ];then
rm -rf $src_dir $dst_dir
elif [ "$type" = "rm" ];then
echo  "rm $WORK_DIR"
rm -rf $WORK_DIR

elif [ "$type" = "apply" ];then
rm -rf $dst_dir
extract_dst
apply_change

elif [ "$type" = "-p" ];then
rm -rf $WORK_DIR/*
extract_orig
extract_dst
gen_change

elif [ "$type" = "-c" -o "$type" = "change" ];then
rm -rf $dst_dir
echo ""
echo "**********************"
#echo "Copy $appweb_patch to $work_patch_file"
#rm -rf $work_patch_file
#cp $appweb_patch $work_patch_file
extract_dst
gen_change
elif [ "$type" = "pc" ];then
echo "copy $patch_file  to $patch_file_change"

cp -f $patch_file  $patch_file_change
cp -f $patch_file  $patch_file_branch
elif [ "$type" = "mc" ];then
    echo "copy $patch_file_change to $patch_file"
    rm -rf $dst_dir
    cp -f $patch_file_change $patch_file
    extract_dst
    gen_change
    rm -rf $mc_change_dir
    cp -Rf $WORK_DIR/appWeb/ $mc_change_dir

elif [ "$type" = "mb" ] || [ "$type" = "mbf" ];then
    rm -rf $dst_dir
    
if [ "$type" = "mbf" ];then
    echo "copy $app_patch_file $patch_file_branch"
    cp -f $app_patch_file  $patch_file_branch
else
    echo "copy $patch_file_branch to $patch_file"
    cp -f $patch_file_branch $patch_file
fi
    extract_dst
    gen_change
    rm -rf $branch_change_dir
    cp -Rf $WORK_DIR/appWeb/ $branch_change_dir
fi

chmod -R 777 $WORK_DIR
 	

