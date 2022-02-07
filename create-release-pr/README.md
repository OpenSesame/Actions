### Behavior

This action will create a pull request from the `release/0000` branch against `master`.

#### Env vars worth setting:

- `TARGET_BRANCH` - the name of the branch to create the PR against (defaults to `master`)
- `GIT_USER_NAME` - username for automated commit user
- `GIT_USER_EMAIL` - email for automated commit user
- `PULL_REQUEST_TITLE` - name of the pull request to create (defaults to `Release PR`)
- `RELEASE_BRANCH_NAME` - name of the release branch (defaults to `release/0000`)

### Usage

Include the create-release-pr action in a workflow, for example:

```yaml
name: lint

on: 
  schedule:
    # Every Monday at 12:00am UTC
    cron: 0 0 * * 1

jobs:
  create-release-pr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - uses: opensesame/Actions/create-release-pr@master
```