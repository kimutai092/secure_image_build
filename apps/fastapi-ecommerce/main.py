from fastapi import FastAPI
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI(title="E-Commerce Demo (FastAPI)")
checkout_counter = Counter("checkout_requests_total", "Total checkout requests")

app.mount("/", StaticFiles(directory="public", html=True), name="static")

@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/api/checkout")
async def checkout(payload: dict):
    items = payload.get("items", [])
    tax_rate = float(payload.get("taxRate", 0.07))
    subtotal = sum(float(it.get("price", 0)) * int(it.get("qty", 1)) for it in items)
    tax = round(subtotal * tax_rate, 2)
    total = round(subtotal + tax, 2)
    checkout_counter.inc()
    from datetime import datetime, timezone
    return {
        "subtotal": round(subtotal, 2),
        "taxRate": tax_rate,
        "tax": tax,
        "total": total,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
