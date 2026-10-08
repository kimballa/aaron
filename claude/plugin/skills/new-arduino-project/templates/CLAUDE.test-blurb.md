
## Host-based unit testing

The host-clean subset of `src/` (listed in `SUT_SRCS` in the `Makefile`) is compiled with ordinary
`g++` against a mock Arduino environment in `test/arduino-mock-env/` (it shadows `<Arduino.h>` etc.
via `-isystem`) and tested with [doctest](https://github.com/doctest/doctest).

* `make compile-test` — fast `-fsyntax-only` check. `make test` — build and run the suite.
* Tests live in `test/<module>_test.cpp`; the Makefile picks up `test/*_test.cpp` via wildcard.
  Each `TEST_CASE` should call `mock::reset()` first.
* Hardware-only code (ISR attributes, port registers, inline asm) is gated behind
  `#ifdef <MCU macro>` with a host stub in the `#else` branch.
* **Default to host-testable.** When you create a new source file, assume it should be
  host-testable unless something it depends on cannot reasonably be mocked: add it to `SUT_SRCS`
  and write `test/<module>_test.cpp` in the same task. Say why in your summary if you leave it out.

### SDLC loop

A task is complete only when each of these passes (each as its own bash call):

1. `make clean test` — no failures, no host compiler warnings.
2. `make lint`.
3. `make clean image` — no warnings from anything under `src/`.
