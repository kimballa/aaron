# {{PROJECT_TITLE}}

{{DESCRIPTION}} An Arduino sketch for {{MCU_DESCRIPTION}} ({{TOOLCHAIN_DESCRIPTION}}).
`README.md` is the spec for the externally visible behavior; keep it up-to-date when behavior
changes.

All C++ source code goes in the `src/` subdirectory. The `.ino` at the top level is intentionally
empty. Compilation units that just have functions/methods have their signatures declared in
`src/sketch.h` or in their own header (`foo.h` for `foo.cpp`).

## Constraints

{{CONSTRAINTS}}

## Style notes

* The first line of every file should be `// (c) Copyright <CURYEAR> Aaron Kimball`.
  If the file was already created in an older year, it will have an older year in the
  header. Do not update it.
* Use #ifndef / #define / #endif guards so that each header file can only be included once.
* Prefer object references over object pointers, if possible. Statically allocate.
* We do not catch or throw exceptions. Use return values or OUT by-reference arguments for error
  signalling.
* Prefer const references/pointers if possible, and declare class methods as `const` when you can.
* Use lowerCamelCase for variables and functions. Constants are `UPPER_SNAKE_CASE` (pin numbers are
  lowerCamel like `pinIntL`).
* Private variables in a class get an `_underscore` prefix.
* Don't hardcode magic constants. Use `constexpr` to define symbolic names for things like GPIO pin
  numbers.
* Prefer explicitly-sized types like `uint8_t` or `int32_t` instead of implicitly-sized types like
  `int` or `long`.
* Each cpp file should include the specific headers it needs rather than glomp everything up
  into `sketch.h`.
* Libraries / modules should use C++ namespaces so internal constexprs / fns defined in the .h file
  don't pollute the global namespace. File-local helpers go in an anonymous namespace.

## Build

This project is built with the `Makefile`, which uses `../arduino-makefile/arduino.mk` and its
`{{PROFILE_NAME}}` profile. Use `make image` to compile. Use `make clean image` if any `.h` files
were modified. The sources compile with `-Wall -Wextra -Werror`, so the exit status of `make` tells
you whether any warnings or errors were emitted. You must successfully build with
`make clean image` before any development task is complete.

`make lint` checks Markdown (`markdownlint-cli2`) and C++ formatting (`clang-format`){{TIDY_BLURB}};
`make lint-fix` fixes what it can (it does not fix clang-tidy findings). Both must pass before a
task is complete. When `make lint` reports something, run `make lint-fix` first rather than
reformatting by hand.
{{TEST_BLURB}}
## Important Rules for using tools and bash shell commands

* You should be able to operate autonomously using the pre-approved commands in
  `.claude/settings.json`.
* If you use compound commands (`command1; command2` or `command1 && command2`), this
  will void prior approval. Do not do this. Run each command in a separate bash call.
* Do not pipe the output of one command directly to another. Redirect the output into a temp
  file and then read it with a separate command.
* Do not redirect stderr to stdout with `2>&1`. You can read both output streams.
* Do not follow a command with `echo "$?"`; the tool harness reports failures.
* Do not use subshells with `$(...)` or backticks. Run the would-be subshell command first and
  save its output to a file.
