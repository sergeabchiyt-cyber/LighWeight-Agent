FROM python:3.11-slim

WORKDIR /app

# 1. Install all required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    file \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# 2. Install ZeroClaw directly from GitHub
RUN curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | sh

# 3. Add Cargo bin to PATH and FORCE Rust logging natively inside the image
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUST_LOG="info,zeroclaw=debug"

# 4. Create config directory and copy the hardcoded file
RUN mkdir -p /root/.zeroclaw
COPY config.toml /root/.zeroclaw/config.toml 

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

# 6. Start Dummy Server and ZeroClaw Daemon WITH THE --verbose FLAG
CMD ["sh", "-c", "python /app/keepalive.py & zeroclaw daemon --verbose"]
