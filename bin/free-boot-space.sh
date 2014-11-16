#!/usr/bin/env bash
#
# Frees up space in /boot when it gets full of old kernels


if [ "$1" == "--help" ]; then
  echo "Usage: $0 { --dry-run | --force }"
elif [ "$1" == "--dry-run" ]; then
  # Just list what we'd remove.
  echo "Would remove the following packages:"
  echo ""
  dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | \
      sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'
elif [ "$1" == "--force" ]; then
  # Actually clean up.
  dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | \
      sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | \
      xargs sudo apt-get -y purge
else
  echo "Use '$0 --help' for options."
  exit 1
fi



