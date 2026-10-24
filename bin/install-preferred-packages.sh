#!/usr/bin/env bash
#
# The packages that make a VM feel like home.
# Run this with sudo to install everything shown here.

set -euo pipefail
set -x

# Keep this list in sync with the Dockerfile in kimballa/dev-sandbox.git
apt-get update 
apt-get install -y --no-install-recommends \
    ack \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    exuberant-ctags \
    fd-find \
    git \
    gitk \
    htop \
    iotop \
    jq \
    less \
    locales \
    lsof \
    make \
    man-db \
    netcat-openbsd \
    net-tools \
    openssh-client \
    openssh-server \
    pipx \
    psmisc \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    shellcheck \
    socat \
    strace \
    sudo \
    tig \
    tldr \
    tmux \
    tree \
    unzip \
    vim \
    wget \
    zip

locale-gen en_US.UTF-8 

set +x

# Install nodejs
echo "Checking for node..."
NODE=$(which node || true)
if [ -z "$NODE" ]; then
  echo "Installing nodejs..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
      && apt-get install -y --no-install-recommends nodejs
fi

# Install gh CLI
echo "Checking for gh..."
GITHUB=$(which gh || true)
if [ -z "$GITHUB" ]; then
  echo "Installing github..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
      && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          > /etc/apt/sources.list.d/github-cli.list \
      && apt-get update \
      && apt-get install -y --no-install-recommends gh
fi

# gh extensions and skills live in the user's home, so like Claude Code they are per-user
# installs and must run as the sudo'ing user.
run_as_user() {
  if [ -n "${SUDO_USER:-}" ]; then
    su - "$SUDO_USER" -c "$1"
  else
    bash -c "$1"
  fi
}

# Install gh-stack, the gh extension for stacked PRs (used by the rebase skill).
# Listings are captured before grepping because `grep -q` exits early, which makes `gh` die of
# SIGPIPE and trips pipefail. Failures are not fatal (e.g. gh not logged in yet): rerun this
# script afterwards.
echo "Checking for gh-stack..."
GH_STACK_EXTENSIONS=$(run_as_user "gh extension list" 2>/dev/null || true)
if ! grep -q 'github/gh-stack' <<<"$GH_STACK_EXTENSIONS"; then
  echo "Installing gh-stack..."
  run_as_user "gh extension install github/gh-stack" \
      || echo "WARNING: gh-stack install failed; run 'gh extension install github/gh-stack' later."
fi

# Install the gh-stack agent skill for Claude Code (needs gh >= 2.90 for `gh skill`). A
# non-interactive `gh skill install` fails if the skill already exists, so check first.
echo "Checking for the gh-stack skill..."
GH_STACK_SKILLS=$(run_as_user "gh skill list --agent claude-code --scope user --json skillName" \
    2>/dev/null || true)
if ! grep -Eq '"skillName": *"gh-stack"' <<<"$GH_STACK_SKILLS"; then
  echo "Installing the gh-stack skill..."
  run_as_user "gh skill install github/gh-stack gh-stack --agent claude-code --scope user" \
      || echo "WARNING: gh-stack skill install failed; run 'gh skill install github/gh-stack gh-stack --agent claude-code --scope user' later."
fi

# Install AWS CLI
echo "Checking for aws..."
AWS=$(which aws || true)
if [ -z "$AWS" ]; then
  echo "Installing AWS..."
  ARCH=$(dpkg --print-architecture) \
      && if [ "$ARCH" = "arm64" ]; then AWS_ARCH="aarch64"; else AWS_ARCH="x86_64"; fi \
      && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscliv2.zip \
      && unzip /tmp/awscliv2.zip -d /tmp \
      && /tmp/aws/install \
      && rm -rf /tmp/awscliv2.zip /tmp/aws
fi

# Install Claude Code
echo "Checking for claude..."
if [ -z "$SUDO_USER" ]; then
  CLAUDE=$(which claude || true)
  if [ -z "$CLAUDE" ]; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi
else
  # We were running as sudo but this should be a per-user install; traverse back to the sudo'ing
  # user for this installation.
  CLAUDE=$(su - "$SUDO_USER" -c "which claude" || true)
  if [ -z "$CLAUDE" ]; then
    echo "Installing Claude Code..."
    su - "$SUDO_USER" -c "curl -fsSL https://claude.ai/install.sh | bash"
  fi
fi

echo "Preferred package installation complete!"

