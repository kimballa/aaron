---
name: new-arduino-project
description: Scaffold a new Arduino sketch project in ~/src/arduino using Aaron's conventions — Makefile built on ../arduino-makefile/arduino.mk, VS Code config (clangd/cpptools IntelliSense, clang-format on save), .clang-format, markdownlint, optional clang-tidy and host-side doctest unit tests, CLAUDE.md and .claude/settings.json. Use when the user wants to create/start/bootstrap a new Arduino, Teensy, ATtiny, or other microcontroller firmware project, or add this tooling to an existing one.
---

# New Arduino project

Scaffold a project that matches Aaron's existing ones. Reference implementations (read them if a
template leaves a question open):

* `~/src/arduino/encoder-counter` — bare-bones: ATtiny1614, `src/`, `-Wall -Wextra -Werror`,
  markdownlint + clang-format lint, no tests.
* `~/src/arduino/hifi-receiver` — rich: Teensy 4.1, host unit tests with a mock Arduino env,
  clang-tidy, `docs/` specs and ADRs, generated assets, `cloud-setup.sh`.
* `~/src/arduino/arduino-makefile` — the shared build system (`arduino.mk`, `Makefile.template`,
  `profiles/`). Board support is selected via `profiles/profile_index.txt` (fqbn →
  profile). If the target board isn't listed there, say so and ask before adding a profile.

Templates are in `templates/` next to this file (`${CLAUDE_SKILL_DIR}/templates` or the directory
containing this SKILL.md). Files with `{{PLACEHOLDER}}` markers need filling in; the rest
(`clang-format`, `clang-tidy`, `markdownlint-cli2.jsonc`, `gitignore`, `vscode/extensions.json`,
`test/*`) are copied verbatim.

## 1. Gather inputs

