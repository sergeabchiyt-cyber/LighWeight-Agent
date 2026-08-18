FROM python:3.11-slim

# 0. Set working directory to prevent "directory nonexistent" errors
WORKDIR /app

# 1. Install basic file handling utilities + gettext (for envsubst)
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    file \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# 2. Install ZeroClaw directly from GitHub to bypass Cloudflare 403
RUN curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | sh

# 3. Add Cargo bin to PATH so the 'zeroclaw' binary is globally executable
ENV PATH="/root/.cargo/bin:${PATH}"

# 4. Create config directory and copy the template
RUN mkdir -p /root/.zeroclaw
COPY config.template.toml /root/.zeroclaw/config.template.toml

# 5. Dummy HTTP Server with explicit /health endpoint
RUN echo "import os\nfrom http.server import HTTPServer, BaseHTTPRequestHandler\n\
class Handler(BaseHTTPRequestHandler):\n\
    def do_GET(self):\n\
        if self.path == '/health':\n\
            self.send_response(200)\n\
            self.end_headers()\n\
            self.wfile.write(b'ZeroClaw Node Healthy')\n\
        else:\n\
            self.send_response(404)\n\
            self.end_headers()\n\
HTTPServer(('0.0.0.0', int(os.environ.get('PORT', 10000))), Handler).serve_forever()" > /app/keepalive.py

# 6. Render environment variables into config.toml, start Dummy Server, and launch ZeroClaw Daemon
CMD ["sh", "-c", "envsubst < /root/.zeroclaw/config.template.toml > /root/.zeroclaw/config.toml && python /app/keepalive.py & zeroclaw daemon"]
