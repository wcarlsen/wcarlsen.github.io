---
date: 2026-11-07
tags:
  - github
---

# Release on push GitHub workflow

I have for a long time been using automatic creation of releases on push for some of the projects that I've been working on. So when merging a PR with labels `release:{norelease,patch,minor,major}` a workflow would create the according release, e.g. `v1.2.3`. Recently I had to expand this functionality so that both major and minor tags (mutable) will be produced, in this case `v1` and `v1.2`. Here is what I ended up implementing.


```yaml
name: auto-release-on-push

on:
  push:
    branches:
      - main

jobs:
  release-on-push:
    runs-on: ubuntu-latest
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: rymndhng/release-on-push-action@v0.28.0
        id: release-on-push
        with:
          bump_version_scheme: patch
          tag_prefix: v
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: haya14busa/action-update-semver@v1.5.1
        with:
          major_version_tag_only: false
          tag: ${{ steps.release-on-push.outputs.tag_name }}
```

There are probably other solutions doing this and maybe even better, but this is what I ended up doing.
