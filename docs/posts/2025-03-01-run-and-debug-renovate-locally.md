---
date: 2025-03-01
tags:
  - github
  - renovate
  - updates
---

# Run and debug Renovate locally

Last I gave a quick introduction to [Renovate](https://docs.renovatebot.com/) and how to run it in centralised configuration. Today we will go over how to run Renovate locally for debugging and extending configuration purpose, which is very handy.

```bash
npx --yes --package renovate -- renovate --dry-run=full --token="GITHUB_TOKEN" wcarlsen/repository0
```

This requires only a Github token and to change `LOG_LEVEL`, just set it as an environment variable to `DEBUG`.

Now go customise your `config.js` or `renovate.json` config files to get the best out of Renovate.
