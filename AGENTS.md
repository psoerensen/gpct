# AGENTS.md

## Git workflow

Use the primary checkout on `main` unless the user explicitly asks otherwise.
Do not create or switch branches or worktrees, including temporary ones,
without explicit user approval. If the checkout is unexpectedly on another
branch, report its actual name and preserve all edits before resolving it
with the user.

Before changing Git state, check the checkout path, branch and uncommitted
edits. Preserve existing edits. Commit and push only when the user explicitly
requests those actions.

After Git operations, report the actual branch name, whether uncommitted
changes remain, and whether the branch is synchronized with GitHub. Do not
use vague wording such as "your current branch" without naming it. Distinguish
local commits from changes that have been pushed.
