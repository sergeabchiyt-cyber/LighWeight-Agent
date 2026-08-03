#!/bin/bash
set -e

# 1. Inject SSH Key from Env Var
mkdir -p ~/.ssh /workspace
echo "$LIGHTNING_SSH_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# 2. Mount Lightning Studio's /workspace directory to local /workspace
sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,StrictHostKeyChecking=no,IdentityFile=~/.ssh/id_ed25519 \
  "${LIGHTNING_SSH_USER}@ssh.lightning.ai:/workspace" /workspace

# 3. Tell ZeroClaw to use the mounted drive as its persistent workspace
export ZEROCLAW_workspace__path=/workspace

# 4. Start ZeroClaw
exec zeroclaw daemon
