#!/bin/sh

# Inject Render Env Vars into config.json
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json

# Activate virtual environment
. /opt/venv/bin/activate

# Start health server
/usr/local/bin/health-server &

# Start Binance tools API
cd /app
uvicorn binance_tools:app --host 0.0.0.0 --port 8000 &

# Start PicoClaw
exec /usr/local/bin/picoclaw
