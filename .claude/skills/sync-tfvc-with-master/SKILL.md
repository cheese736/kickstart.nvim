---
name: sync-tfvc-with-master
description: Commit the working-tree changes on master, then rebase with_tfvc onto the updated master. Use when the user asks to "commit master's changes and rebase with_tfvc", "sync with_tfvc with master", or similar in this nvim config repo.
---

# Sync with_tfvc with master

This repo keeps `with_tfvc` as `master` plus one extra commit (`add tfvc`,
the TFVC integration files). Whenever new work lands on `master`,
`with_tfvc` needs to be rebased on top so it stays a clean single-commit
diff from `master`.

## Steps

### 1. Check state before touching anything

```bash
git status
git branch -vv
```

- If there are uncommitted changes but the current branch is **not**
  `master`, stop and ask the user — don't silently switch branches with
  dirty state.
- If `master` has no uncommitted changes and nothing to commit, skip step 2.

### 2. Commit on master

```bash
git checkout master   # only if not already there
git add <specific files>   # never `git add -A`/`.` blindly — review `git status` first
git commit -m "<concise, imperative summary>"
```

Write the message in this repo's existing style (see `git log --oneline -5`
for tone/format). Don't invent scope beyond what's actually in the diff.

### 3. Rebase with_tfvc onto master

```bash
git checkout with_tfvc
git rebase master
```

- If the rebase hits conflicts, stop and resolve them with the user rather
  than force-resolving blindly (`add tfvc` touches TFVC-specific files that
  are easy to get wrong).
- After a clean rebase, `with_tfvc` and `origin/with_tfvc` will have
  diverged (local history was rewritten). That's expected — do **not**
  force-push automatically. Only push if the user explicitly asks, and use
  `git push --force-with-lease` (never plain `--force`).

### 4. Report

Show `git log --oneline -5` for `with_tfvc` and `git status` so the user can
see the new commit on master and the rebased tip, and mention explicitly
that the remote `with_tfvc` still needs a force-push if they want it synced.
