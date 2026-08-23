from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import ccxt
import os

app = FastAPI()

# Initialize Binance client
binance = ccxt.binance({
    'apiKey': os.environ.get('BINANCE_API_KEY'),
    'secret': os.environ.get('BINANCE_API_SECRET'),
    'options': {
        'defaultType': 'spot',
        'adjustForTimeDifference': True
    }
})

# Optional: set sub-account if using one
sub_account = os.environ.get('BINANCE_SUB_ACCOUNT_NAME')
if sub_account:
    binance.headers = {'X-MBX-SUB-ACCOUNT': sub_account}

class TradeRequest(BaseModel):
    symbol: str
    side: str  # "buy" or "sell"
    type: str  # "market" or "limit"
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
