#!/usr/bin/bash
export GIT_ROOT="/home/hubo/workspace/git-depot/unleashed_200.13"
export repo_list="apps atheros/linux qdrops build-tools buildroot dl controller controller/common linux/kernels/linux-4.4.60 scg/common scg/control_plane/rcli"
BRANCH_NAME=$1
REPO_NAME=$2

# for repo in $repo_list; do echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch; done; cd ${GIT_ROOT};
echo "branch is $BRANCH_NAME, repo is $REPO_NAME"
if [ ! -f /home/hubo/workspace/git-depot/${BRANCH_NAME} ]; then
    mkdir -p /home/hubo/workspace/git-depot/${BRANCH_NAME}
fi
if [ ! -z $REPO_NAME ]; then
    cd ${GIT_ROOT}/${REPO_NAME}
    CMD="cd ${GIT_ROOT}/${REPO_NAME} ; git worktree add --checkout -b release/$BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$REPO_NAME origin/release/${BRANCH_NAME}"
    echo "$CMD"
    read -p "Press any key to continue... " -n1 -s
    cd ${GIT_ROOT}/${REPO_NAME}
    git worktree add --checkout -b release/$BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$REPO_NAME origin/release/${BRANCH_NAME}
else
    for repo in $repo_list
    do
        CMD="git worktree add --checkout -b release/$BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$repo origin/release/${BRANCH_NAME}"
        echo "$CMD"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo}
        git worktree add --checkout -b release/$BRANCH_NAME /home/hubo/workspace/git-depot/$BRANCH_NAME/$repo origin/release/${BRANCH_NAME}
    done
fi

# for repo in $repo_list
# do
#     echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch;
# done




