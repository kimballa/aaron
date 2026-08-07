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

