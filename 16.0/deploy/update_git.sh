#!/bin/sh
echo "Starting update git script"

# Check if a .env file with the same name as the script exists in the same path and source it
SCRIPT_PATH="$(dirname "$0")"
SCRIPT_NAME="$(basename "$0" .sh)"
ENV_FILE="${SCRIPT_PATH}/${SCRIPT_NAME}.env"

if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE"
    # Source the .env file and export all variables
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        if [[ $key =~ ^[[:space:]]*# ]] || [[ -z $key ]]; then
            continue
        fi
        # Remove leading/trailing whitespace
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Export the variable, overwriting any existing value
        echo "${key}=${value}"
        export "$key=$value"
    done < "$ENV_FILE"
else
    echo "No environment file $ENV_FILE found, using default environment variables"
fi

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

chmod 700 /github_deploy_key

ssh-keyscan github.com >> /known_hosts
git config --global --add safe.directory /repo

# Check if the repository already exists
if [ ! -d "/repo/.git" ]; then
    echo "Repository not found, cloning from $REPO_URL"
    GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git clone --branch "$BRANCH" --recurse-submodules "$REPO_URL" /repo
    echo "Cloning done"
    exit 0
fi

# Change directory to the repository
cd /repo

# Check current branch
echo "Checking current branch"
CURRENT_BRANCH=$(GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Could not determine current branch"
    exit 1
fi

# Check if we need to switch branches
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "Current branch is $CURRENT_BRANCH, target branch is $BRANCH"
    echo "Switching branch from $CURRENT_BRANCH to $BRANCH"
    
    # Try to checkout the target branch
    GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git checkout "$BRANCH"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to checkout branch $BRANCH"
        echo "Attempting to create and switch to new branch..."
        
        # Try to create and switch to a new branch from the current HEAD
        GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git checkout -b "$BRANCH"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create and checkout branch $BRANCH"
            exit 1
        fi
    fi
    
    echo "Successfully switched to branch $BRANCH"

    # Ensure branch has an upstream; if not, set it if origin/$BRANCH exists.
    # Otherwise fall back to using explicit pull args later.
    PULL_ARGS=""
    if ! GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        echo "No upstream configured for branch $BRANCH"
        if GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
            echo "Remote branch origin/$BRANCH exists — setting upstream"
            GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git branch --set-upstream-to=origin/"$BRANCH" "$BRANCH" || true
        else
            echo "Remote branch origin/$BRANCH does not exist — will use explicit pull from origin/$BRANCH"
            PULL_ARGS="origin $BRANCH"
        fi
    fi
fi

# Fetch updates from the remote repository
GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git fetch origin

# If COMMIT_HASH is not specified, use the latest commit
if [ -z "$COMMIT_HASH" ]; then
    echo "COMMIT_HASH not specified, using the latest commit from branch $BRANCH"
    LATEST_COMMIT=$(GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git ls-remote origin "$BRANCH" | tail -n 1)
    echo "Latest commit is $LATEST_COMMIT"
    COMMIT_HASH=$(echo "$LATEST_COMMIT" | awk '{print $1}')
fi

GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git fetch origin --prune "$COMMIT_HASH" 
GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git merge "origin/$BRANCH"
#GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git submodule sync --recursive
GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git submodule update --init --recursive

# Ensure the branch is up-to-date
echo "Ensure the branch is up-to-date"
GIT_SSH_COMMAND="ssh  -o 'UserKnownHostsFile /known_hosts' -i /github_deploy_key" git pull

echo "Repository updated to branch $BRANCH commit: $COMMIT_HASH"

# Set write permissions only if WRITABLE_REPO is set
if [ -n "$WRITABLE_REPO" ]; then
    chmod -R a+w "/repo"
    echo "Write permissions set for repository"
else
    echo "WRITABLE_REPO not set, keeping default permissions"
fi

echo "Update script finished"
