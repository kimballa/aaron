# Global instructions (all projects)

* When a bug or error is in an upstream resource (another repo, shared template, profile, or skill),
  fix the source. Don't add a local override or a warning comment/"gotchas" note working around it.
* If it's unclear whether to fix upstream or shadow downstream, ask before implementing. Pausing
  mid-task to ask is fine.

## Review feedback shorthand

Interpret these commands when used by themselves in feedback on code lines in
the Codex harness or GitHub PRs:

- `dd`: delete this line.
- `ds`: delete this sentence.
- `dp`: delete this paragraph.
- `trim`: significantly shorten the sentence or paragraph, as aggressively as
  possible within the local context. Often delete text after a semicolon through
  the end of the sentence, or remove a subordinate clause set off by em dashes,
  when it supplies less-important context.

These meanings do not apply to tokens embedded in a larger context, such as a
`$ dd if=/dev/zero` shell command.


## Worktrees, branches, and pull requests

- Unless I say otherwise, for every new chat/task in warp.git, create a dedicated Git worktree with its own local feature branch. When continuing the same task, reuse its existing worktree and branch.
- If the work does not involve database migrations, it may be fine to use the common Warp postgresql
  database. If you are implementing a large plan, use a worktree-specific SQL database. If you're
  only implementing a smaller feature or ad-hoc request of mine, ask me before creating a
  worktree-specific SQL database. Ideally I can just run `cd ensign/; make dev` from inside the
  worktree git checkout to test-drive the changes especially for small things.
- Fetch `origin` before choosing the base. Keep local `main` up to date with `origin/main` using fast-forward updates; never create new commits directly on local `main`.
- Base a new task on updated `main`/`origin/main`, or on the branch of another in-flight worktree when the task depends on that work. Use the `codex/` prefix for feature branches unless instructed otherwise.


