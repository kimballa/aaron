
# Personal dotfiles repo

This contains my vimrc, bashrc, vim plugins/config (in vim/), personal LLM
skills shared by Claude Code and Codex (in claude/plugin/), and a bunch of
handy scripts. For best results, put aaron.git/bin in your $PATH.

## Installation

Install prerequisites via `apt` (or your platform's equivalent):

```bash
sudo bin/install-preferred-packages.sh
```

Or for OS X:

```bash
bin/install-preferred-packages-osx.sh
```

Then run:

```bash
make install
```

This runs the `deploy-etc` script, which symlinks .bashrc, .vimrc, .vim,
and other config files to point at the files in etc/ and vim/ in this
directory (after backing up any pre-existing files, of course!). It also
symlinks claude/plugin/ into ~/.claude/skills/aaron and claude/CLAUDE.md into
~/.claude/CLAUDE.md. Other Claude skills and plugins are left untouched.
It is safe to run repeatedly: existing symlinks are left alone, and any
symlink that's gone broken (e.g., because this repo moved) is repaired.

If `codex` is on PATH, the script also registers this repo's `aaron-personal`
marketplace and installs or refreshes `aaron@aaron-personal`. If Codex isn't
installed, it skips that step. This marketplace is separate from Warp's
`aaron-local` marketplace.

Both clients use the same skills under `claude/plugin/skills/`. The plugin
has a manifest for each client; Codex's marketplace catalog is at
`.agents/plugins/marketplace.json`. Add personal skills to
`claude/plugin/skills/<skill-name>/SKILL.md`. After editing a skill, run
`make install` again (or run the commands below to refresh only Codex):

```bash
codex plugin marketplace add .
codex plugin add aaron@aaron-personal
```

Restart your Codex client and start a new chat to load the refreshed skills.
The Arduino skill can be invoked as `$new-arduino-project`.

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
