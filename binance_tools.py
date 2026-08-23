from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import ccxt
import os
import glob

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "ok"}
    
@app.get("/debug/security-path")
async def debug_security_path():
    import os
    paths_to_check = [
        "/root/.picoclaw/.security.yml",
        "/root/.picoclaw/security.yml",
        "/root/.picoclaw/config.security.yml",
    ]
    results = {}
    for p in paths_to_check:
        results[p] = {
            "exists": os.path.exists(p),
            "size": os.path.getsize(p) if os.path.exists(p) else 0
        }
    return results
    
@app.get("/debug/state")
async def debug_state():
    result = {
        "picoclaw_dir_exists": os.path.exists("/root/.picoclaw"),
        "files_in_picoclaw_dir": glob.glob("/root/.picoclaw/*"),
        "etc_picoclaw_files": glob.glob("/etc/picoclaw/*"),
        "env_vars_present": {
            "ORCAROUTER_API_KEY": bool(os.environ.get("ORCAROUTER_API_KEY")),
            "TELEGRAM_BOT_TOKEN": bool(os.environ.get("TELEGRAM_BOT_TOKEN")),
            "TELEGRAM_USER_ID": bool(os.environ.get("TELEGRAM_USER_ID")),
        },
        "current_user": os.getenv("USER", "unknown"),
        "home": os.path.expanduser("~")
    }
    return result
    
@app.get("/debug/config")
async def debug_config():
    try:
        with open("/root/.picoclaw/config.json") as f:
            return f.read()
    except FileNotFoundError:
        raise HTTPException(404, "config.json not found")

@app.get("/debug/security")
async def debug_security():
    try:
        with open("/root/.picoclaw/.security.yml") as f:
            return f.read()
    except FileNotFoundError:
        raise HTTPException(404, ".security.yml not found")

binance = ccxt.binance({
    'apiKey': os.environ.get('BINANCE_API_KEY'),
    'secret': os.environ.get('BINANCE_API_SECRET'),
    'options': {
        'defaultType': 'spot',
        'adjustForTimeDifference': True
    }
})

class TradeRequest(BaseModel):
    symbol: str
    side: str
    type: str
    amount: float
    price: float = None

@app.post("/tools/get_balance")
async def get_balance():
    try:
        balance = binance.fetch_balance()
        return {"balance": balance['total']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tools/get_ticker")
async def get_ticker(symbol: str):
    try:
        ticker = binance.fetch_ticker(symbol)
        return {"symbol": symbol, "price": ticker['last'], "change_24h": ticker['percentage']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tools/place_order")
async def place_order(req: TradeRequest):
    try:
        order = binance.create_order(
            symbol=req.symbol,
            type=req.type,
            side=req.side,
            amount=req.amount,
            price=req.price
        )
        return {"order_id": order['id'], "status": order['status']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tools/get_positions")
async def get_positions():
    try:
        positions = binance.fetch_positions()
        return {"positions": [p for p in positions if p['contracts'] > 0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
