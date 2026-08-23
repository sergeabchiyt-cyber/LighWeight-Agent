#!/bin/sh

echo "=== Entrypoint starting ==="
echo "Checking template files..."

if [ ! -f /etc/picoclaw/config.template.json ]; then
    echo "ERROR: config.template.json missing"
    ls -la /etc/picoclaw/ 2>/dev/null || echo "  /etc/picoclaw/ does not exist"
else
    echo "config.template.json found"
fi

if [ ! -f /etc/picoclaw/security.template.yml ]; then
    echo "ERROR: security.template.yml missing"
else
    echo "security.template.yml found"
fi

echo "Creating /root/.picoclaw..."
mkdir -p /root/.picoclaw

echo "Rendering config.json..."
envsubst < /etc/picoclaw/config.template.json > /root/.picoclaw/config.json
if [ $? -eq 0 ]; then
    echo "config.json written successfully"
    echo "--- config.json content ---"
    cat /root/.picoclaw/config.json
    echo "--- end config.json ---"
else
    echo "ERROR: envsubst failed for config.json"
fi

echo "Rendering .security.yml..."
envsubst < /etc/picoclaw/security.template.yml > /root/.picoclaw/.security.yml
if [ $? -eq 0 ]; then
    echo ".security.yml written successfully"
    echo "--- .security.yml content ---"
    cat /root/.picoclaw/.security.yml
    echo "--- end .security.yml ---"
else
    echo "ERROR: envsubst failed for .security.yml"
fi

echo "=== Starting services ==="

. /opt/venv/bin/activate

/usr/local/bin/health-server &
echo "Health server started on :8080"

cd /app
uvicorn binance_tools:app --host 0.0.0.0 --port 8000 &
echo "Binance tools started on :8000"

export PICOCLAW_GATEWAY_PORT="${PORT:-10000}"
echo "Starting picoclaw gateway on port ${PICOCLAW_GATEWAY_PORT}"
exec picoclaw gateway
