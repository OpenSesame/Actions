#!/bin/bash

# exit on errors
# add -xv to debug
set -e
set -o pipefail

# if set, use that, else default
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-/tmp/ssh_agent.sock}"
export PULL_REQUEST_TITLE="${PULL_REQUEST_TITLE:-Release PR}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-build@opensesame.com}"
export GIT_USER_NAME="${GIT_USER_NAME:-automerge}"

# use ssh urls
git config --global url."git@github.com:".insteadOf "https://github.com/"

# git config for merge commits
git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "${GIT_USER_NAME}"
git config --global push.default matching

mkdir -p ~/.ssh
ssh-agent -a "${SSH_AUTH_SOCK}" > /dev/null

# FIXME
# adding the host key doesn't work ?!, this is an unfortunate override
git config --global core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

# add github's pubkey to known_hosts
echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' >> ~/.ssh/known_hosts

# add SSH deploy key via stdin
# output will filter this
if [[ -z "${DEPLOY_KEY}" ]]; then
    echo "Required secret \$DEPLOY_KEY is not set, see README for details."
    exit 1
fi
echo "$DEPLOY_KEY" | ssh-add -

# this is automatically provided if passed
# see: https://help.github.com/en/articles/virtual-environments-for-github-actions#github_token-secret
if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "You must include the GITHUB_TOKEN as an environment variable."
    exit 1
fi

# actions/checkout step has to be run beforehand
# this dir is mounted into the container
cd "${GITHUB_WORKSPACE}"

# get branches for all remotes
git fetch --all

# clean up merged branches
git remote prune origin

function get_release_branch() {
    BRANCH_DATE_STRING=$(date '+%m%d')
    echo "release/$BRANCH_DATE_STRING"
}

function open_pull_request() {
    echo "DEBUG: making pull request from ${GITHUB_REF} to $1"

    # if $1 branch does not exist origin
    if [[ -z "$(git ls-remote origin "$1")" ]]; then
        echo "Could not find expected branch '$1' on remote 'origin'"
    fi

    # subshell with +e so we continue on errors
    (
        set +e

        # check for existing PRs
        PR_URL="$(hub pr list -b "$1" -h "${GITHUB_REF}" -s open -f '%U')"
        if [[ -z "$PR_URL" ]]; then
            # PR did not exist, create it
            PR_URL="$(hub pull-request -b "$1" -h "${GITHUB_REF}" -m "${PULL_REQUEST_TITLE}" -l "automerge")"
        fi
    )
}

# ensure we're on master
#********* if [ "${GITHUB_REF}" == "refs/heads/master" ]; then
if [ "${GITHUB_REF}" == "refs/heads/feature/add_release_pr_creation_action" ]; then
    RELEASE_BRANCH=$(get_release_branch)
    if [[ -z "$(git ls-remote origin "$RELEASE_BRANCH")" ]]; then
        echo "Could not find expected branch '$RELEASE_BRANCH' on remote 'origin'"
        exit 0
    fi
    # create PR from master => develop
    open_pull_request "$RELEASE_BRANCH";
else
    echo "This action can only be run on the master branch"
    exit 1
fi