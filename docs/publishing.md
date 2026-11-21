---
layout: default
title: Publishing updates
---
# Publishing updates

The public [psoerensen/gpct repository](https://github.com/psoerensen/gpct) is
connected to this checkout. The [Pages site](https://psoerensen.github.io/gpct/)
publishes from `main` and `/docs`. The initial local-only delivery was followed
by explicitly requested pushes and verified Pages deployments.

The Pages source is `docs/`, using GitHub's standard Jekyll branch publishing.
Its only YAML file is the standard Pages `_config.yml`; benchmark settings
remain ordinary R lists. No custom web application, dashboard or deployment
workflow is required.

For later updates, inspect staged/tracked files for individual data and push the
local main branch. From the repository root, after committing reviewed changes:

```text
git push origin main
```

Check `git remote -v` first. If the remote has acquired commits, fetch and inspect them before
integrating; do not force-push over existing content.

If setting up a separate copy, in **Settings → Pages → Build and deployment**, choose
**Deploy from a branch**, branch **main**, folder **/docs**, then save.
The current URL is [psoerensen.github.io/gpct](https://psoerensen.github.io/gpct/).
Check the Pages build/deployment and affected public links after each update.

If publishing under another owner or repository name, update `url` and `baseurl`
in `_config.yml` and hardcoded repository links in the Markdown first. Review
the Pages build status and visit all navigation links after the first deployment.
