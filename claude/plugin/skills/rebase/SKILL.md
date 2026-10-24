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
   changes, and integrate remote-only commits before rebasing. Keep each branch's
   pre-fetch remote tip (`P_i` below). `gh stack rebase` only fast-forwards local
   branches that are strictly behind their remote copy, and it updates the worktree
   that owns each branch only when that worktree is clean; it never stashes. Other
   agents may be working in other worktrees, so never stash, reset, or switch a
   worktree this run does not own: list them with `git worktree list` and report
   the path of any that blocks the rebase.
4. Check whether the stack was already rebased, by this clone's other worktrees,
   another clone, or GitHub's "Rebase stack" button, and realign instead of
   rebasing again. `gh stack` does not do this for you: `gh stack rebase` has no
   "already up to date" shortcut, it silently skips branches that have diverged
   from their remote copy, and it rebases the rest again. `gh stack push` would
   then force a second, differently-hashed copy of already-published work over the
   first, which is what dismisses approvals. So decide with git first. Fetch the
   trunk and every stack branch (names from `gh stack view --json`), and let `T` be
   `<remote>/<trunk>`, `L_i` and `R_i` the local and fetched remote tips of the
   i-th branch from the bottom. Test linearity with
   `git merge-base --is-ancestor <parent> <child>`:
   - **Local stack already linear** (`T` is an ancestor of `L_1`, and each `L_{i-1}`
     is an ancestor of `L_i`): another worktree of this clone did the rebase. Branch
     refs are shared by all worktrees and `gh stack` moved the working copy of each
     clean owning worktree, so there is nothing to realign. Skip to step 7.
   - **Remote stack already linear but local is not** (same test on the `R_i`): realign
     each branch whose `L_i` differs from `R_i` and is not an ancestor of `R_i`
     (an ancestor is a plain fast-forward). Check `git cherry <remote>/<b> <b>`.
     With no `+` lines, there is no unpublished local work: for the current branch
     run `git reset --hard <remote>/<b>` (after preserving local changes as above),
     and for a branch no worktree has checked out run `git branch -f <b> <remote>/<b>`
     (Git refuses this for a checked-out branch, which belongs to that worktree's
     owner: leave it and report it). With `+` lines there are unpublished local
     commits, or copies of published ones whose conflict resolution changed their
     patch IDs; compare with `git range-diff`, then replay only the unique commits
     with `git rebase --onto <remote>/<b> P_i <b>` when `P_i` is an ancestor of
     `L_i`. If it is not, both sides rewrote the branch: ask. Then skip to step 7.
   - **Remote only partly rebased, or neither side linear:** if the remote is only
     partly rebased, stop and ask; otherwise continue with step 5.
5. Run `gh stack rebase` with no scope flags. It fetches `origin`, then rebases each
   branch onto the tip of the layer below, trunk first. A branch whose PR already
   merged is replayed with `--onto` automatically, so the manual boundary search in
   the next section does not apply. Rebase the whole stack: `--downstack` or
   `--upstack` alone leaves some branches not based on their parent, and GitHub will
   not merge a stack that is not linear. Use `--remote <name>` if `origin` is not
   the stack's remote. It does not push. If it refuses because another worktree
   that owns a stack branch is dirty or busy, do not touch that worktree: confirm
   with `gh stack view --json` and `git worktree list` that nothing changed (run
   `gh stack rebase --abort` if a rebase was left pending), report the path, and
   stop.
6. On a conflict the command exits 3 and lists the files. Resolve them as described
   below, `git add` only the resolved files, and run `gh stack rebase --continue`;
   do not repeat start-only flags. `gh stack rebase --abort` restores every branch
   to its pre-rebase state. Exit 7 means a rebase is already running.
7. Verify as described under "Verify, restore local changes, and push". Also confirm
   that `gh stack view --json` reports no branch with `needsRebase: true`.
8. Push with `gh stack push`, not `git push`. It pushes every active branch in one
   command with a per-branch `--force-with-lease` and skips merged and queued
   branches. Because it pushes every branch, first confirm that each local tip is
   equal to, a descendant of, or a branch this run just rebased from its fetched
   remote tip. A branch that has diverged with its own commits, for example in
   another agent's worktree, would be force-pushed over the remote copy; its lease
   is taken after a fetch, so do not rely on the lease to catch it. If any branch
   fails the check, do not run `gh stack push`: report it and ask. The push is not atomic: if one branch is rejected, the others may have
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
