# Automerge

## Configuration

- Generate a fresh SSH keypair
- Add the public key as a write-access deploy key to the repo
- Create a new secret called `DEPLOY_KEY` with the private key in PEM format
- Add env setting 'MERGE_LABEL' with the label to be scanned for on all pull requests to auto merge
- Note: both `DEPLOY_KEY` and `GITHUB_TOKEN` are required for functionality

### Env vars worth setting:

- `GIT_USER_NAME` - username for automated commit user
- `GIT_USER_EMAIL` - email for automated commit user

## Notes

- We hardcode Github's SSH pubkeys into our known_hosts for security reasons
  - these are gotten via: `ssh-keyscan github.com`
  - For unknown reasons this no longer works, temporary fix is to ignore host keys
    - Noted with a FIXME
- Expects `develop` branch to exist already by convention
  - provides a sane error message if an expected branch does not exist

### Merges all pull requests as follows:

- All open pull requests labeled with the label specified in the 'MERGE_LABEL' env setting will be merged.

## Example workflow

```yaml
name: automerge
on:
  schedule:
    - cron: "*/30 * * * *"
jobs:
  automerge:
    runs-on: ubuntu-latest
    steps:
      # checks out out repo to $GITHUB_WORKSPACE
      # note: this has to be a full clone to avoid "fatal: refusing to merge unrelated histories"
      - uses: actions/checkout@v1
        uses: ./automerge
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          MERGE_LABEL: "automerge"
```
