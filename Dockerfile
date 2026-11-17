# ---- Build stage ----
FROM rust:1.85-slim-bookworm AS builder

WORKDIR /app

# Install build dependencies (if your crates need OpenSSL, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
COPY src ./src

# Build the release binary.
RUN cargo build --release --locked

# ---- Runtime stage ----
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/telegram-webhook-gateway /app/telegram-webhook-gateway

# Render sets PORT automatically; default to 10000 if not set[reference:5].
ENV PORT=10000

# Do NOT hardcode TELEGRAM_WEBHOOK_SECRET here.
# Set it as an environment variable in the Render dashboard.

EXPOSE 10000

CMD ["/app/telegram-webhook-gateway"]
