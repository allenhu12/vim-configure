#!/usr/bin/bash
# BRANCH_NAME should be something like dev/unleashed_200.15.99 or release/unleashed_200.15
# run this script anywhere, the basic format should be ./git_branch_worktree.sh dev/unleashed_200.15.99
export GIT_ROOT="/home/hubo/workspace/git-depot/unleashed_200.13"
export repo_list="apps atheros/linux qdrops build-tools buildroot dl controller controller/common linux/kernels/linux-4.4.60 scg/common scg/control_plane/rcli video54"
BRANCH_NAME=$1
REPO_NAME=$2

# for repo in $repo_list; do echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch; done; cd ${GIT_ROOT};
echo "branch is $BRANCH_NAME, repo is $REPO_NAME"
if [ ! -f /home/hubo/workspace/git-depot/${BRANCH_NAME} ]; then
    mkdir -p /home/hubo/workspace/git-depot/${BRANCH_NAME}
fi
if [ ! -z $REPO_NAME ]; then
    cd ${GIT_ROOT}/${REPO_NAME}
    CMD="cd ${GIT_ROOT}/${REPO_NAME} ; git fetch ; git worktree add --checkout -b $BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$REPO_NAME origin/${BRANCH_NAME}"
    echo "$CMD"
    read -p "Press any key to continue... " -n1 -s
    cd ${GIT_ROOT}/${REPO_NAME}
    git fetch
    git worktree add --checkout -b $BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$REPO_NAME origin/${BRANCH_NAME}
else
    #cd ${GIT_ROOT}
    for repo in $repo_list
    do
        cd ${GIT_ROOT}/${repo}
        CMD="git fetch ; git worktree add --checkout -b $BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$repo origin/${BRANCH_NAME}"
        echo "$CMD"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo}
        git fetch
        git worktree add --checkout -b $BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$repo origin/${BRANCH_NAME}
    done
fi

# for repo in $repo_list
# do
#     echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch;
# done




