#!/bin/bash 

#
# Purpose: 
#   1.  Setup the git user.name and user.email
#   2.  Setup the git config --global init.templatedir $GIT_TEMPLATE_DIR
#   3.  Download the client hooks from $URL_CLIENT_HOOKS
#   4.  Setup the $GIT_TEMPLATE_HOOKS_DIR symbolic link to $RKS_CLIENT_HOOKS_DIR
#   5.  Setup the git config --global commit.template $COMMIT_TMPLATE_TEXT_FILE
#
# Usage:
# ./rks_client_hooks_setup.sh
#
# Author: Brian Pang
# Date: Aug 18, 2020
#

GIT_TEMPLATE_DIR="$HOME/.git-templates"
GIT_TEMPLATE_HOOKS_DIR="$GIT_TEMPLATE_DIR/hooks"
RKS_CLIENT_DIR="$HOME/rks_client_hooks"
URL_CLIENT_HOOKS='ssh://git@ruckus-git.ruckuswireless.com:7999/wrls/client_hooks_bash.git'
basename_with_ext="${URL_CLIENT_HOOKS##*/}"
basename_without_ext=${basename_with_ext%.*}
RKS_CLIENT_HOOKS_DIR="$RKS_CLIENT_DIR/${basename_without_ext}"

COMMIT_TMPLATE_TEXT_FILE="$HOME/.gitmessage.txt"

trace=0
ERROR_COUNT=0

assertInstalled() {
    if [[ $trace = 1 ]] ; then echo "In assertInstalled"; fi
    for app in "$@"; do
        if ! command -v $app &> /dev/null; then
            echo "Missing $app;  Please install $app first."
            ERROR_COUNT=$((ERROR_COUNT+1))
        else
            if [[ $trace = 1 ]] ; then echo "$app ok"; fi
        fi
    done
}

check_env_variables() {
    if [[ -z "${HOME}" ]] ; then
        echo "The environment variable \$HOME is not set.  Please set it before continuing..." 
        ERROR_COUNT=$((ERROR_COUNT+1))
    else
        if [[ $trace = 1 ]] ; then echo "HOME=${HOME} was defined"; fi
    fi
}

set_git_username() {
    #local trace=1
    if [[ $trace = 1 ]] ; then echo "In set_git_username"; fi
    USERNAME=`git config --global --get user.name`
    RETVAL=$?
    if [[ $trace = 1 ]] ; then echo "RETVAL=$RETVAL"; echo "USERNAME=$USERNAME"; fi
    if [[ "$RETVAL" -eq "0" ]] ; then
        echo "git config --global user.name is using: $USERNAME"
        read -p "Continue to use $USERNAME? [y/n] : " 
        if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
            read -r -p "Enter your new git user.name : "  username
            `git config --global user.name "$username"` 
            if [[ "$?" -eq "0" ]]; then
                #echo "$username is set successfully."
                :
            else
                echo "$username failed to set."
                ERROR_COUNT=$((ERROR_COUNT+1))
            fi
        fi
    else
        read -r -p "Enter your new git user.name : "  username
        `git config --global user.name "$username"` 
        if [[ "$?" -eq "0" ]]; then
            #echo "$username is set successfully."
            :
        else
            echo "$username failed to set."
            ERROR_COUNT=$((ERROR_COUNT+1))
        fi
    fi
}

set_git_useremail() {
    #local trace=1
    if [[ $trace = 1 ]] ; then echo "In set_git_useremail"; fi
    USEREMAIL=`git config --global --get user.email`
    RETVAL=$?
    if [[ $trace = 1 ]] ; then echo "RETVAL=$RETVAL"; echo "USEREMAIL=$USEREMAIL"; fi
    if [[ "$RETVAL" -eq "0" ]] ; then
        echo "git config --global user.email is using: "$USEREMAIL""
        read -p "Continue to use $USEREMAIL? [y/n] : " 
        if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
            read -r -p "Enter Your new git user.email : "  useremail
            `git config --global user.email "$useremail"` 
            if [[ "$?" -eq "0" ]]; then
                #echo "$useremail is set successfully."
                :
            else
                echo "$useremail failed to set."
                ERROR_COUNT=$((ERROR_COUNT+1))
            fi
        fi
    else
        read -r -p "Enter your new git user.email : "  useremail
        `git config --global user.email "$useremail"`
        if [[ "$?" -eq "0" ]]; then
            #echo "$useremail is set successfully."
            :
        else
            echo "$useremail failed to set."
            ERROR_COUNT=$((ERROR_COUNT+1))
        fi
    fi
}

#
# getPermissionToConfigAllChanges()
# 
#   Ask from this function only once.  It quits here if no permission is obtained.
#
getPermissionToConfigAllChanges()  {
    echo "----------------------------------------------"
    echo "The following configuration will be modified: "
    echo "----------------------------------------------"
    echo "git config --global commit.template $COMMIT_TMPLATE_TEXT_FILE"
    echo "git config --global init.templatedir $GIT_TEMPLATE_DIR"
    #echo "git clone $URL_CLIENT_HOOKS"
    echo ""
    echo "1.  $RKS_CLIENT_HOOKS_DIR directory will be used for the download. "
    echo "2.  The $GIT_TEMPLATE_HOOKS_DIR dirctory will be used for the symbolic link"
    echo "    to $RKS_CLIENT_HOOKS_DIR directory"
    echo ""
    continue_setup
}

