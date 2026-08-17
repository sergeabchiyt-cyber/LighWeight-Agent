FROM python:3.11-slim

# 1. Install basic file handling utilities (curl, unzip, file)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    file \
    && rm -rf /var/lib/apt/lists/*

# 2. Install ZeroClaw Rust binary
RUN curl -fsSL https://zeroclawlabs.ai/install.sh | bash

# 3. Create config directory and inject configuration
RUN mkdir -p /root/.zeroclaw
COPY config.toml /root/.zeroclaw/config.toml

# 4. Dummy HTTP Server with explicit /health endpoint for Render's router and UptimeRobot
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

# 5. Start Dummy Server and ZeroClaw Daemon concurrently
CMD ["sh", "-c", "python /app/keepalive.py & zeroclaw daemon"]
