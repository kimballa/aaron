#!/usr/bin/env bash
#
# The packages that make a VM feel like home.
# Run this with sudo to install everything shown here.

set -e
set -x

apt-get install iotop gitk ack vim tldr jq python3 tig htop rip-grep

pip3 install jc
