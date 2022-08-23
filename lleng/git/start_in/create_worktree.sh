#!/bin/bash

TOP_DIR=/opt/mycompile
TOP_WKTREE_DIR=/opt/worktree
BRANCH_NAME=relase/ap_118.0
tmp_prject_dir=/tmp/work_git
repo_xml=unleashed.xml
tmp_prject_file=$tmp_prject_dir/project_dir.txt

creat_tmp_dir(){
[ ! -d $tmp_prject_dir ] || mkdir -p $tmp_prject_dir
}
clean_tmp_dir(){
[ -d $tmp_prject_dir ] || mkdir -p $tmp_prject_dir
}

creat_tmp_dir
#   <project  path="apps" name="apps"/>
#   <project  path="qdrops" name="qdrops"/>
#   <project  path="atheros/linux" name="platform_dp"/>
#   <project  path="dl" name="dl"/>
#   <project  path="buildroot" name="buildroot"/>
#   <project  path="build-tools" name="build-tools"/>
#   <project  path="controller" name="controller"/>
#   <project  path="controller/common" name="ap_zd_controller"/>
#   <project  path="video54" name="video54"/>
#   <project  path="scg/common" name="ap_scg_common"/>
#   <project  path="scg/control_plane/rcli" name="ap_scg_rcli"/>
#   <project  path="linux/kernels/linux-2.6.32.24" name="linux_2_6"/>
#   <project  path="linux/kernels/linux-3.14.43" name="linux_3_14"/>
#   <project  path="linux/kernels/linux-4.4.60" name="linux_4_4"/>

create_work_tree()
{
    local remote_branch_name=$1
    local work_branch_name="dev/$2"
    local work_branch_dir=${TOP_WKTREE_DIR}/${work_branch_name}
    local create_dir=""
    local line=""
    local p_name=""
    local p_dir=""
    local src_dir=""

    cat $TOP_DIR/.repo/manifests/$repo_xml | grep project > $tmp_prject_file

    while read line; do
        echo "$line"
        p_name=`echo "$line" | grep 'path="'| awk  '{print $2}' | awk -F'"' '{print $2}'`
        echo "${p_name}"
        create_dir=$work_branch_dir/${p_name}
        src_dir=${TOP_DIR}/${p_name}
        echo "$create_dir"
        if [ ! -d $create_dir ];then          
            echo "$create_dir is not existed, add banch ${remote_branch_name} to $create_dir."
            cd $src_dir
            git worktree add -b $work_branch_name $create_dir
            cd $create_dir
            git branch --set-upstream-to=origin/$remote_branch_name $work_branch_name
        fi
    done < $tmp_prject_file
    # cd $TOP_DIR
    # cd buildroot
    # create_dir=$work_branch_dir/buildroot
    # if [ ! -d $create_dir ];then
    #     echo "$create_dir is not existed, add banch ${branch_name} to $create_dir."
    #     git worktree add -b $branch_name $create_dir
    #     cd $create_dir
    #     git branch --set-upstream-to=origin/$branch_name $branch_name
    # fi
}

creat_work_tree(){
    local remote_branch_name="$1"
    local work_branch_name="$2"
    local p_name="$3"
    local src_git_dir=${TOP_DIR}/${p_name}
    local work_branch_top_dir=${TOP_WKTREE_DIR}/${work_branch_name}
    local work_branch_git_dir=${work_branch_top_dir}/${p_name}

    echo "maping $src_git_dir to $work_branch_git_dir"

    if [ ! -d $work_branch_git_dir ];then          
        echo "$work_branch_git_dir is not existed, add banch ${remote_branch_name} to it"
        cd $src_git_dir
        git worktree add -b $work_branch_name $work_branch_git_dir
        cd $work_branch_git_dir
        git branch --set-upstream-to=origin/$remote_branch_name $work_branch_name
    fi

}
exec_git_cmd()
{
    local type="$1"
    local remote_branch_name="$2"
    local work_branch_name="$3"
    local line=""
    local p_name=""
    local src_git_dir=""

    cat $TOP_DIR/.repo/manifests/$repo_xml | grep project > $tmp_prject_file

    while read line; do
        echo "$line"
        p_name=`echo "$line" | grep 'path="'| awk  '{print $2}' | awk -F'"' '{print $2}'`
        echo "path:${p_name}"
  
        if [ $type ]
            creat_work_tree "$remote_branch_name" "$work_branch_name" "$p_name"
        fi
    done < $tmp_prject_file
}
cmd=$1

show_usage(){
show_comm_usage    
echo "
Version 1.0
usage: $0   -c|--create   remote_branch_name  local_branchname           ;create new worktree .
example 5:  $0 -c release/unleashed_200.13  dev/rmmodko_11ax

"

if [ "create" = "$cmd" ] || [ "-c" = "$cmd" ];then
    exec_git_cmd "create" "$1"  "$2"
elif [ "run" = "$cmd" ] || [ "-r" = "$cmd" ];then
    exec_git_cmd "run" "$2"
elif [ "test" = "$cmd" ] || [ "-t" = "$cmd" ];then    
exec_git_cmd "create" "release/unleashed_200.13"  "dev/rmmodko_11ax"    
else
    show_usage    
fi

clean_tmp_dir