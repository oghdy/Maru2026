#!/usr/bin/env python3
"""MARU web demo short real-AI check (WEB-5.6.2). Python standard library only.

Spends real OpenAI money. Fixed plan, worst case 11 external calls:
  1 mission setup          1 call
  1 Help me Turtle         1 call (single call, nothing else running: baseline)
  3 chat turns at once     6 calls, plus at most 1 length retry per turn

The ledger file keeps the worst-case total across runs and the script refuses to go past the budget.
Tokens are kept in memory only and are never printed or written.

Usage:
  python3 run_ai_check.py --ledger ai_ledger.json --out ai_results.json
"""
import argparse
import http.client
import json
import os
import ssl
import threading
import time

API_HOST = "maru2026-production-1c60.up.railway.app"
ORIGIN = "https://proud-flow-production-2f97.up.railway.app"
BUDGET = 12
TIMEOUT_S = 70

SSL_CTX = ssl.create_default_context()


def load_spent(path):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)["worst_case_calls"]
    return 0


def save_spent(path, spent):
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"worst_case_calls": spent}, f)


class Ledger:
    def __init__(self, path):
        self.path = path
        self.spent = load_spent(path)
        self.lock = threading.Lock()

    def reserve(self, worst_case):
        with self.lock:
            if self.spent + worst_case > BUDGET:
                raise SystemExit("AI budget exceeded: spent %d, asking %d, budget %d" % (self.spent, worst_case, BUDGET))
            self.spent += worst_case
            save_spent(self.path, self.spent)


def post(path, body, token=None):
    headers = {"Origin": ORIGIN, "Content-Type": "application/json", "User-Agent": "maru-web-demo-loadtest"}
    if token:
        headers["Authorization"] = "Bearer " + token
    payload = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    conn = http.client.HTTPSConnection(API_HOST, timeout=TIMEOUT_S, context=SSL_CTX)
    t0 = time.perf_counter()
    try:
        conn.request("POST", path, body=payload, headers=headers)
        resp = conn.getresponse()
        data = resp.read()
        ms = round((time.perf_counter() - t0) * 1000)
        try:
            parsed = json.loads(data)
        except ValueError:
            parsed = None
        return resp.status, ms, parsed
    finally:
        conn.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ledger", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    ledger = Ledger(args.ledger)
    report = {"started": time.strftime("%Y-%m-%d %H:%M:%S"), "steps": []}

    status, ms, parsed = post("/api/demo/guest", None)
    if status != 200:
        raise SystemExit("guest entry failed: %s" % status)
    token = parsed["data"]
    report["guests_created"] = 1

    ledger.reserve(1)
    status, ms, parsed = post("/api/v1/mission-chat/setup", {
        "hierarchy": "👥 We're about the same age or rank (use neutral Korean)",
        "intimacy": "Stranger",
        "role": "Cafe staff",
        "personality": "Friendly",
        "difficulty": "easy",
    }, token)
    report["steps"].append({"step": "setup", "status": status, "ms": ms,
                            "message": parsed.get("message") if status != 200 and parsed else None})
    print("setup", status, ms)
    if status != 200:
        report["stopped"] = "setup failed"
        return finish(report, ledger, args.out)
    setup = parsed["data"]
    report["setup_json_chars"] = len(json.dumps(setup, ensure_ascii=False))
    history = [{"role": "assistant", "content": setup["persona"].get("firstMessage") or "안녕하세요. 뭐 드릴까요?"}]

    ledger.reserve(1)
    status, ms, parsed = post("/api/v1/mission-chat/suggestion", {"setup": setup, "conversationHistory": history}, token)
    report["steps"].append({"step": "suggestion_single", "status": status, "ms": ms,
                            "message": parsed.get("message") if status != 200 and parsed else None})
    print("suggestion", status, ms)
    if status != 200:
        report["stopped"] = "suggestion failed"
        return finish(report, ledger, args.out)

    # A turn is 2 calls, plus one retry when the rabbit's reply is too long
    messages = ["커피 한 잔 주세요.", "아메리카노 얼마예요?", "안녕하세요. 라떼 주세요."]
    ledger.reserve(3 * len(messages))
    results = [None] * len(messages)

    def turn(i, text):
        s, m, p = post("/api/v1/mission-chat/chat", {
            "userMessage": text,
            "conversationHistory": history + [{"role": "user", "content": text}],
            "setup": setup,
        }, token)
        results[i] = {"step": "turn_concurrent", "i": i, "status": s, "ms": m,
                      "reply_chars": len((p.get("data") or {}).get("rabbitReply") or "") if p else None,
                      "message": p.get("message") if s != 200 and p else None}

    t0 = time.perf_counter()
    threads = [threading.Thread(target=turn, args=(i, text)) for i, text in enumerate(messages)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    report["concurrent_wall_ms"] = round((time.perf_counter() - t0) * 1000)
    report["steps"].extend(results)
    for r in results:
        print("turn", r["i"], r["status"], r["ms"], "reply_chars", r["reply_chars"])
    finish(report, ledger, args.out)


def finish(report, ledger, out):
    report["worst_case_calls"] = ledger.spent
    report["finished"] = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=1)
    print("worst case calls so far:", ledger.spent, "| wall ms:", report.get("concurrent_wall_ms"))


if __name__ == "__main__":
    main()
