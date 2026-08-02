# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS builder

# The install script requires curl, jq, and sha256sum (coreutils)
RUN apt-get update && \
    apt-get install -y curl ca-certificates jq coreutils && \
    rm -rf /var/lib/apt/lists/*

# Run the official install script (auto-detects architecture via uname -m)
RUN curl -fsSL https://pkg.lightpanda.io/install.sh | LIGHTPANDA_DIR=/usr/local/bin bash

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/lightpanda /usr/local/bin/lightpanda

EXPOSE 10000

CMD ["sh", "-c", "lightpanda mcp --port ${PORT:-10000} --host 0.0.0.0"]
