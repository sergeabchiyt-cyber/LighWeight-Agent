#!/bin/sh

# Render config from env vars
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json

# Binance tools venv
. /opt/venv/bin/activate

# Render health check (internal)
/usr/local/bin/health-server &

# Binance tools API (internal, PicoClaw calls localhost:8000)
cd /app
uvicorn binance_tools:app --host 0.0.0.0 --port 8000 &

# PicoClaw gateway on Render's port
export PORT="${PORT:-10000}"
exec picoclaw
