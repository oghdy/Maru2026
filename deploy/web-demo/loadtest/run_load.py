#!/usr/bin/env python3
"""MARU web demo load test (WEB-5.6.1). Python standard library only.

Simulates exhibition visitors against the demo hosts. Every request is either plain DB work or a
cache HIT. Nothing here should reach OpenAI or Gemini: the probe stops the run on the first TTS MISS
or slow Lab answer, and the load phase aborts on any TTS MISS.

Usage:
  python3 run_load.py --stages 10,30,50 --duration 90 --out results.json

Tokens are kept in memory only and are never printed or written.
"""
import argparse
import collections
import http.client
import json
import random
import ssl
import threading
import time
import urllib.parse

WEB_HOST = "proud-flow-production-2f97.up.railway.app"
API_HOST = "maru2026-production-1c60.up.railway.app"
ORIGIN = "https://" + WEB_HOST
ALLOWED_HOSTS = {WEB_HOST, API_HOST}  # the production API is deliberately not reachable from this script

TIMEOUT_S = 30
GUESTS_PER_MINUTE = 200  # server cap is 300; stay well under it
ROUNDS_PER_GUEST = 3
LAB_SLOW_MS = 2500  # a cache HIT is far faster than a Gemini call

# Present in the demo DB when it was copied from the local content (see LOG WEB-5.4.1)
TTS_TEXTS = ["가", "나", "하", "ㄱ", "ㄴ", "안녕하세요! 제 이름은 Sarah예요.", "민수: 안녕하세요?"]
LAB_REQUESTS = [
    {"inputText": "저는 밥을 먹어요", "category": "tense"},
    {"inputText": "저는 밥을 먹어요", "category": "politeness"},
    {"inputText": "매일 아침 커피를 마셔요", "category": "tense"},
]
DECK_IDS = [14, 15, 13]

SSL_CTX = ssl.create_default_context()


class Abort(Exception):
    pass


class Shared:
    def __init__(self):
        self.lock = threading.Lock()
        self.results = []  # (t, group, status, ms, bytes)
        self.abort_reason = None
        self.guests = 0
        self.guest_window_start = time.time()
        self.guest_window_count = 0
        self.stop = threading.Event()
        self.tts_miss = 0
        self.probe = []

    def record(self, group, status, ms, size):
        with self.lock:
            self.results.append((time.time(), group, status, ms, size))

    def abort(self, reason):
        with self.lock:
            if self.abort_reason is None:
                self.abort_reason = reason
        self.stop.set()

    def may_create_guest(self):
        with self.lock:
            now = time.time()
            if now - self.guest_window_start >= 60:
                self.guest_window_start = now
                self.guest_window_count = 0
            if self.guest_window_count >= GUESTS_PER_MINUTE:
                return False
            self.guest_window_count += 1
            return True


