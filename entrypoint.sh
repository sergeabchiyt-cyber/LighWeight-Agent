#!/bin/bash
set -e

# 1. Inject SSH Key from Env Var
mkdir -p ~/.ssh /workspace
echo "$LIGHTNING_SSH_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# 2. Mount Lightning Studio's /workspace directory to local /workspace
sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,StrictHostKeyChecking=no,IdentityFile=~/.ssh/id_ed25519 \
  "${LIGHTNING_SSH_USER}@ssh.lightning.ai:/workspace" /workspace

# Force ZeroClaw to read config from the persistent SSHFS mount
export ZEROCLAW_CONFIG=/workspace/config.toml
export ZEROCLAW_workspace__path=/workspace

# 3. Check if setup is complete
if [ ! -f /workspace/.setup_complete ]; then
    echo "Config not found. Starting setup server on port $PORT..."
    # exec replaces the shell process. When python exits, the container stops and Render restarts it.
    exec python3 /app/setup_server.py
fi

# 4. Start ZeroClaw daemon
echo "Setup complete. Starting ZeroClaw daemon..."
exec zeroclaw daemon
