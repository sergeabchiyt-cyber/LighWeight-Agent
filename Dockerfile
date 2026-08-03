FROM debian:bookworm-slim

# Removed sshfs (requires /dev/fuse). Added rsync for background syncing.
RUN apt-get update && \
    apt-get install -y curl ca-certificates openssh-client rsync python3 && \
    rm -rf /var/lib/apt/lists/*

# Spoof User-Agent to bypass Cloudflare 403
RUN curl -fsSL -A "Mozilla/5.0" https://zeroclawlabs.ai/install.sh | bash

COPY entrypoint.sh /entrypoint.sh
COPY setup_server.py /app/setup_server.py
COPY lightning_exec.sh /usr/local/bin/lightning_exec

RUN chmod +x /entrypoint.sh /app/setup_server.py /usr/local/bin/lightning_exec

ENV ZEROCLAW_gateway__port=${PORT:-10000}
ENV ZEROCLAW_gateway__allow_public_bind=true

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]
