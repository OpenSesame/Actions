# Shellcheck

## Behavior

Runs [shellcheck](https://github.com/koalaman/shellcheck) on all files matching `*.sh` in the repo.

## Usage

Include the shellcheck action in a workflow, for example:

```yaml
name: lint

on: [push]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
        with:
          fetch-depth: 1
      - uses: opensesame/Actions/shellcheck@v1
```