class Client:
    """One visitor's browser: a keep-alive connection per host and a preflight cache per URL."""

    def __init__(self, shared):
        self.shared = shared
        self.conns = {}
        self.token = None
        self.preflighted = set()

    def close(self):
        for c in self.conns.values():
            try:
                c.close()
            except Exception:
                pass
        self.conns = {}

    def _send(self, host, method, path, headers, body):
        if host not in ALLOWED_HOSTS:
            raise Abort("host not allowed: " + host)
        for attempt in (0, 1):
            conn = self.conns.get(host)
            if conn is None:
                conn = http.client.HTTPSConnection(host, timeout=TIMEOUT_S, context=SSL_CTX)
                self.conns[host] = conn
            try:
                conn.request(method, path, body=body, headers=headers)
                resp = conn.getresponse()
                data = resp.read()
                return resp, data
            except (http.client.RemoteDisconnected, http.client.CannotSendRequest, BrokenPipeError,
                    ConnectionResetError) as e:
                conn.close()
                self.conns.pop(host, None)
                if attempt == 1:
                    raise e
            except Exception:
                conn.close()
                self.conns.pop(host, None)
                raise

    def request(self, group, host, method, path, body=None, auth=True, accept_gzip=False):
        headers = {"User-Agent": "maru-web-demo-loadtest"}
        if accept_gzip:
            headers["Accept-Encoding"] = "gzip"
        if host == API_HOST:
            headers["Origin"] = ORIGIN
            if auth and self.token:
                headers["Authorization"] = "Bearer " + self.token
        if body is not None:
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
            headers["Content-Type"] = "application/json"
        t0 = time.perf_counter()
        try:
            resp, data = self._send(host, method, path, headers, body)
        except Exception as e:
            ms = (time.perf_counter() - t0) * 1000
            self.shared.record(group, "ERR:" + type(e).__name__, ms, 0)
            return None, None
        ms = (time.perf_counter() - t0) * 1000
        self.shared.record(group, resp.status, ms, len(data))
        return resp, data

    def api(self, group, method, path, body=None, auth=True):
        """Sends the browser's CORS preflight the first time this URL is used in the session."""
        key = (method, path)
        if key not in self.preflighted:
            self.preflighted.add(key)
            preflight_headers = "authorization,content-type" if body is not None else "authorization"
            t0 = time.perf_counter()
            try:
                resp, data = self._send(API_HOST, "OPTIONS", path, {
                    "Origin": ORIGIN,
                    "Access-Control-Request-Method": method,
                    "Access-Control-Request-Headers": preflight_headers,
                    "User-Agent": "maru-web-demo-loadtest",
                }, None)
                self.shared.record("preflight", resp.status, (time.perf_counter() - t0) * 1000, len(data))
            except Exception as e:
                self.shared.record("preflight", "ERR:" + type(e).__name__, (time.perf_counter() - t0) * 1000, 0)
        return self.request(group, API_HOST, method, path, body=body, auth=auth)

    def enter_as_guest(self):
        resp, data = self.api("guest", "POST", "/api/demo/guest", auth=False)
        if resp is None or resp.status != 200:
            return False
        self.token = json.loads(data)["data"]
        with self.shared.lock:
            self.shared.guests += 1
        return True


def tts_path(text):
    return "/api/tts?" + urllib.parse.urlencode({"text": text})


class RoundOver(Exception):
    """The stage ended while this visitor was between requests."""


def visitor_round(c, args, shared, stage_stop):
    def pause():
        if stage_stop.wait(random.uniform(args.think_min, args.think_max)) or shared.stop.is_set():
            raise RoundOver()

    deck = random.choice(DECK_IDS)

    # Home
    c.api("me", "GET", "/api/me")
    c.api("stats", "GET", "/api/me/stats")
    c.api("daily_review", "GET", "/api/v1/vocabulary/daily-review?limit=30")
    pause()

    # Lessons: the list response already carries the lesson content
    c.api("lessons_unit0", "GET", "/api/units/0/lessons")
    c.api("progress", "GET", "/api/progress/lessons?unitId=0")
    pause()
    c.api("lessons_unit1", "GET", "/api/units/1/lessons")
    c.api("progress", "GET", "/api/progress/lessons?unitId=1")
    pause()

    # Vocabulary
    c.api("decks", "GET", "/api/v1/vocabulary/decks?level=Beginner")
    c.api("deck_lessons", "GET", "/api/v1/vocabulary/decks/%d/lessons" % deck)
    pause()
    resp, data = c.api("due", "GET", "/api/v1/vocabulary/due?deckId=%d&lessonNumber=1&limit=30" % deck)
    if resp is not None and resp.status == 200:
        words = json.loads(data).get("data") or []
        if words:
            word = random.choice(words)
            word_id = word.get("wordId", word.get("id"))
            if word_id is not None:
                pause()
                c.api("review_write", "POST", "/api/v1/vocabulary/review",
                      body={"wordId": word_id, "rating": 3, "reviewMode": "LESSON"})
    c.api("game", "GET", "/api/v1/vocabulary/game/%d?lessonNumber=1" % deck)
    pause()

    # Sentence Lab cached examples
    c.api("lab_cached", "POST", "/api/lab/explore", body=random.choice(LAB_REQUESTS))
    pause()

    # Pronunciation button, cached sentence
    resp, _ = c.api("tts_cached", "GET", tts_path(random.choice(TTS_TEXTS)))
    if resp is not None and resp.status == 200:
        if resp.getheader("X-TTS-Cache") != "HIT":
            with shared.lock:
                shared.tts_miss += 1
            shared.abort("TTS MISS during the load phase")
    pause()


