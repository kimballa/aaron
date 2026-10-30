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
