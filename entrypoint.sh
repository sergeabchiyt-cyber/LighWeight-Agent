#!/bin/sh

# Render config from env vars
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json
envsubst < /etc/picoclaw/security.template.yml > /root/.picoclaw/.security.yml

# Binance tools venv
. /opt/venv/bin/activate

# Render health check (internal, port 8080)
/usr/local/bin/health-server &

# Binance tools API (internal, port 8000)
cd /app
uvicorn binance_tools:app --host 0.0.0.0 --port 8000 &

# PicoClaw gateway on Render's port (10000)
export PICOCLAW_GATEWAY_PORT="${PORT:-10000}"
exec picoclaw gateway