def visitor(args, shared, stage_stop, start_delay):
    if stage_stop.wait(start_delay):
        return
    while not stage_stop.is_set() and not shared.stop.is_set():
        c = Client(shared)
        try:
            # Landing and app bundle, once per visitor. The API part uses a fresh guest.
            c.request("static_landing", WEB_HOST, "GET", "/", accept_gzip=True)
            c.request("static_bootstrap", WEB_HOST, "GET", "/app/flutter_bootstrap.js", accept_gzip=True)
            c.request("static_main_js", WEB_HOST, "GET", "/app/main.dart.js", accept_gzip=True)
            while not shared.may_create_guest():
                if stage_stop.wait(1):
                    return
            if not c.enter_as_guest():
                if stage_stop.wait(2):
                    return
                continue
            for _ in range(ROUNDS_PER_GUEST):
                if stage_stop.is_set() or shared.stop.is_set():
                    break
                visitor_round(c, args, shared, stage_stop)
        except RoundOver:
            pass
        finally:
            c.close()


def watchdog(shared, stage_stop, max_error_rate, max_p95_ms):
    while not stage_stop.wait(5):
        with shared.lock:
            window = shared.results[-400:]
        if len(window) < 60:
            continue
        bad = [r for r in window if not is_ok(r[2])]
        rate = len(bad) / len(window)
        api_ms = sorted(r[3] for r in window if not r[1].startswith("static"))
        p95 = pct(api_ms, 95) if api_ms else 0
        if rate > max_error_rate:
            shared.abort("error rate %.1f%% over the last %d requests" % (rate * 100, len(window)))
            return
        if p95 > max_p95_ms:
            shared.abort("API p95 %.0f ms over the last %d requests" % (p95, len(window)))
            return


def is_ok(status):
    return isinstance(status, int) and 200 <= status < 400


def pct(sorted_values, p):
    if not sorted_values:
        return 0.0
    i = min(len(sorted_values) - 1, int(round(p / 100 * (len(sorted_values) - 1))))
    return sorted_values[i]


def summarize(rows):
    ms = sorted(r[3] for r in rows)
    statuses = collections.Counter(str(r[2]) for r in rows)
    ok = sum(1 for r in rows if is_ok(r[2]))
    return {
        "requests": len(rows),
        "ok_pct": round(ok / len(rows) * 100, 2) if rows else 0,
        "p50_ms": round(pct(ms, 50)),
        "p95_ms": round(pct(ms, 95)),
        "max_ms": round(ms[-1]) if ms else 0,
        "statuses": dict(statuses),
        "bytes": sum(r[4] for r in rows),
    }


def run_probe(shared):
    """One request per cached item, one at a time, before any load."""
    c = Client(shared)
    try:
        if not c.enter_as_guest():
            raise Abort("guest entry failed in the probe")
        for text in TTS_TEXTS:
            resp, data = c.api("probe_tts", "GET", tts_path(text))
            header = resp.getheader("X-TTS-Cache") if resp is not None else None
            shared.probe.append({"kind": "tts", "text": text, "status": resp.status if resp else None,
                                 "cache": header, "bytes": len(data) if data else 0})
            if resp is None or resp.status != 200 or header != "HIT":
                raise Abort("TTS probe was not a cache HIT, stopping: " + text)
        for body in LAB_REQUESTS:
            t0 = time.perf_counter()
            resp, data = c.api("probe_lab", "POST", "/api/lab/explore", body=body)
            ms = (time.perf_counter() - t0) * 1000
            shared.probe.append({"kind": "lab", "text": body["inputText"], "category": body["category"],
                                 "status": resp.status if resp else None, "ms": round(ms)})
            if resp is None or resp.status != 200 or ms > LAB_SLOW_MS:
                raise Abort("Lab probe looks like a cache MISS, stopping: %s/%s" % (body["inputText"], body["category"]))
    finally:
        c.close()


