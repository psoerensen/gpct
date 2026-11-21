---
layout: default
title: Publishing later
---
# Publishing later

Per the latest instruction, this scaffold is local. Content has not been pushed,
and GitHub Pages has not been enabled. An empty public
[psoerensen/gpct repository](https://github.com/psoerensen/gpct) was created before
that instruction arrived; it has received no scaffold content from this task.

The Pages source is `docs/`, using GitHub's standard Jekyll branch publishing.
Its only YAML file is the standard Pages `_config.yml`; benchmark settings
remain ordinary R lists. No custom web application, dashboard or deployment
workflow is required.

When ready, inspect local staged/tracked files for individual data and push the
local main branch to the intended repository. Example commands from repo root:

```text
git remote add origin https://github.com/psoerensen/gpct.git
git push -u origin main
```

Check `git remote -v` first and skip `remote add` if an appropriate origin already
exists. If the remote has acquired commits, fetch and inspect them before
integrating; do not force-push over existing content.

In GitHub repository **Settings → Pages → Build and deployment**, choose
**Deploy from a branch**, branch **main**, folder **/docs**, then save.
The intended URL is [psoerensen.github.io/gpct](https://psoerensen.github.io/gpct/).
It is not a verified live site for this local delivery.

If publishing under another owner or repository name, update `url` and `baseurl`
in `_config.yml` and hardcoded repository links in the Markdown first. Review
the Pages build status and visit all navigation links after the first deployment.
