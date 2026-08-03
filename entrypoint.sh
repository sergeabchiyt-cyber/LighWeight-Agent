#!/bin/bash
set -e

# 1. Inject SSH Key from Env Var
mkdir -p ~/.ssh /workspace
echo "$LIGHTNING_SSH_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

SSH_CMD="ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519"

# 2. Pull existing workspace from Lightning (Persistent Storage)
echo "Syncing workspace from Lightning..."
rsync -az --delete -e "$SSH_CMD" \
  "${LIGHTNING_SSH_USER}@ssh.lightning.ai:/workspace/" /workspace/ || true

# 3. Background Sync Loop (Pushes changes back to Lightning every 60s)
# This ensures ZeroClaw's memory, logs, and state are saved to the 400GB drive
(
  while true; do
    sleep 60
    rsync -az --delete -e "$SSH_CMD" \
      /workspace/ "${LIGHTNING_SSH_USER}@ssh.lightning.ai:/workspace/" 2>/dev/null || true
  done
) &

# 4. Force ZeroClaw to use the synced directory
export ZEROCLAW_CONFIG=/workspace/config.toml
export ZEROCLAW_workspace__path=/workspace

# 5. Check if setup is complete
if [ ! -f /workspace/.setup_complete ]; then
    echo "Config not found. Starting setup server on port $PORT..."
    exec python3 /app/setup_server.py
fi

# 6. Start ZeroClaw daemon
echo "Setup complete. Starting ZeroClaw daemon..."
exec zeroclaw daemon
