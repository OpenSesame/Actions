#!/bin/bash

# exit on errors
# add -xv to debug
set -e
set -o pipefail

# if set, use that, else default
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-/tmp/ssh_agent.sock}"
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

if [[ -z "${MERGE_LABEL}" ]]; then
    echo "You must include the MERGE_LABEL as an environment variable."
    exit 1
fi

# actions/checkout step has to be run beforehand
# this dir is mounted into the container
cd "${GITHUB_WORKSPACE}"

# get branches for all remotes
git fetch --all

# clean up merged branches
git remote prune origin

function merge_pull_request() {
    echo "DEBUG: making pull request from $2 to $1"

    # subshell with +e so we continue on errors
    (
        set +e

        # checkout destination branch,
        # merge PR and push merge commit
        git fetch origin "${1}" && \
        git checkout "${1}" && \
        git reset --hard origin/"${1}"
        # create merge commit
        hub merge "${2}" && \
        echo "DEBUG: successfully merged ${GITHUB_REF} into $1" || \
        echo "DEBUG: merging ${GITHUB_REF} into $1 failed"
        # pushes merge commit
        git push origin "${1}" && \
        echo "DEBUG: successfully pushed ${GITHUB_REF} merged into $1" || \
        echo "DEBUG: pushing ${GITHUB_REF} merged into $1 failed"

    )
}

#list all open pull requests with labels||url||baseBranch
PRs="$(hub pr list -f "%L||%U||%B%n")"

for $pr in $PRs
do
  read -ra Parts <<< "$(echo $pr | tr "||" "\n")"
  label="${Parts[0]}"
  url="${Parts[1]}"
  base="${Parts[2]}"

  #case insensitive compare by using the ,, to lower case
  if [ "${label,,}" = "${MERGE_LABEL,,}" ]
  then
    merge_pull_request "$base" "$url"
  else
    echo "DEBUG: PR ignored from $url no matching label ($label)"
  fi
done
