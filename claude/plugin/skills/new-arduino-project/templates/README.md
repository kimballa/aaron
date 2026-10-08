# {{PROJECT_NAME}}

{{DESCRIPTION}}

## Building

Requires `arduino-cli`, the `{{CORE_PACKAGE}}` core, and `../arduino-makefile` (a sibling checkout).
See that repo's README for `~/.arduino_mk.conf`.

* `make image` — compile. `make upload` — flash. `make help` — all targets.
* `make lint` / `make lint-fix` — markdownlint + clang-format{{README_TIDY}}.
{{README_TEST}}
