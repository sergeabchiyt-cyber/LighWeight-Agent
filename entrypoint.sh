#!/bin/bash
set -e

# 1. Inject SSH Key from Env Var
mkdir -p ~/.ssh /root/workspace
chmod 700 ~/.ssh
printf "%s" "$LIGHTNING_SSH_KEY" > ~/.ssh/key
chmod 600 ~/.ssh/key

SSH_CMD="ssh -v -o StrictHostKeyChecking=no -i ~/.ssh/key"

# 2. Pull home directory from Lightning (Persistent Storage)
echo "Pulling config from Lightning home directory..."
if ! rsync -az -e "$SSH_CMD" \
  "${LIGHTNING_SSH_USER}@ssh.lightning.ai:~/" /root/workspace/; then
  echo "❌ SSH Connection Failed. Check verbose logs above."
  exit 1
fi

# 3. Background Sync Loop (Pushes state back to Lightning every 60s)
(
  while true; do
    sleep 60
    rsync -az -e "ssh -o StrictHostKeyChecking=no -i ~/.ssh/key" \
      /root/workspace/ "${LIGHTNING_SSH_USER}@ssh.lightning.ai:~/" 2>/dev/null || true
  done
) &

# 4. Locate config and start daemon
export ZEROCLAW_workspace__path=/root/workspace

# Find the config dynamically inside the synced home directory
CONFIG_PATH=$(find /root/workspace -name "config.toml" -print -quit)
if [ -z "$CONFIG_PATH" ]; then
  echo "❌ config.toml not found in home directory."
  exit 1
fi

export ZEROCLAW_CONFIG="$CONFIG_PATH"
echo "✅ Using config: $CONFIG_PATH"

exec zeroclaw daemon
