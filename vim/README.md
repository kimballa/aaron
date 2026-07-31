
# vim dir

The vim/ directory in here is my ~/.vim directory.
The vimrc file is my ~/.vimrc file. (Actually, these are symlinked into my git repo.)

The only thing that is missing is the .vim/eclim/ directory. That seems to
need to be installed via the eclim installer at www.eclim.org.
(Note, 2020: Disabled eclim in vimrc)

You should also install the exuberant-ctags package:
  sudo apt-get install exuberant-ctags

## Upgrade notes

This used to be the separate vimscripts.git repo. That repo is now deprecated;
its contents live here, in the vim/ subdirectory of aaron.git.

If your machine still has ~/.vim or ~/.vimrc symlinked into the old
vimscripts.git checkout, run `bin/upgrade-etc` (from aaron.git) to repoint
them at this directory.
