### Behavior

This action will create a pull request from a release branch against `master`. It determines the release branch to create the PR for based on the current day using the following code:
```shell
function get_release_branch() {
    BRANCH_DATE_STRING=$(date '+%m%d')
    echo "release/$BRANCH_DATE_STRING"
}
```
This code will look for a branch called `release/MMDD` where `MMDD` is the current month and day that the action is running. You should schedule the action to run on the day of the release. (Note the action runs in the UTC timezone)

#### Env vars worth setting:

- `TARGET_BRANCH` - the name of the branch to create the PR against (defaults to `master`)
- `GIT_USER_NAME` - username for automated commit user
- `GIT_USER_EMAIL` - email for automated commit user
- `PULL_REQUEST_TITLE` - name of the pull request to create (defaults to `Release PR`)

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