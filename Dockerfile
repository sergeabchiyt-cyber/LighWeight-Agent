FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git gcc musl-dev libc-dev python3 py3-pip

WORKDIR /build

# Build PicoClaw
RUN git clone https://github.com/sipeed/picoclaw.git .
RUN go build -o /picoclaw .

# Install Python dependencies for Binance tools
RUN pip3 install --no-cache-dir fastapi uvicorn ccxt

# Build health server
RUN cat <<EOF > /build/health.go
package main
import "net/http"
func main() {
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    })
    http.ListenAndServe(":8080", nil)
}
EOF
RUN go build -o /health-server /build/health.go

# --- Runtime Stage ---
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata gettext python3 py3-pip
RUN pip3 install --no-cache-dir fastapi uvicorn ccxt

WORKDIR /app

COPY --from=builder /picoclaw /usr/local/bin/picoclaw
COPY --from=builder /health-server /usr/local/bin/health-server
COPY config.template.json /etc/picoclaw/config.json
COPY binance_tools.py /app/binance_tools.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV PICOCLAW_GATEWAY_HOST=0.0.0.0
ENV PORT=18800

EXPOSE 10000 8080 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
