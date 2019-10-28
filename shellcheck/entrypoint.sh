#!/bin/bash

set -exv

# requires checkout action to have run
cd "$GITHUB_WORKSPACE"
find . -iname \*.sh -exec shellcheck {} +
