---
name: prune-worktrees
description: Remove stale local Git worktrees belonging to archived Codex chats and their disposable local branches, with named worktree and branch retention options. Use for archived-chat worktree cleanup or local worktree pruning.
---

# Prune worktrees

Clean up local checkouts for archived chats while preserving work the user wants to revisit. A cleanup request authorizes removal of confirmed stale, clean worktrees and disposable local branches; do not add a blanket confirmation step.

## Retention choices

Accept two independent named sets in the user's request:

- **Keep worktrees:** Preserve each named checkout and its branch, even if its chat is archived or its PR merged.
- **Keep branches only:** Preserve each named local branch while removing its eligible archived-chat checkout. Committed work remains available for a later `git worktree add`.

Resolve names against the inventory: accept absolute checkout paths, unambiguous worktree directory names, and exact local branch names. A worktree retention wins over branch-only retention. Clarify ambiguous or missing names before deleting anything they might designate. Apply the sets across the entire cleanup, including branch-only cleanup. Do not assume an earlier chat's keep list persists unless it is available in the current instructions or the user supplies a saved list.

Examples:

- `$prune-worktrees keep worktrees ui-tweaks; keep branches only codex/experiment`
- `$prune-worktrees dry run` — report proposed actions without removing anything.

If no retention names were supplied, ask once early whether the user has exceptions, and continue inventorying. Allow a reasonable opportunity to answer before removing eligible merged work. Silence never authorizes discarding unique work.

## Establish scope and ownership

1. Inventory with `git worktree list --porcelain` for the requested repository. In Aaron's usual setup, inspect `~/src/warp` and `~/.codex/worktrees/`; discover other repositories there without assuming all belong to Warp. `.git/worktrees/` contains Git administrative records, not checkout directories. Never delete those records directly. Do not create a temporary worktree solely to perform cleanup unless applicable repository instructions require one.
2. Discover the Codex app's `list_threads` and `list_archived_threads` tools. List active and archived history separately and consume every page. Keep primary checkouts, the current checkout, active-chat worktrees, locked worktrees, explicit retention entries, and checkouts with uncertain ownership.
3. Match worktrees to chats using exact paths, attachments, and creation or subsequent working-directory commands from `read_thread` where available. A title resemblance or a path mentioned as background is insufficient. Sessions often record the primary checkout as `cwd` even after creating another worktree. Follow a moved checkout or reused branch through its later owning chats; verify all actual owners are archived. A read-only inspection by an active chat does not itself establish ownership.
4. If app tools omit the necessary mapping, inspect local Codex metadata and rollout files read-only. Discover the current state database and schema rather than hard-coding a version. Use SQLite `mode=ro`; never update app state. Rollouts can store commands in `custom_tool_call.input` as well as `function_call.arguments`, including nested `functions.exec` calls. Root user chats establish lifecycle; guardian reviews and internal subagents are not independent owners. If a local database's rollout path is missing, locate the exact session ID under the local session/archive directories. Keep unresolved cases.

## Assess each checkout and branch

Fetch the repository's relevant remote refs before merge assessment. Respect its instructions for fast-forwarding the primary branch. Record checkout path, branch, HEAD, owning chat IDs and archive status, dirty state, and the proposed action with its reason.

- Inspect staged, unstaged, and non-ignored untracked files. Inspect ignored files for unique user data, credentials, local databases, or artifacts; dependency and build caches are disposable. Preserve dirty worktrees or unique ignored data unless the user explicitly authorizes their disposition. For ignored files, a verified backup outside the removed checkout can preserve the data while allowing cleanup; report its location and restrict permissions when it contains credentials. A branch retains commits only, not uncommitted or ignored files.
- Check for running processes using a candidate checkout, initialized submodules, nested repositories, and worktree locks. Preserve affected checkouts until their use or contents are resolved; do not kill processes or force removal implicitly.
- Delete a local branch only when it belongs to the stale work and has no retained checkout or other ongoing purpose. Check branches whose old checkout is already gone when ownership evidence establishes the same scope. Protect primary and unrelated branches; never delete remote branches or change PR state.
- Prove that commits are preserved in the intended integration branch using ancestry. For squash/rebase merges, check the exact repository PR and its merged state, destination, and head commit. Confirm that the destination was integrated into the intended mainline; a PR merged into another feature branch is insufficient. A merged PR whose recorded head differs from the local tip does not prove later local commits disposable. Being pushed, having a deleted upstream, or an archived chat alone is not merge proof.
- For a clean archived-chat checkout with unmerged commits, retain its local branch by default and remove only the checkout if no other preservation concern applies. Preserve detached HEAD commits with a named branch before removing their sole checkout. Ask before discarding unique commits. Honor explicit keep-branch choices even for merged work.

## Remove and verify

Summarize the concrete removal and retention decisions before applying them. Resolve any unique-work decisions first; proceed with independently safe entries under the existing cleanup authorization.

Recheck archive status, HEAD, branch, retention sets, and dirty state immediately before each removal. Use `git worktree remove <exact-path>` from a retained checkout. Do not use recursive filesystem deletion or a force flag to bypass an unexpected refusal. Prefer the app's `archive_worktree` for managed worktrees when the tool supports the target chat and attachment; it is scoped to the calling chat, so do not pass an unrelated chat's worktree to it.

Delete only the associated disposable local branches after successful removal. Prefer `git branch -d`; for a proven squash/rebase merge, `git branch -D` is appropriate after checking the branch still points at the reviewed commit and no remaining checkout uses it. Retain a log of branch names, tip SHAs, owning chats, merge evidence, and outcomes outside removed checkouts.

Use `git worktree prune --dry-run` to review stale registrations; prune only reviewed records. Empty parent folders under the selected worktree root can be removed with `rmdir` after confirming the checkout is gone. Leave nonempty orphan folders for inspection. Never alter conversation archives or delete unrelated databases, containers, volumes, or app caches as part of this skill.

Finish by re-listing worktrees and local branches, verifying retained entries, and reporting counts removed plus any retained or unresolved work and its reason. Give the location of the cleanup log and the names of branches retained for later revisiting.
