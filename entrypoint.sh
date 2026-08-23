#!/bin/sh

echo "=== Entrypoint starting ==="

mkdir -p /root/.picoclaw

echo "Rendering config.json..."
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json
echo "--- config.json content ---"
cat /root/.picoclaw/config.json
echo "--- end config.json ---"

echo "Rendering .security.yml..."
envsubst < /etc/picoclaw/security.template.yml > /root/.picoclaw/.security.yml
echo "--- .security.yml content ---"
cat /root/.picoclaw/.security.yml
echo "--- end .security.yml ---"

echo "=== Starting services ==="

. /opt/venv/bin/activate

# 1. FastAPI gets the PUBLIC port (10000) for Render health checks and debug routes
uvicorn binance_tools:app --host 0.0.0.0 --port ${PORT:-10000} &
echo "FastAPI started on public port ${PORT:-10000}"

# 2. PicoClaw runs on an INTERNAL port (Telegram is long-polling, no inbound webhooks needed)
export PICOCLAW_GATEWAY_PORT=8001
echo "PicoClaw starting on internal port 8001"

exec picoclaw gateway
