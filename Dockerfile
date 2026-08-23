# ---- Stage 1: build only the tiny health server ----
FROM golang:alpine AS builder
WORKDIR /build
RUN cat <<'EOF' > health.go
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
RUN go build -o /health-server health.go

# ---- Stage 2: runtime on the OFFICIAL picoclaw image ----
FROM sipeed/picoclaw:latest

# Alpine-based image; add python + envsubst
RUN apk add --no-cache ca-certificates tzdata gettext python3 py3-pip py3-virtualenv
RUN python3 -m venv /opt/venv
RUN /opt/venv/bin/pip install --no-cache-dir fastapi uvicorn ccxt

WORKDIR /app

COPY --from=builder /health-server /usr/local/bin/health-server
COPY config.template.json /etc/picoclaw/config.template.json
COPY security.template.yml /etc/picoclaw/security.template.yml
COPY binance_tools.py /app/binance_tools.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /root/.picoclaw \
 && chmod +x /usr/local/bin/health-server /usr/local/bin/entrypoint.sh

ENV PICOCLAW_GATEWAY_HOST=0.0.0.0

EXPOSE 8000 8080 10000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
