
# Personal dotfiles repo

This contains my vimrc, bashrc, vim plugins/config (in vim/), and a bunch
of handy scripts.  For best results, put aaron.git/bin in your $PATH.

## Installation

Install prerequisites via `apt` (or your platform's equivalent):

```bash
sudo apt-get install shellcheck exuberant-ctags
```

Then run:

```bash
make install
```

This runs the `deploy-etc` script, which symlinks .bashrc, .vimrc, .vim,
and other config files to point at the files in etc/ and vim/ in this
directory (after backing up any pre-existing files, of course!). It is
safe to run repeatedly: existing correct symlinks are left alone, and any
symlink that's gone broken (e.g., because this repo moved) is repaired.

Machine-specific bashrc elements go in ~/.localbashrc.

If you have an old installation that still links to the deprecated,
separate 'vimscripts' repo, run `bin/migrate-vim` to repoint those links
at the vim/ directory in this repo.

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
