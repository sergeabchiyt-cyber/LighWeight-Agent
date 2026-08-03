#!/bin/bash
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 "${LIGHTNING_SSH_USER}@ssh.lightning.ai" "$@"