###
fill_git_template_text() {
    if [[ $trace = 1 ]] ; then echo "In fill_git_template_text"; fi
    MSGFILE="$COMMIT_TMPLATE_TEXT_FILE"
    echo "Fill content $MSGFILE"
    echo "COMMENT=" > $MSGFILE
    echo "BUG_NUMBER=" >> $MSGFILE
    echo "CODEBASE=" >> $MSGFILE
    echo "COMPONENT=" >> $MSGFILE
    echo "DEV_TREE=" >> $MSGFILE
    echo "SSR_ID=" >> $MSGFILE
    echo "UNIT_TESTS=" >> $MSGFILE
    echo "UNIT_TEST_REPORT_LINK=" >> $MSGFILE
    OUTPUT=$(cat $MSGFILE)
    if [[ $trace = 1 ]] ; then echo "$OUTPUT"; fi
}

set_git_commit_template_text_file() {
    if [[ $trace = 1 ]] ; then echo "In set_git_commit_template_text_file"; fi
    local cmd="git config --global --get commit.template"
    local MSGFILE=`$cmd`
    RETVAL=$? 
    if [[ "$RETVAL" -eq "0" ]]; then
        echo "$cmd successfully."
        echo "MSGFILE=$MSGFILE"
        if [[ -e $MSGFILE ]]; then
            echo "Found existing $MSGFILE"
            read -p "Remove $MSGFILE? [y/n] : " 
            if [[ $REPLY =~ ^[Yy]$ ]] ; then
                `rm -f $MSGFILE`
                RETVAL=$?
                if [[ $RETVAL = 0 ]]; then 
                    echo "Remove $MSGFILE successfully." 
                    fill_git_template_text
                else
                    echo "Failed to remove: $MSGFILE"
                    ERROR_COUNT=$((ERROR_COUNT+1))
                fi
            else
                echo "Reuse $MSGFILE"
            fi
        fi    
    else
        echo "Failed: $cmd"
        ERROR_COUNT=$((ERROR_COUNT+1))
    fi
}

###

#
#  set_git_commit_template_config()
#    Setting the git commit.template config file.
# 
set_git_commit_template_config() {
    if [[ $trace = 1 ]] ; then echo "In set_git_commit_template_config"; fi
    local cmd="git config --global commit.template $COMMIT_TMPLATE_TEXT_FILE"
    if [[ $trace = 1 ]] ; then echo "cmd=$cmd"; fi
    `$cmd`  
    RETVAL=$? 
    if [[ ! "$RETVAL" -eq "0" ]]; then
        echo "Failed: $cmd"
        ERROR_COUNT=$((ERROR_COUNT+1))
    fi
}

#
#  set_git_commit_template()
#    The main entry point for setting the git commit.template config file.
# 
set_git_commit_template() {
    if [[ $trace = 1 ]] ; then echo "In set_git_commit_template"; fi
    CMTMSG=`git config --global --get commit.template`
    RETVAL=$?
    if [[ $trace = 1 ]] ; then echo "RETVAL=$RETVAL"; fi
    if [[ "$RETVAL" -eq "0" ]] ; then 
        echo "git config --global commit.template is currently set to: "
        echo "$CMTMSG" 
        read -p "Continue to use $CMTMSG? [y/n] : " 
        if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
            if [[ $trace = 1 ]] ; then echo "Over-write original."; fi
            set_git_commit_template_config       
        fi

    else
        if [[ $trace = 1 ]] ; then echo "git config --global --get commit.template not set."; fi
        set_git_commit_template_config
    fi
    if [[ $trace = 1 ]] ; then echo "Out set_git_commit_template"; fi
}

create_git_config_templatedir() {
    `git config --global init.templatedir "$GIT_TEMPLATE_DIR"`
    mkdir -p "$GIT_TEMPLATE_HOOKS_DIR"
}

continue_setup() {
    while true; do
        read -p  "Do you want to continue ? [y/n] " ANSWER
        case $ANSWER in
            [Yy]* ) break;;
            [Nn]* ) echo "Exiting"; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

download_client_hooks() {
    local trace=0
    echo "Downloading client hooks"

    if [ -d $RKS_CLIENT_DIR ] ; then
        echo " $RKS_CLIENT_DIR is already on system."
        echo " Warning! This will remove the previous download. "
        continue_setup
    fi   
    if [ -d $RKS_CLIENT_DIR ] ; then
        rm -rf $RKS_CLIENT_DIR
    fi
    mkdir -p $RKS_CLIENT_DIR
    cd $RKS_CLIENT_DIR
    echo "git clone $URL_CLIENT_HOOKS"
    git clone $URL_CLIENT_HOOKS
    RETVAL=$?
    if [[ $trace = 1 ]] ; then 
        echo "RETVAL=$RETVAL"
        pwd
        ls -al
    fi
}

