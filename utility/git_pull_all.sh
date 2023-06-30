#!/bin/bash

# Set the base directory
base_dir=~/workspace/git-depot/unleashed_200.15

# Define an array of repositories
repos=(
  apps
  atheros
  buildroot
  controller
  controller/common
  dl
  linux/kernels/linux-4.4.60
  qdrops
  scg/common
  scg/control_plane
  video54
)

# ANSI color escape sequences
GREEN='\033[0;32m'
RESET='\033[0m'

# Change to the base directory
cd "$base_dir"

# Loop through each repository and run "git pull"
for repo in "${repos[@]}"; do
  # Change to the repository directory
  cd "$repo" || continue

  # Get the current branch name
  branch=$(git rev-parse --abbrev-ref HEAD)

  # Display the repository and branch name in green color
  echo -e "${GREEN}Updating $repo ($branch)...${RESET}"

  # Prompt the user for confirmation
  read -n 1 -rp "Press Enter to update or any other key to skip: " input
  echo
  # Check if the input is other than Enter
  if [[ $input != "" ]]; then
    echo "Skipping $repo..."
  else
    # Run "git pull"
    git pull
  fi


  # Change back to the base directory
  cd "$base_dir"
done

