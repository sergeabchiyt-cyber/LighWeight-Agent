FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y curl ca-certificates openssh-client rsync && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | sh

# Add Cargo bin to PATH so the entrypoint script can find 'zeroclaw'
ENV PATH="/root/.cargo/bin:${PATH}"

COPY entrypoint.sh /entrypoint.sh
COPY lightning_exec.sh /usr/local/bin/lightning_exec

RUN chmod +x /entrypoint.sh /usr/local/bin/lightning_exec

ENV ZEROCLAW_gateway__port=${PORT:-10000}
ENV ZEROCLAW_gateway__allow_public_bind=true

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]
