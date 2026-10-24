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
    git-lfs \
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

echo "Setting up git lfs"
# Use Homebrew's git (prefix is /opt/homebrew on Apple Silicon, /usr/local on Intel).
BREW_GIT="$(brew --prefix)/bin/git"
"$BREW_GIT" lfs install
"$BREW_GIT" lfs version

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

# Install gh-stack, the gh extension for stacked PRs (used by the rebase skill).
# Listings are captured before grepping because `grep -q` exits early, which makes `gh` die of
# SIGPIPE and trips pipefail. Failures are not fatal (e.g. gh not logged in yet): rerun this
# script afterwards.
echo "Checking for gh-stack..."
GH_STACK_EXTENSIONS=$(gh extension list 2>/dev/null || true)
if ! grep -q 'github/gh-stack' <<<"$GH_STACK_EXTENSIONS"; then
  echo "Installing gh-stack..."
  gh extension install github/gh-stack \
      || echo "WARNING: gh-stack install failed; run 'gh extension install github/gh-stack' later."
fi

# Install the gh-stack agent skill for an agent (needs gh >= 2.90 for `gh skill`). A
# non-interactive `gh skill install` fails if the skill already exists, so check first.
install_gh_stack_skill() {
  local agent="$1" installed
  echo "Checking for the gh-stack skill ($agent)..."
  installed=$(gh skill list --agent "$agent" --scope user --json skillName 2>/dev/null || true)
  if ! grep -Eq '"skillName": *"gh-stack"' <<<"$installed"; then
    echo "Installing the gh-stack skill ($agent)..."
    gh skill install github/gh-stack gh-stack --agent "$agent" --scope user \
        || echo "WARNING: gh-stack skill install ($agent) failed; run 'gh skill install github/gh-stack gh-stack --agent $agent --scope user' later."
  fi
}

install_gh_stack_skill claude-code

# Codex is optional: only install its skills if it is present (on PATH, or it has run before and
# created ~/.codex).
echo "Checking for codex..."
if command -v codex &>/dev/null || [ -d "$HOME/.codex" ]; then
  install_gh_stack_skill codex
else
  echo "codex not found; skipping its skills."
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

# Install Codex CLI
echo "Checking for codex..."
CODEX=$(which codex || true)
if [ -z "$CODEX" ]; then
  echo "Installing Codex CLI..."
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

echo "Preferred package installation complete!"
