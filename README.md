
# Personal dotfiles repo

This contains my vimrc, bashrc, vim plugins/config (in vim/), Claude Code
skills/agents (in claude/), and a bunch of handy scripts.  For best results,
put aaron.git/bin in your $PATH.

## Installation

Install prerequisites via `apt` (or your platform's equivalent):

```bash
sudo bin/install-preferred-packages.sh
sudo apt-get install shellcheck exuberant-ctags
```

For OS X, also:

```bash
brew install bash-completion
```

Then run:

```bash
make install
```

This runs the `deploy-etc` script, which symlinks .bashrc, .vimrc, .vim,
and other config files to point at the files in etc/ and vim/ in this
directory (after backing up any pre-existing files, of course!). It also
symlinks each skill/agent in claude/skills/ and claude/agents/ into
~/.claude/skills/ and ~/.claude/agents/, individually, so any skills that
live only in ~/.claude (e.g. work-specific ones, not tracked here since
this repo is public) are left untouched. It is safe to run repeatedly:
existing correct symlinks are left alone, and any symlink that's gone
broken (e.g., because this repo moved) is repaired.

Machine-specific bashrc elements go in ~/.localbashrc.

If you have an old installation, run `make upgrade` (or `bin/upgrade-etc`
directly) to migrate it to the current layout. This repoints any links
that still point to the deprecated, separate 'vimscripts' repo at the
vim/ directory in this repo, and moves the bash_completion.d symlink to
its new XDG-compliant location under ~/.local/share.

## Linting

Run `make lint` to shellcheck all the scripts in this repo.

## Renamed branch

The branch was renamed from `master` to `main` in 2025. For 
deployments that have not yet updated, follow these steps:

```bash
# Switch to the "master" branch (if not already there):
$ git checkout master

# Rename it to "main":
$ git branch -m master main

# Get the latest commits (and branches!) from the remote:
$ git fetch

# Remove the existing tracking connection with "origin/master":
$ git branch --unset-upstream

# Create a new tracking connection with the new "origin/main" branch:
$ git branch -u origin/main
```
