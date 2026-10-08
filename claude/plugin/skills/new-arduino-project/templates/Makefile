# (c) Copyright {{YEAR}} Aaron Kimball
#
# {{DESCRIPTION}}

BOARD := {{BOARD_FQBN}}

# Set the name of the application to be compiled
prog_name := {{PROJECT_NAME}}

# Other libraries you depend on. If you depend on libfoo.a, write 'foo'.
# If a library 'foo' depends on another library 'bar', you must enumerate both
# (`libs := foo bar`).  Further, you *must* list foo /before/ bar, otherwise you will see
# errors in the link phase about missing symbols.
libs := {{LIBS}}

# List all directories of source files. (The .ino is intentionally empty and not compiled.)
src_dirs := src

# Surface compiler feedback immediately, so agents get it from make's exit status.
XFLAGS += -Wall -Wextra -Werror

# Set UPLOAD_PORT (e.g. /dev/ttyUSB0) in ~/.arduino_mk.conf or on the command line.

# Finally, include the main makefile library.
# This creates targets like 'all', 'install', 'upload', 'clean'...
include ../arduino-makefile/arduino.mk

# Use `make config` to inspect the build configuration.
# Use `make help` to see a list of available targets.

{{TEST_SECTION}}
##### Linting #####
# `make lint` reports problems without modifying anything; `make lint-fix` autofixes what it can.
MARKDOWNLINT := markdownlint-cli2
CLANG_FORMAT := clang-format
LINT_MD_GLOBS := "**/*.md"
LINT_SRC_FILES := $(shell git ls-files --cached --others --exclude-standard src | grep -E '\.(c|cpp|h)$$')

lint: lint-md lint-src{{LINT_TIDY_DEP}}

lint-fix: lint-md-fix lint-src-fix

lint-md:
	$(MARKDOWNLINT) $(LINT_MD_GLOBS)

lint-md-fix:
	$(MARKDOWNLINT) --fix $(LINT_MD_GLOBS)

lint-src:
	$(CLANG_FORMAT) --dry-run --Werror $(LINT_SRC_FILES)

lint-src-fix:
	$(CLANG_FORMAT) -i $(LINT_SRC_FILES)

.PHONY: lint lint-fix lint-md lint-md-fix lint-src lint-src-fix
{{TIDY_SECTION}}
