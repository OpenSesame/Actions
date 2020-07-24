### Behavior

This action will create a pull request from a release branch against `master`. It determines the release branch to create the PR for based on the current day using the following code:
```shell
function get_release_branch() {
    BRANCH_DATE_STRING=$(date '+%m%d')
    echo "$RELEASE_BRANCH_PREFIX$BRANCH_DATE_STRING"
}
```
This code will look for a branch called `release/MMDD` (release/ is the default `RELEASE_BRANCH_PREFIX`) where `MMDD` is the current month and day that the action is running. You should schedule the action to run on the day of the release. (Note the action runs in the UTC timezone)

The action is also capable of looking ahead a few days incase your release occasionally drifts from the same week day. 

#### Env vars worth setting:

- `TARGET_BRANCH` - the name of the branch to create the PR against (defaults to `master`)
- `GIT_USER_NAME` - username for automated commit user
- `GIT_USER_EMAIL` - email for automated commit user
- `PULL_REQUEST_TITLE` - name of the pull request to create (defaults to `Release PR`)
- `RELEASE_BRANCH_PREFIX` - prefix for the release branch where the date will be appended (defaults to `release/`)
- `MAX_RANGE` - number of days you would like for the action to look in advance for release branches that may be set for other days. For example if you normally release Monday's but every so often have your release on a Tuesday (defaults to 1)

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