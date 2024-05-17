#!/bin/sh

# Check if the REPO_URL variable is set
if [ -z "$REPO_URL" ]; then
    echo "REPO_URL variable not set. Please provide the GitHub repository URL."
    exit 1
fi
if [ -z "$BRANCH" ]; then
    echo "BRANCH variable not set. Please provide the branch name."
    exit 1
fi

echo "Start repository update"

ssh-keyscan github.com >> /known_hosts

# Check if the repository already exists
if [ ! -d "/repo/.git" ]; then
    echo "Repository not found, cloning from $REPO_URL"
    GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git clone --branch "$BRANCH" --recurse-submodules "$REPO_URL" /repo
    echo "Cloning done"
    exit 0
fi

# Change directory to the repository
cd /repo

GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git reset --hard

# Fetch updates from the remote repository
GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git fetch origin

# If COMMIT_HASH is not specified, use the latest commit
if [ -z "$COMMIT_HASH" ]; then
    LATEST_COMMIT=$(GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git ls-remote --sort=committerdate | grep HEAD)
    echo "Latest commit is $LATEST_COMMIT"
    COMMIT_HASH=$(echo "$LATEST_COMMIT" | awk '{print $1}')
fi

GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git fetch origin "$COMMIT_HASH" 
GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git merge "origin/$BRANCH"
GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git submodule update --init --recursive

# Ensure the branch is up-to-date
#GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git pull

echo "Repository updated to branch $BRANCH commit: $COMMIT_HASH"