download_client_hooks_no_prompt() {
    local trace=0
    echo "Downloading client hooks"

    #if [ -d $RKS_CLIENT_DIR ] ; then
    #    echo " $RKS_CLIENT_DIR is already on system."
    #    echo " Warning! This will remove the previous download. "
    #    continue_setup
    #fi   
    if [ -d $RKS_CLIENT_DIR ] ; then
        rm -rf $RKS_CLIENT_DIR
    fi
    mkdir -p $RKS_CLIENT_DIR
    cd $RKS_CLIENT_DIR
    echo "git clone $URL_CLIENT_HOOKS"
    git clone $URL_CLIENT_HOOKS
    RETVAL=$?
    if [[ $trace = 1 ]] ; then 
        echo "RETVAL=$RETVAL"
        pwd
        ls -al
    fi
}

config_symlink() {
    cd $GIT_TEMPLATE_HOOKS_DIR
    rm -f *
    ln -s $RKS_CLIENT_HOOKS_DIR/* .
}

setup_symlink() {
    if [ ! -d $GIT_TEMPLATE_HOOKS_DIR ]; then
        echo "GIT_TEMPLATE_HOOKS_DIR=$GIT_TEMPLATE_HOOKS_DIR does not exists."
    fi
    if [ ! -d $RKS_CLIENT_HOOKS_DIR ]; then
        echo "RKS_CLIENT_HOOKS_DIR=$RKS_CLIENT_HOOKS_DIR does not exists."
    fi

    if [ -d $GIT_TEMPLATE_HOOKS_DIR ] && [ -d $RKS_CLIENT_HOOKS_DIR ]; then
        #echo "Both exists"
        #echo "$GIT_TEMPLATE_HOOKS_DIR check if sym link exists"
        GITHOOK="${GIT_TEMPLATE_HOOKS_DIR}/"
        #echo "GITHOOK=$GITHOOK"
        CMD=`ls -al $GITHOOK | grep '\->' `
        if [ "$?" = "0" ]; then
            echo "Previous symbolic link found.  Must be remove before continuing..."
            continue_setup   
            config_symlink
        else
            config_symlink
        fi
    fi
}

setup_symlink_no_prompt() {
    if [ ! -d $GIT_TEMPLATE_HOOKS_DIR ]; then
        echo "GIT_TEMPLATE_HOOKS_DIR=$GIT_TEMPLATE_HOOKS_DIR does not exists."
    fi
    if [ ! -d $RKS_CLIENT_HOOKS_DIR ]; then
        echo "RKS_CLIENT_HOOKS_DIR=$RKS_CLIENT_HOOKS_DIR does not exists."
    fi

    if [ -d $GIT_TEMPLATE_HOOKS_DIR ] && [ -d $RKS_CLIENT_HOOKS_DIR ]; then
        #echo "Both exists"
        #echo "$GIT_TEMPLATE_HOOKS_DIR check if sym link exists"
        GITHOOK="${GIT_TEMPLATE_HOOKS_DIR}/"
        #echo "GITHOOK=$GITHOOK"
        CMD=`ls -al $GITHOOK | grep '\->' `
        if [ "$?" = "0" ]; then
            #echo "Previous symbolic link found.  Must be remove before continuing..."
            #continue_setup   
            config_symlink
        else
            config_symlink
        fi
    fi
}

setup_client_hooks()  {

    local TEMPLATE_DIR=`git config --global --get init.templatedir`
    if [ "$?" = "0" ]; then 
        echo "This program found a configuration :"
        echo "$TEMPLATE_DIR"
        while true; do
            echo "Do you want to remove the current configuration $TEMPLATE_DIR"
            read -p "This program will create a new $GIT_TEMPLATE_DIR/hooks directory [y/n]?" ANSWER
            case $ANSWER in
                [Yy]* ) `git config --unset --global init.templatedir`
                        create_git_config_templatedir 
                        break;;
                [Nn]* ) echo "Exiting $0"; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        
    else
        #echo "git config did not find init.templatedir configuration."
        create_git_config_templatedir 
    fi
}

check_error_count()  {
    if [[ "$ERROR_COUNT" -gt "0" ]]; then exit 1; fi
}

assertInstalled python java
check_env_variables
check_error_count

echo "Running $0 on `date`"

set_git_username
set_git_useremail
check_error_count

# Ask only once here
getPermissionToConfigAllChanges

#set_git_commit_template # this prompts
set_git_commit_template_config
check_error_count

#set_git_commit_template_text_file # this prompt
fill_git_template_text
check_error_count

#setup_client_hooks
create_git_config_templatedir
#download_client_hooks
download_client_hooks_no_prompt
#setup_symlink
setup_symlink_no_prompt

echo "Done running $0 on `date`"

: <<'end_long_comment'
#echo "comment out"
end_long_comment