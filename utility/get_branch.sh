#!/usr/bin/bash
export GIT_ROOT="/home/hubo/workspace/git-depot/unleashed_200.13"
export repo_list="apps atheros/linux qdrops build-tools buildroot dl controller controller/common linux/kernels/linux-4.4.60 scg/common scg/control_plane/rcli"

# for repo in $repo_list; do echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch; done; cd ${GIT_ROOT};

for repo in $repo_list
do
    echo -e "\e[1;41m***repo:${repo}\e[0m" && cd ${GIT_ROOT}/${repo} && git fetch;
done




