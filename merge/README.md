# Merge

## Configuration

- Generate a fresh SSH keypair
- Add the public key as a write-access deploy key to the repo
- Create a new secret called `DEPLOY_KEY` with the private key in PEM format
- Note: both `DEPLOY_KEY` and `GITHUB_TOKEN` are required for functionality

### Env vars worth setting

- `GIT_USER_NAME` - username for automated commit user
- `GIT_USER_EMAIL` - email for automated commit user
- `PULL_REQUEST_TITLE` - name of the pull request to create

## Notes

- We hardcode Github's SSH pubkeys into our known_hosts for security reasons
  - these are gotten via: `ssh-keyscan github.com`
  - For unknown reasons this no longer works, temporary fix is to ignore host keys
    - Noted with a FIXME
- Expects `develop` branch to exist already by convention
  - provides a sane error message if an expected branch does not exist

### Creates pull requests as follows

- If we're on master:
  - Open PRs with changes from head branch master onto base branches matching:
    - 'release/\d{4}$'
    - 'hotfix/.*'
- If we're on a branch matching 'release/\d{4}$':
  - Open PRs from each release branch to develop
- If we're on develop:
  - Open PRs with changes from head branch develop onto base branches matching 'sprint/.*'

## Example workflow

```yaml
name: merge

on:
  push:
    branches:
      - 'master'
      - 'release/*'
      - 'develop'

jobs:
  merge:
    runs-on: ubuntu-latest
    steps:
    # checks out out repo to $GITHUB_WORKSPACE
    # note: this has to be a full clone to avoid "fatal: refusing to merge unrelated histories"
    - uses: actions/checkout@v1
    - uses: opensesame/Actions/merge@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
```
