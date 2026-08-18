FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl ca-certificates && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | sh

ENV PATH="/root/.cargo/bin:${PATH}"

RUN mkdir -p /root/.zeroclaw
# Direct copy of the hardcoded file
COPY config.toml /root/.zeroclaw/config.toml 

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

CMD ["sh", "-c", "python /app/keepalive.py & zeroclaw daemon"]
