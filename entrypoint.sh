#!/bin/sh

# Inject Render Env Vars into config.json
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json

# Activate virtual environment
. /opt/venv/bin/activate

# Start health server on 8080 (internal, for Render health checks)
/usr/local/bin/health-server &

# Start Binance tools API on 8000 (internal, for PicoClaw tool calls)
cd /app
uvicorn binance_tools:app --host 0.0.0.0 --port 8000 &

# Start PicoClaw on Render's PORT (10000)
PORT=${PORT:-10000}
exec /usr/local/bin/picoclaw
