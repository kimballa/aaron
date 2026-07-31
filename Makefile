SHELL := /bin/bash

# Scripts with a bash/sh shebang, found automatically.
SHEBANG_SCRIPTS := $(shell grep -lrE '^\#!.*(bash|/bin/sh\b|dash|ksh)' bin etc 2>/dev/null | sort)

# Sourced files with no shebang of their own; must be told which shell dialect to check as.
SOURCED_SCRIPTS := etc/bashrc

TARGETS=help lint install upgrade
.PHONY: $(TARGETS)

help:
	@echo "Makefile targets: $(TARGETS)"

lint:
	shellcheck $(SHEBANG_SCRIPTS)
	shellcheck -s bash $(SOURCED_SCRIPTS)

install:
	bin/deploy-etc

upgrade:
	bin/migrate-vim
