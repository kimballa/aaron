#!/usr/bin/env bash
#
# The packages that make a Mac feel like home.
# This is the macOS counterpart to install-preferred-packages.sh (Linux/apt).
# Run this as your normal user -- Homebrew refuses to run as root, so do NOT use sudo.

set -euo pipefail
set -x

if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi

# Provides `make`/a C toolchain -- the macOS equivalent of build-essential.
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
fi

brew update

# Keep this list in sync with the apt list in install-preferred-packages.sh where a
# macOS equivalent exists. Notes on Linux-only tools with no direct port:
#   - iotop, strace: no macOS equivalent (use `sudo fs_usage`/Instruments/dtrace instead)
#   - psmisc (killall/fuser): killall already ships with macOS; pstree below covers the rest
#   - net-tools, openssh-client/server, sudo, unzip, zip, lsof, less, rsync: already
#     ship with macOS; installed below anyway to get current versions on $PATH
#   - locales/locale-gen: not applicable, macOS handles locales differently
#   - man-db, ca-certificates: macOS's built-in equivalents are already sufficient
brew install \
    ack \
    bash-completion \
    ctags \
    fd \
    git \
    git-gui \
    htop \
    jq \
    less \
    lsof \
    netcat \
    pipx \
    pstree \
    python3 \
    ripgrep \
    rsync \
    shellcheck \
    socat \
    tig \
    tlrc \
    tmux \
    tree \
    vim \
    wget

set +x

# Install nodejs
echo "Checking for node..."
NODE=$(which node || true)
if [ -z "$NODE" ]; then
  echo "Installing nodejs..."
  brew install node
fi

# Install gh CLI
echo "Checking for gh..."
GITHUB=$(which gh || true)
if [ -z "$GITHUB" ]; then
  echo "Installing github..."
  brew install gh
fi

# Install AWS CLI
echo "Checking for aws..."
AWS=$(which aws || true)
if [ -z "$AWS" ]; then
  echo "Installing AWS..."
  brew install awscli
fi

# Install Claude Code
echo "Checking for claude..."
CLAUDE=$(which claude || true)
if [ -z "$CLAUDE" ]; then
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "Preferred package installation complete!"