def run_stage(users, args, shared):
    stage_stop = threading.Event()
    started = len(shared.results)
    guests_before = shared.guests
    t0 = time.time()
    threads = []
    for _ in range(users):
        delay = random.uniform(0, args.ramp)
        t = threading.Thread(target=visitor, args=(args, shared, stage_stop, delay), daemon=True)
        t.start()
        threads.append(t)
    dog = threading.Thread(target=watchdog, args=(shared, stage_stop, args.max_error_rate, args.max_p95_ms), daemon=True)
    dog.start()
    deadline = t0 + args.duration
    while time.time() < deadline and not shared.stop.is_set():
        time.sleep(0.5)
    stage_stop.set()
    for t in threads:
        t.join(timeout=TIMEOUT_S + 5)
    elapsed = time.time() - t0
    rows = shared.results[started:]

    groups = collections.defaultdict(list)
    for r in rows:
        groups[r[1]].append(r)
    api_rows = [r for r in rows if not r[1].startswith("static")]
    bins = collections.defaultdict(list)
    for r in api_rows:
        bins[int((r[0] - t0) // 15) * 15].append(r[3])
    timeline = [{"t": k, "req_per_s": round(len(v) / 15, 1), "p50_ms": round(pct(sorted(v), 50)),
                 "p95_ms": round(pct(sorted(v), 95))} for k, v in sorted(bins.items())]
    return {
        "users": users,
        "elapsed_s": round(elapsed, 1),
        "guests_created": shared.guests - guests_before,
        "req_per_s": round(len(rows) / elapsed, 1),
        "all": summarize(rows),
        "api_only": summarize(api_rows),
        "groups": {k: summarize(v) for k, v in sorted(groups.items())},
        "timeline_api": timeline,
        "stopped_threads": sum(1 for t in threads if t.is_alive()),
    }


def print_stage(s):
    print("\n=== %d users, %.0fs, %.1f req/s, guests %d ===" % (s["users"], s["elapsed_s"], s["req_per_s"], s["guests_created"]))
    print("%-18s %7s %7s %7s %7s %8s  %s" % ("group", "n", "ok%", "p50", "p95", "max", "statuses"))
    for name, g in list(s["groups"].items()) + [("ALL API", s["api_only"]), ("ALL", s["all"])]:
        print("%-18s %7d %7.2f %7d %7d %8d  %s" % (name, g["requests"], g["ok_pct"], g["p50_ms"], g["p95_ms"], g["max_ms"], g["statuses"]))
    print("API over time: " + " | ".join("%ds %.1f/s p95 %d" % (b["t"], b["req_per_s"], b["p95_ms"]) for b in s["timeline_api"]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stages", default="10,30,50")
    ap.add_argument("--duration", type=int, default=90, help="seconds per stage")
    ap.add_argument("--ramp", type=float, default=10, help="seconds over which visitors arrive")
    ap.add_argument("--rest", type=int, default=15, help="seconds between stages")
    ap.add_argument("--think-min", type=float, default=0.5)
    ap.add_argument("--think-max", type=float, default=2.0)
    ap.add_argument("--max-error-rate", type=float, default=0.05)
    ap.add_argument("--stage-error-stop", type=float, default=0.02, help="do not go to the next stage above this")
    ap.add_argument("--max-p95-ms", type=float, default=15000)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    shared = Shared()
    report = {"started": time.strftime("%Y-%m-%d %H:%M:%S"), "args": vars(args), "stages": []}
    try:
        run_probe(shared)
    except Abort as e:
        report["abort"] = str(e)
    report["probe"] = shared.probe
    print("probe:", json.dumps(shared.probe, ensure_ascii=False))

    if "abort" not in report:
        stages = [int(x) for x in args.stages.split(",")]
        for i, users in enumerate(stages):
            s = run_stage(users, args, shared)
            report["stages"].append(s)
            print_stage(s)
            if shared.abort_reason:
                report["abort"] = shared.abort_reason
                break
            if 100 - s["api_only"]["ok_pct"] > args.stage_error_stop * 100:
                report["abort"] = "stage error rate above the limit, not going higher"
                break
            if i < len(stages) - 1:
                time.sleep(args.rest)

    report["guests_total"] = shared.guests
    report["tts_miss"] = shared.tts_miss
    report["finished"] = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=1)
    print("\nguests total:", shared.guests, "| tts miss:", shared.tts_miss, "| abort:", report.get("abort"))


if __name__ == "__main__":
    main()
