#!/usr/bin/env python3
"""Check availability of Lichess bot accounts used in ChessPals.

Usage:
    python tools/check_bots.py              # human-readable output
    python tools/check_bots.py --json       # JSON output (for CI)
    python tools/check_bots.py --ci         # exits non-zero if any bot is problematic
"""

import json
import sys
import urllib.request
from datetime import datetime, timezone

BOTS = [
    {"name": "Bella the Bee", "username": "grandQ_AI", "fallback": "SF 1"},
    {"name": "Flutter the Butterfly", "username": "larryz-alterego", "fallback": "SF 1"},
    {"name": "Zip the Hummingbird", "username": "uSunfish-l0", "fallback": "SF 1"},
    {"name": "Rosie the Rabbit", "username": "EdwardKillick", "fallback": "SF 1"},
    {"name": "Kira the Kangaroo", "username": "bernstein-2ply", "fallback": "SF 2"},
    {"name": "Dino the Deer", "username": "sargon-1ply", "fallback": "SF 2"},
    {"name": "Gabi the Giraffe", "username": "Humaia", "fallback": "SF 2"},
    {"name": "Tara the Tiger", "username": "bernstein-4ply", "fallback": "SF 3"},
]

STALE_DAYS = 30


def check_bot(username: str) -> dict:
    url = f"https://lichess.org/api/user/{username}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return {"exists": False, "online": False, "seen": None, "disabled": False}
        raise

    seen_at = data.get("seenAt")
    seen_dt = None
    days_ago = None
    if seen_at:
        seen_dt = datetime.fromtimestamp(seen_at / 1000, tz=timezone.utc)
        days_ago = (datetime.now(timezone.utc) - seen_dt).days

    return {
        "exists": True,
        "online": data.get("online", False),
        "seen": seen_dt.isoformat() if seen_dt else None,
        "days_ago": days_ago,
        "disabled": data.get("disabled", False),
        "tosViolation": data.get("tosViolation", False),
    }


def main():
    ci_mode = "--ci" in sys.argv
    json_mode = "--json" in sys.argv
    results = []
    problems = []

    for bot in BOTS:
        info = check_bot(bot["username"])
        status = "OK"
        problem = None

        if not info["exists"]:
            status = "GONE"
            problem = f"{bot['name']} ({bot['username']}) — account no longer exists"
        elif info.get("disabled") or info.get("tosViolation"):
            status = "BANNED"
            problem = f"{bot['name']} ({bot['username']}) — account disabled/TOS violation"
        elif info["days_ago"] is not None and info["days_ago"] > STALE_DAYS:
            status = "STALE"
            problem = f"{bot['name']} ({bot['username']}) — last seen {info['days_ago']} days ago"

        if problem:
            problems.append(problem)

        results.append({
            **bot,
            **info,
            "status": status,
        })

    if json_mode:
        print(json.dumps(results, indent=2, default=str))
    else:
        print(f"{'Character':<25} {'Username':<20} {'Status':<8} {'Online':<8} {'Last seen':<15} {'Fallback'}")
        print("-" * 100)
        for r in results:
            online = "yes" if r.get("online") else "no"
            seen = f"{r['days_ago']}d ago" if r.get("days_ago") is not None else "unknown"
            if not r["exists"]:
                online = "-"
                seen = "-"
            print(f"{r['name']:<25} {r['username']:<20} {r['status']:<8} {online:<8} {seen:<15} {r['fallback']}")

        print()
        if problems:
            print(f"PROBLEMS ({len(problems)}):")
            for p in problems:
                print(f"  - {p}")
        else:
            print("All bots healthy.")

    if ci_mode and problems:
        sys.exit(1)


if __name__ == "__main__":
    main()