Ask (only for what you can't infer; use sensible defaults and state them):

* **Project name** (kebab-case, becomes the dir `~/src/arduino/<name>/`, `prog_name`, and the
  `.ino` name) and a one-line description.
* **Board fqbn** (e.g. `teensy:avr:teensy41`, `megaTinyCore:megaavr:atxy4:chip=1614,clock=10internal`,
  `arduino:avr:uno`). Check it is covered by `profile_index.txt`.
* **Libraries** (`libs :=`; order matters — dependents before dependencies; see the
  arduino-makefile README). Sibling libs live in `~/src/arduino/*` and are installed with
  `make install` in their dir.
* **Tier**: *bare-bones* (default) or *rich* = bare-bones + host unit tests + clang-tidy. Only go
  rich if the user asks, or the project has real logic worth host-testing.

## 2. Create the project

Directory: `~/src/arduino/<name>/` (must be a sibling of `arduino-makefile`, because the Makefile
does `include ../arduino-makefile/arduino.mk`). Then `git init` it. Do not commit unless asked.

| Template | Destination | Notes |
| --- | --- | --- |
| `Makefile` | `Makefile` | Fill `{{YEAR}}`, `{{DESCRIPTION}}`, `{{BOARD_FQBN}}`, `{{PROJECT_NAME}}`, `{{LIBS}}`. Replace `{{TEST_SECTION}}`, `{{LINT_TIDY_DEP}}`, `{{TIDY_SECTION}}` — see below. |
| `sketch.ino` | `<name>.ino` | Intentionally empty stub that includes `src/sketch.h`; real code is in `src/`. |
| `src/sketch.h`, `src/main.cpp` | same | Minimal `setup()`/`loop()`. |
| `clang-format` | `.clang-format` | Verbatim. |
| `markdownlint-cli2.jsonc` | `.markdownlint-cli2.jsonc` | Verbatim. |
| `gitignore` | `.gitignore` | Verbatim; append generated files if any. |
| `vscode/*` | `.vscode/` | See "VS Code" below. |
| `claude/settings.json` | `.claude/settings.json` | Fill `{{CORE_PACKAGE}}` (e.g. `megaTinyCore`, `teensy`). |
| `CLAUDE.md` | `CLAUDE.md` | See "CLAUDE.md" below. |
| `README.md` | `README.md` | Fill in; flesh out with pinout/behavior spec as the project develops. |

Tidy/test tiers:

* **Bare-bones**: `{{TEST_SECTION}}` → empty, `{{LINT_TIDY_DEP}}` → empty, `{{TIDY_SECTION}}` →
  empty. Lint target is `lint: lint-md lint-src`.
* **Rich**: `{{TEST_SECTION}}` → contents of `Makefile.test-section.mk` (fill `{{CPP_STD}}` with
  `-std` value matching the firmware's `CXX_STD`, e.g. `gnu++17` for AVR, `gnu++20` for Teensy),
  `{{LINT_TIDY_DEP}}` → ` lint-tidy`, `{{TIDY_SECTION}}` → `Makefile.tidy-section.mk`. Also:
  * copy `clang-tidy` → `.clang-tidy`;
  * copy `templates/test/test_main.cpp`, `sanity_test.cpp` and `doctest.h` into `test/`. **Do not
    read `doctest.h`** (it is the huge vendored single-header doctest); just `cp` it into place;
  * create `test/arduino-mock-env/` by copying `Arduino.{h,cpp}`, `mock-control.{h,cpp}`, and
    (as needed) `Wire.*`, `SPI.*`, `HardwareSerial.*`, `Print.*` from
    `~/src/arduino/hifi-receiver/test/arduino-mock-env/`, then **strip the Teensy-specific bits**
    (IMXRT/DMA mocks, `LPSPI`) unless the new board needs them. The mock must not define the
    target-MCU macro (e.g. `__IMXRT1062__`, `__AVR_ATtiny1614__`) so production `#ifdef` gates take
    their host branch;
  * in `CLAUDE.md`, `{{TEST_BLURB}}` → contents of `CLAUDE.test-blurb.md`, `{{TIDY_BLURB}}` →
    `, and clang-tidy (host-testable subset)`; in `README.md`, `{{README_TIDY}}` → `, clang-tidy`,
    `{{README_TEST}}` → a bullet for `make test`. Bare-bones: all of those → empty.
  * Offer `~/src/arduino/hifi-receiver/tools/cloud-setup.sh` as a model if the user wants Claude
    cloud-environment support; don't add it unprompted.

## 3. VS Code config

`vscode/settings.json`: fill `{{COMPILER_PATH}}` (the target's cross-compiler under
`${env:HOME}/.arduino15/packages/...` — use `${env:HOME}` rather than a literal home dir in
`c_cpp_properties.json`), `{{CPP_STD}}` (matches the Makefile: `gnu++17` AVR, `gnu++20` Teensy),
`{{INTELLISENSE_MODE}}` (`linux-gcc-x64` for avr-gcc, `linux-gcc-arm` for ARM). Add
`files.associations` entries for core headers the editor mis-detects as C (hifi-receiver shows
examples) only if needed.

`vscode/c_cpp_properties.json`: don't guess include paths and defines — derive them from the real
build. Run `make config` and/or `make -n image` (or look in `build/` after `make image`) and
transcribe the core/variant/libraries `-I`/`-isystem` dirs into `includePath`, and the `-D` flags
(MCU macro, `F_CPU`, `ARDUINO*`, board-specific) into `defines`. Keep `"${workspaceFolder}/**"`
first, and the compiler's own `include` dir for AVR. Reference examples:
`~/src/arduino/encoder-counter/.vscode/c_cpp_properties.json` (AVR) and
`~/src/arduino/hifi-receiver/.vscode/c_cpp_properties.json` (ARM). `{{BOARD_SHORT_NAME}}` is a
short label like `attiny1614`. `{{C_STD}}`: `gnu11` (AVR) / `c17` (ARM). `.vscode/extensions.json` is
verbatim (makefile-tools, cpptools, clang-format).

## 4. CLAUDE.md

Fill `{{PROJECT_TITLE}}`, `{{DESCRIPTION}}`, `{{MCU_DESCRIPTION}}`, `{{TOOLCHAIN_DESCRIPTION}}`
(e.g. "megaTinyCore, tinyAVR 1-series; avr-gcc 7.3, `gnu++17`"), `{{PROFILE_NAME}}` (e.g.
`profiles/megatinycore.mk`) and `{{CONSTRAINTS}}`: the hardware limits that matter — flash/RAM
sizes and the no-heap/no-`String` rule on small MCUs; ISR rules (shared state `volatile`, no
`attachInterrupt()` if the project defines vectors directly); which peripherals are driven directly
vs. via libraries. For a big-RAM board (Teensy) the constraints can be short. Delete the
Style/Build bullets that don't apply; keep the "Important Rules for using tools and bash shell
commands" section verbatim — it's what lets agents run autonomously with the pre-approved
`.claude/settings.json` commands.

## 5. Verify

Run these (each as a separate command) in the new dir and fix problems:

1. `make config` — profile resolved, paths exist.
2. `make clean image` — builds with `-Wall -Wextra -Werror`, exit 0.
3. `make lint` — passes (run `make lint-fix` first if formatting is off; requires `clang-format`
   and `markdownlint-cli2` on PATH — report if missing rather than installing silently).
4. Rich tier: `make clean test`.

If `~/.arduino_mk.conf` is missing, point at `arduino-makefile/arduino_mk_conf.template`. Finish by
summarizing what was created, the tier chosen, and anything left as a TODO (e.g. unfilled
constraints, missing tools). Do not commit.
