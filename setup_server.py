import os, sys, http.server, socketserver

PORT = int(os.environ.get("PORT", 10000))
WORKSPACE = "/workspace"

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(self.html().encode())

    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        data = self.rfile.read(length).decode()
        
        if self.path == '/save':
            with open(f"{WORKSPACE}/config.toml", "w") as f: f.write(data)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Saved")
        elif self.path == '/done':
            with open(f"{WORKSPACE}/.setup_complete", "w") as f: f.write("1")
            self.send_response(200)
            self.end_headers()
            sys.exit(0)

    def html(self):
        return """<!DOCTYPE html><html><head><title>ZeroClaw Setup</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        body{font-family:system-ui,sans-serif;max-width:600px;margin:2rem auto;padding:1rem;background:#121212;color:#e0e0e0;line-height:1.5}
        h1{color:#fff;margin-bottom:24px}
        textarea{width:100%;height:200px;background:#1e1e1e;color:#fff;border:1px solid #333;padding:12px;font-family:monospace;border-radius:4px;box-sizing:border-box}
        button{min-height:44px;padding:12px 24px;font-size:16px;cursor:pointer;border-radius:4px;border:none;width:100%;margin-top:8px;transition:opacity 0.2s}
        button:active{opacity:0.8}
        .btn-primary{background:#007bff;color:#fff}
        .btn-success{background:#28a745;color:#fff}
        .btn-secondary{background:#333;color:#fff}
        .step{margin-bottom:16px;padding:16px;background:#1e1e1e;border-radius:8px}
        code{background:#333;padding:4px 8px;border-radius:4px;font-size:14px}
        </style>
        </head><body>
        <h1>ZeroClaw Manual Setup</h1>
        <div class="step">
            <h3>1. Generate Config</h3>
            <p>Run <code>zeroclaw onboard</code> locally or in your Lightning terminal.</p>
        </div>
        <div class="step">
            <h3>2. Paste config.toml</h3>
            <textarea id="c" placeholder="Paste config.toml contents here..."></textarea>
            <button class="btn-secondary" onclick="fetch('/save',{method:'POST',body:document.getElementById('c').value}).then(()=>alert('Saved to Lightning'))">Save to Persistent Drive</button>
        </div>
        <div class="step">
            <h3>3. Launch Agent</h3>
            <button class="btn-success" onclick="fetch('/done',{method:'POST'}).then(()=>{document.body.innerHTML='<h1>Starting...</h1>';setTimeout(()=>location.reload(),3000)})">Finish & Start Daemon</button>
        </div>
        </body></html>"""

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
