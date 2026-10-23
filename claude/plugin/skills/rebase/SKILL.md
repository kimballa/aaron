---
name: rebase
description: Fetch upstream Git changes and rebase the current feature branch onto its parent, including stacked PR branches. Resolve conflicts, verify the result, and update an existing remote feature branch with a normal push or an explicit force-with-lease when required. Use when the user asks to rebase or update a feature branch from its base.
---

# Rebase a feature branch

Complete the rebase and update an existing remote copy of the feature branch.
Invoking this skill authorizes fetching, rebasing, resolving conflicts, and pushing
the existing feature branch. Do not request a second confirmation for those steps
when the branch and base are clear. Follow repository instructions and preserve
uncommitted work and other people's commits.

## Establish the branch, parent, and push destination

1. Inspect the repository's instructions, working tree, current branch, remotes,
   tracking configuration, and any in-progress Git operation. Record the original
   branch name and HEAD for recovery. If HEAD is detached, the current branch is
   `main` or `master`, or a merge/rebase/cherry-pick is already in progress, stop
   and explain what needs to be resolved before starting this workflow.
2. Identify the branch's parent using, in order: an explicit base in the user's
   request, the current PR's base branch, or established stack metadata/configuration
   and repository conventions. For GitHub, `gh pr view --json baseRefName,headRefName,url`
   can provide the PR base; check that the PR corresponds to the current branch and
   repository. Resolve base branches against the correct remote, considering forks.
   Git does not record a universal parent-branch field. The branch's tracking
   upstream often identifies its own published copy, not its parent. Never infer a
   stack solely from names such as `stacked-pr-1` and `stacked-pr-2`.
3. Without explicit parent evidence, use the repository's remote default branch
   (usually `origin/main` or `origin/master`) when the history supports an ordinary
   feature branch. Inspect `refs/remotes/<remote>/HEAD`, repository hosting metadata,
   or `git ls-remote --symref <remote> HEAD` to identify the default rather than
   assuming `main`. If multiple plausible parents remain, or a stack is apparent
   but its parent is unknown, ask the user for the parent before rebasing.
4. Separately identify the existing remote copy of this feature branch. Inspect
   `branch.<branch>.remote`, `branch.<branch>.merge`, push remotes/refspecs, and
   hosting metadata. An existing same-name branch on the appropriate remote can
   be used even without local tracking configuration. Prefer `origin` when it is
   the appropriate remote; do not choose arbitrarily among conflicting remotes.
   A tracking target of `main` or `master` is a base, never a feature push target.
   Ask if the intended feature destination is ambiguous. If no published copy
   exists, finish locally without publishing a new remote branch.

## Fetch and preserve work

- Capture relevant remote-tracking tips before fetching, particularly the parent
  of a stacked branch: its old tip/reflog may be needed to identify child commits
  after the parent has been rewritten.
- Fetch the latest branch data from the base and feature remotes, pruning stale
  remote-tracking refs. Honor normal repository refspecs; if they exclude a needed
  branch, fetch that branch explicitly into its remote-tracking ref. Confirm the
  chosen parent and any published feature branch still exist after fetching.
  Do not silently substitute the default branch for a deleted stack parent.
- Record the fetched published feature tip as `expected_remote_oid` before any
  history rewrite. Preserve this exact value through the push; do not refresh it
  merely because a later fetch or push fails.
- Preserve staged, unstaged, and untracked changes before rebasing. If a stash is
  needed, use `git stash push --include-untracked` with a descriptive message,
  record its object ID, and restore that exact stash with `git stash apply --index`
  afterward. Do not use a blanket reset/clean or consume unrelated stashes. If
  untracked/ignored files or submodule changes cannot be preserved this way,
  handle them separately or stop before the rebase can overwrite them.
- Compare local and fetched feature history. Preserve remote work absent locally
  before rewriting. For ordinary divergence, rebase local-only commits onto the
  fetched feature tip first, then rebase the combined branch onto its parent.
  When either history was already rewritten, inspect patches with `git range-diff`
  and commit history to distinguish equivalent changes from new work. Ask only
  if ownership or the intended combined history cannot be determined safely.

## Rebase and resolve conflicts

- For an ordinary branch, rebase onto the fetched parent ref, such as
  `git rebase origin/main`. Preserve intentional merge topology with
  `--rebase-merges` when the branch requires it.
- For a stack whose parent history was rewritten, first establish the old child
  boundary from pre-fetch history, the parent's reflog/`--fork-point`, stack
  metadata, and commit inspection. Use
  `git rebase --onto <fetched-parent> <old-child-boundary> <current-branch>`
  to replay only the child's commits. A plain merge-base against the new parent
  can include the old parent's commits; do not replay those as child changes.
  Ask for the boundary if the available evidence cannot establish it.
- Resolve conflicts by reading both changes and the surrounding code, preserving
  the feature's intent and upstream behavior. During a rebase, `ours` refers to
  the new base and `theirs` to the commit being replayed; do not select either
  side wholesale without understanding the changes. Use the repository's normal
  generators for generated files and lockfiles where appropriate.
- Stage only resolved files and continue until the rebase finishes. Skip a commit
  only after confirming its changes already exist or it has become genuinely
  empty. Do not discard substantive work just to complete the rebase. When a
  resolution needs a product decision or lacks enough evidence, ask a focused
  question and preserve the recoverable operation state.

## Verify, restore local changes, and push

1. Inspect the final history and diff against the parent, check for unresolved
   conflicts and whitespace errors, and run checks appropriate to the changed
   code. Use `git range-diff` against the recorded old feature range where useful
   to catch lost or accidentally replayed changes. Confirm the current branch is
   still the original feature branch. Fix validation failures caused by the rebase
   before pushing; report pre-existing failures and checks that could not run.
2. Restore any saved local changes and their staged state. If stash application
   conflicts, resolve them while preserving the original local edits; retain the
   stash until restoration is verified. Do not push while restoration conflicts
   remain. Drop only the stash created by this run, once verified, identifying
   its current stash entry by object ID rather than assuming it is `stash@{0}`.
   Do not commit the user's unrelated local edits.
3. If an existing published feature branch was identified, recheck the exact
   destination ref. **Never force-push `refs/heads/main` or `refs/heads/master`,
   regardless of the local branch name, remote name, or tracking configuration.**
   Do not push to either of those destinations in this feature-branch workflow.
   Respect any additional protected branches and repository restrictions.
4. Push only the original feature branch to the explicit remote feature ref.
   If the recorded remote tip is an ancestor of the new HEAD, a normal push is
   sufficient:

   ```bash
   git push <remote> HEAD:refs/heads/<feature-destination>
   ```

   Otherwise use an explicit lease tied to the tip recorded after fetching:

   ```bash
   git push --force-with-lease=refs/heads/<feature-destination>:<expected_remote_oid> <remote> HEAD:refs/heads/<feature-destination>
   ```

   Do not use bare `--force`, `+` refspecs, `--mirror`, or `--all`. Do not rely on
   a default push destination or a lease based on a moving remote-tracking ref.
   If a push is rejected, inspect the reason. On a lease rejection, fetch and
   compare the newly published work, integrate it, and revalidate before a new
   attempt with a newly recorded tip. Stop and ask if the intended integration
   is unclear; never just renew the lease and overwrite the remote changes.
5. Verify the remote feature ref matches the pushed HEAD, for example with
   `git ls-remote <remote> refs/heads/<feature-destination>`, and inspect final
   local status. Report the base, conflicts resolved, validation, whether the
   remote was updated, and any preserved local changes or remaining blockers.
