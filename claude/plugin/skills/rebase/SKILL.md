---
name: rebase
description: Fetch upstream Git changes and rebase the current feature branch onto its parent, including stacked PR branches. Branches in a GitHub stack are rebased and pushed with `gh stack` so PR approvals are not needlessly dismissed. Resolve conflicts, verify the result, and update an existing remote feature branch with a normal push or an explicit force-with-lease when required. Use when the user asks to rebase or update a feature branch from its base.
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
   but its parent is unknown, ask the user for the parent before rebasing. A branch
   in a GitHub stack (next section) has a known parent; do not ask.
4. Separately identify the existing remote copy of this feature branch. Inspect
   `branch.<branch>.remote`, `branch.<branch>.merge`, push remotes/refspecs, and
   hosting metadata. An existing same-name branch on the appropriate remote can
   be used even without local tracking configuration. Prefer `origin` when it is
   the appropriate remote; do not choose arbitrarily among conflicting remotes.
   A tracking target of `main` or `master` is a base, never a feature push target.
   Ask if the intended feature destination is ambiguous. If no published copy
   exists, finish locally without publishing a new remote branch.

## GitHub stacks: use `gh stack`

Rebasing a stacked PR branch by hand and pushing it makes GitHub treat every
rewritten branch as a plain force-push, which dismisses approvals on repositories
that dismiss stale reviews. `gh stack push` marks its force-pushes as belonging to a
stack so GitHub can keep approvals when a rebase leaves a PR's diff unchanged. That
needs a recent `gh-stack` (the marker was merged after v0.2.1; check
`gh extension list` and run `gh extension upgrade stack` if the user agrees). So for
a branch in a stack, do the rebase and the push with `gh stack`, not raw `git`.

`gh stack` rebases locally: there is no server-side rebase through the CLI or API.
The only server-side rebase is the "Rebase stack" button in the PR merge box, which
cannot resolve conflicts. Do not try to emulate it.

1. Check that the extension exists with `gh stack --help`. If it does not, fall back
   to the ordinary workflow in this skill and say that stack-aware rebasing and
   approval preservation were unavailable.
2. Detect the stack. Stack metadata is local (`.git/gh-stack`), and the active
   stack is the one containing the checked-out branch.
   `gh stack view --json` exits 0 inside a stack, 2 outside one, and 6 when the
   branch belongs to several stacks (ask the user which). If it exits 2, also look
   for a stack that exists on GitHub but is not tracked locally: with the current
   branch's PR number `N`, `gh api "repos/{owner}/{repo}/stacks?pull_request=N"`
   returns it. If one exists, run `gh stack checkout N` to set it up locally and
   re-run `gh stack view --json`; stop and ask if that prompts or fails. If there is
   no stack either way, use the ordinary workflow in this skill.
3. Do the "Fetch and preserve work" steps below for every branch in the stack, not
   just the current one: record each branch's fetched remote tip, preserve local
   changes, and integrate remote-only commits before rebasing. `gh stack rebase`
   only fast-forwards local branches that are behind their remote copy, and it
   rebases or switches worktrees only when the owning worktree is clean. It never
   stashes.
4. If a branch's remote copy was already rebased on GitHub (its fetched tip already
   contains the new parent tip and `git range-diff` shows the same patches as the
   local branch, with no unpushed local commits), do not rebase it again. Move the
   local branch to the fetched tip, then skip to verification.
5. Run `gh stack rebase` with no scope flags. It fetches `origin`, then rebases each
   branch onto the tip of the layer below, trunk first. A branch whose PR already
   merged is replayed with `--onto` automatically, so the manual boundary search in
   the next section does not apply. Rebase the whole stack: `--downstack` or
   `--upstack` alone leaves some branches not based on their parent, and GitHub will
   not merge a stack that is not linear. Use `--remote <name>` if `origin` is not
   the stack's remote. It does not push.
6. On a conflict the command exits 3 and lists the files. Resolve them as described
   below, `git add` only the resolved files, and run `gh stack rebase --continue`;
   do not repeat start-only flags. `gh stack rebase --abort` restores every branch
   to its pre-rebase state. Exit 7 means a rebase is already running.
7. Verify as described under "Verify, restore local changes, and push". Also confirm
   that `gh stack view --json` reports no branch with `needsRebase: true`.
8. Push with `gh stack push`, not `git push`. It pushes every active branch in one
   command with a per-branch `--force-with-lease` and skips merged and queued
   branches. The push is not atomic: if one branch is rejected, the others may have
   updated. A lease rejection means someone published new work to that branch;
   handle it as described in the push section, then re-run `gh stack push`. Never
   fall back to `git push --force` to get past it.
9. Verify that every branch's remote ref matches its local tip, and report the
   stack's branches, conflicts resolved, validation, and the pushed result. Say that
   GitHub's approval retention depends on repository settings and the extension
   version, and do not claim approvals survived unless the PRs show them.

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
- For a stack that `gh stack` does not manage and whose parent history was rewritten, first establish the old child
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
