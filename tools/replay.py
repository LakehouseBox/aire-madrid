#!/usr/bin/env python3
"""Replay a past winter day by day: does a forecaster that keeps a notebook of its own mistakes get better?

Every simulated day D, at "noon", three forecasters predict tomorrow (D+1) from what was known then:
  - persistence: no model; tomorrow's chance is how often, over the last 28 days, a day like yesterday was followed by
    an event (a fixed rule, the floor to beat);
  - fresh:  the model, the same brief every day, no memory;
  - memory: the model, the same brief plus its own notebook of lessons and its recent scorecard. Each day it first
    sees how its forecast for yesterday turned out (made two days ago, as the live agent closes them) and rewrites
    the notebook.
The questions: some station's daily NO2 mean above 50 (EU 2030 daily limit), five or more stations above 50 (a
widespread episode), and the 12 background stations' mean above 60 (the parking surcharge). Brier score each.

Honest limits, written into the results: the weather for tomorrow is what was measured (a perfect forecast); the
year is hidden from the model, but the month and weekday are not.

  python3 tools/replay.py --days data/replay_days.parquet --out data/replay --from 2024-10-01 --to 2025-03-31
The model and its key are the agent service's (DeepSeek-V4-Flash on Scaleway): LHBOX_REPLAY_BASE_URL, _KEY.
"""
import argparse, concurrent.futures as cf, datetime as dt, json, os, re, sys, time, urllib.request

import duckdb, holidays

MODEL = "deepseek-v4-flash-0731"
QUESTIONS = {
    "any_over_50": "some station's daily NO2 mean above 50 µg/m³ (EU 2030 daily limit)",
    "five_over_50": "five or more stations with a daily NO2 mean above 50 µg/m³ (a widespread episode)",
    "ser_over_60": "the mean of the 12 background stations above 60 µg/m³ (raises parking prices the day after)",
}
SYSTEM = """You forecast nitrogen dioxide (NO2) in Madrid. It is noon; you forecast TOMORROW (a whole Madrid day, \
midnight to midnight). You are scored with the Brier score the day after, so give calibrated probabilities: of all \
the times you say 0.3, it should happen about 3 in 10.

What drives NO2 in a Madrid winter: traffic (lower on weekends, holidays and in the Christmas period), and \
above all the weather. Calm wind, no rain, clear cold nights (strong inversions, a big gap between the maximum and \
minimum temperature) and high pressure (a stable anticyclone) let NO2 build up day after day; wind above ~3 m/s or \
rain clears it. Persistence is a strong baseline: tomorrow tends to look like today unless the weather changes.

Answer with JSON only:
{"any_over_50": p, "five_over_50": p, "ser_over_60": p, "worst_daily_mean": µg/m³, "rationale": "one or two sentences"}
where p is a probability between 0 and 1."""
REFLECT = """You are the same forecaster, reviewing your record. Below: your notebook of lessons, the forecast you \
made two days ago for yesterday, what yesterday's brief said, and what happened. Rewrite the notebook: keep the \
lessons that still hold, correct or drop the ones this case contradicts, and add one only if this case teaches \
something specific and reusable (a condition and what it does to NO2, or a bias of yours to correct, e.g. "after \
two calm days with tmin below 2 °C, any_over_50 has been yes: say ≥0.8"). At most 12 lessons, each one sentence. \
Answer with JSON only: {"lessons": ["...", ...], "note": "what you changed and why, one sentence"}"""


def call(base, key, system, user, tries=6):
    body = {"model": MODEL, "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            "max_tokens": 16000, "temperature": 0.3, "response_format": {"type": "json_object"}}
    for i in range(tries):
        try:
            req = urllib.request.Request(base + "/chat/completions", data=json.dumps(body).encode(),
                                         headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=240) as r:
                d = json.load(r)
            ch = d["choices"][0]
            txt = ch["message"].get("content") or ""
            m = re.search(r"\{.*\}", txt, re.S)
            if not m:   # say why: a reasoning model that spends max_tokens thinking answers no content
                raise ValueError("no JSON (finish_reason %s, %d content chars, usage %s)"
                                 % (ch.get("finish_reason"), len(txt), d.get("usage", {}).get("completion_tokens")))
            return json.loads(m.group(0)), d.get("usage", {})
        except Exception as exc:
            print("  model retry %d: %s" % (i + 1, str(exc)[:120]), file=sys.stderr)
            time.sleep(5 * (i + 1))
    raise RuntimeError("model failed")


def fmt_day(r):
    return ("%s: worst station daily mean %s, stations over 50: %s, background mean %s; wind %s m/s, rain %s mm, "
            "temp %s..%s °C, pressure %s mb" % (r["weekday"][:3], r["worst_daily_mean"], r["stations_over_eu2030_day"],
                                                r["ser_background_mean"], r["wind_ms"], r["rain_mm"], r["temp_min_c"],
                                                r["temp_max_c"], r["pressure_mb"]))


def brief(days, d, hol):
    t = d + dt.timedelta(days=1)
    lines = ["Recent days (oldest first):"]
    for k in range(7, 0, -1):
        x = d - dt.timedelta(days=k)
        if x in days:
            lines.append("- %d days ago, %s" % (k, fmt_day(days[x])))
    r = days[d]
    lines += ["", "Today (%s %s), this morning 00:00-11:59: highest hourly NO2 %s; background stations' mean %s; "
              "07-10h mean %s; highest hour by protocol zone: %s; wind this morning %s m/s."
              % (r["weekday"], d.strftime("%d %B"), r["morning_max_hour"], r["morning_background_mean"],
                 r["morning_rush_mean"], r["morning_zone_max"], r["morning_wind_ms"])]
    w = days[t]
    lines += ["", "Tomorrow: %s %s%s. Weather forecast for tomorrow: wind %s m/s, rain %s mm, temperature %s..%s °C, "
              "pressure %s mb." % (w["weekday"], t.strftime("%d %B"), (", holiday: " + hol[t]) if t in hol else "",
                                   w["wind_ms"], w["rain_mm"], w["temp_min_c"], w["temp_max_c"], w["pressure_mb"])]
    return "\n".join(lines)


def outcome(r):
    return {"any_over_50": int(r["stations_over_eu2030_day"] > 0), "five_over_50": int(r["stations_over_eu2030_day"] >= 5),
            "ser_over_60": int((r["ser_background_mean"] or 0) > 60), "worst_daily_mean": r["worst_daily_mean"]}


def persistence(days, d):
    """P(event tomorrow | yesterday's status), from the 28 transitions before today (yesterday is the last full day)."""
    y = d - dt.timedelta(days=1)
    out = {}
    for q in QUESTIONS:
        same = [outcome(days[x + dt.timedelta(days=1)])[q] for k in range(2, 30)
                for x in [d - dt.timedelta(days=k)] if x in days and x + dt.timedelta(days=1) in days
                and outcome(days[x])[q] == outcome(days[y])[q]]
        out[q] = round((sum(same) + 0.5) / (len(same) + 1), 3)   # a little smoothing for empty or one-sided counts
    out["worst_daily_mean"] = days[y]["worst_daily_mean"]
    return out


def scorecard(rows, known_until):
    """The last 30 forecasts whose day is over by noon of the run (target_day <= yesterday): no peeking."""
    recent = [r for r in rows if r["target_day"] <= str(known_until)][-30:]
    if not recent:
        return "No scored forecasts yet."
    lines = ["Your last %d scored forecasts:" % len(recent)]
    for q in QUESTIONS:
        ps = [r["forecast"][q] for r in recent]
        os_ = [r["outcome"][q] for r in recent]
        b = sum((p - o) ** 2 for p, o in zip(ps, os_)) / len(ps)
        lines.append("- %s: mean Brier %.3f; you said %.2f on average, it happened %.2f of the days"
                     % (q, b, sum(ps) / len(ps), sum(os_) / len(os_)))
    return "\n".join(lines)


def is_off(d, hol):
    return d.weekday() >= 5 or d in hol


def record_view(rows, days, hol, t, known_until):
    """What the record arm sees: its own scored forecasts, as a table query would return them. No model call."""
    known = [r for r in rows if r["target_day"] <= str(known_until)]
    if len(known) < 7:
        return "Your record: fewer than 7 scored forecasts so far."
    out = ["Your record, computed from the table of your own past forecasts and what happened (%d scored days):" % len(known)]
    last = known[-60:]
    for q in QUESTIONS:
        ps, os_ = [r["forecast"][q] for r in last], [r["outcome"][q] for r in last]
        out.append("- %s, last %d days: you said %.2f on average, it happened %.2f; mean Brier %.3f"
                   % (q, len(last), sum(ps) / len(ps), sum(os_) / len(os_), sum((p - o) ** 2 for p, o in zip(ps, os_)) / len(ps)))
    out.append("When you said ... it happened (all scored days):")
    for q in ("any_over_50", "five_over_50"):
        cells = []
        for lo_, hi_ in ((0, .2), (.2, .4), (.4, .6), (.6, .8), (.8, 1.01)):
            b = [r for r in known if lo_ <= r["forecast"][q] < hi_]
            if b:
                cells.append("%.1f-%.1f: %d/%d" % (lo_, min(hi_, 1), sum(r["outcome"][q] for r in b), len(b)))
        out.append("- %s: %s" % (q, "; ".join(cells)))
    w = days[t]
    def dist(r):
        x = days[dt.date.fromisoformat(r["target_day"])]
        m = days[dt.date.fromisoformat(r["made_on"])]
        return (abs((x["wind_ms"] or 0) - (w["wind_ms"] or 0)) / 0.7
                + 1.5 * (((x["rain_mm"] or 0) > 0.5) != ((w["rain_mm"] or 0) > 0.5))
                + abs(((x["temp_max_c"] or 0) - (x["temp_min_c"] or 0)) - ((w["temp_max_c"] or 0) - (w["temp_min_c"] or 0))) / 4
                + 1.0 * (is_off(dt.date.fromisoformat(r["target_day"]), hol) != is_off(t, hol))
                + abs((m["morning_max_hour"] or 0) - (days[t - dt.timedelta(days=1)]["morning_max_hour"] or 0)) / 30)
    out.append("Your past days most like tomorrow (weather of the day, weekday/holiday, the morning before):")
    for r in sorted(known, key=dist)[:6]:
        x, td = days[dt.date.fromisoformat(r["target_day"])], dt.date.fromisoformat(r["target_day"])
        out.append("- %s %s: wind %s, rain %s, temp %s..%s | you said any_over_50 %.2f, five_over_50 %.2f | happened: "
                   "stations over 50: %s, worst mean %s"
                   % (x["weekday"][:3], td.strftime("%d %b"), x["wind_ms"], x["rain_mm"], x["temp_min_c"], x["temp_max_c"],
                      r["forecast"]["any_over_50"], r["forecast"]["five_over_50"], x["stations_over_eu2030_day"],
                      x["worst_daily_mean"]))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", default="data/replay_days.parquet")
    ap.add_argument("--out", default="data/replay")
    ap.add_argument("--from", dest="lo", default="2024-10-01")
    ap.add_argument("--to", dest="hi", default="2025-03-31")
    ap.add_argument("--arms", default="persistence,fresh,memory", help="any of persistence,fresh,memory,record")
    a = ap.parse_args()
    arms = set(a.arms.split(","))
    base, key = os.environ["LHBOX_REPLAY_BASE_URL"].rstrip("/"), os.environ["LHBOX_REPLAY_KEY"]
    con = duckdb.connect()
    cols = [c[0] for c in con.execute("DESCRIBE SELECT * FROM read_parquet(?)", [a.days]).fetchall()]
    days = {r[0]: dict(zip(cols, r)) for r in con.execute("SELECT * FROM read_parquet(?)", [a.days]).fetchall()}
    lo, hi = dt.date.fromisoformat(a.lo), dt.date.fromisoformat(a.hi)
    hol = dict(holidays.Spain(subdiv="MD", years=range(lo.year, hi.year + 2)))
    for y in range(lo.year, hi.year + 2):
        hol.setdefault(dt.date(y, 11, 9), "Almudena (Madrid city)")
        hol.setdefault(dt.date(y, 5, 15), "San Isidro (Madrid city)")
    os.makedirs(a.out, exist_ok=True)
    fpath, mpath = os.path.join(a.out, "forecasts.jsonl"), os.path.join(a.out, "memory.jsonl")
    done = set()
    rows = {"fresh": [], "memory": [], "persistence": [], "record": []}
    if os.path.exists(fpath):                                  # resume: keep what is there
        for l in open(fpath):
            r = json.loads(l); rows[r["arm"]].append(r); done.add((r["arm"], r["made_on"]))
    lessons = []
    if os.path.exists(mpath):
        for l in open(mpath):
            lessons = json.loads(l)["lessons"]
    ff, mf = open(fpath, "a"), open(mpath, "a")
    tokens = 0
    d = lo - dt.timedelta(days=1)
    while d < hi:
        d += dt.timedelta(days=1)
        t = d + dt.timedelta(days=1)
        if d not in days or t not in days:
            continue
        b = brief(days, d, hol)
        # Memory arm: first close the forecast made two days ago for yesterday (yesterday is now complete).
        y = d - dt.timedelta(days=1)
        prev = next((r for r in rows["memory"] if r["target_day"] == str(y)), None)
        if "memory" in arms and prev and ("memory", str(d)) not in done:
            happened = outcome(days[y])
            user = ("Notebook:\n%s\n\nYour forecast (made two days ago): %s\n\nThe brief you had:\n%s\n\nWhat happened: %s"
                    % ("\n".join("- " + s for s in lessons) or "(empty)", json.dumps(prev["forecast"]),
                       prev["brief"], json.dumps(happened)))
            res, u = call(base, key, REFLECT, user)
            tokens += u.get("total_tokens", 0)
            lessons = [str(s)[:300] for s in (res.get("lessons") or [])][:12]
            mf.write(json.dumps({"day": str(d), "lessons": lessons, "note": res.get("note")}) + "\n"); mf.flush()
        jobs = {}
        with cf.ThreadPoolExecutor(3) as ex:
            if "record" in arms and ("record", str(d)) not in done:
                jobs["record"] = ex.submit(call, base, key, SYSTEM,
                                           record_view(rows["record"], days, hol, t, y) + "\n\n" + b)
            if "fresh" in arms and ("fresh", str(d)) not in done:
                jobs["fresh"] = ex.submit(call, base, key, SYSTEM, b)
            if "memory" in arms and ("memory", str(d)) not in done:
                mem = ("Your notebook of lessons from earlier days:\n%s\n\n%s\n\n%s"
                       % ("\n".join("- " + s for s in lessons) or "(empty)", scorecard(rows["memory"], y), b))
                jobs["memory"] = ex.submit(call, base, key, SYSTEM, mem)
            got = {k: f.result() for k, f in jobs.items()}
        if "persistence" in arms and ("persistence", str(d)) not in done:
            got["persistence"] = (persistence(days, d), {})
        happened = outcome(days[t])
        for arm, (res, u) in got.items():
            tokens += u.get("total_tokens", 0)
            fc = {q: min(1.0, max(0.0, float(res.get(q, 0.5)))) for q in QUESTIONS}
            fc["worst_daily_mean"] = res.get("worst_daily_mean")
            r = {"arm": arm, "made_on": str(d), "target_day": str(t), "forecast": fc, "outcome": happened,
                 "brier": {q: round((fc[q] - happened[q]) ** 2, 4) for q in QUESTIONS},
                 "rationale": res.get("rationale"), "brief": b if arm != "persistence" else None,
                 "lessons_count": len(lessons) if arm == "memory" else None}
            rows[arm].append(r)
            ff.write(json.dumps(r) + "\n"); ff.flush()
        print("%s  any50 %s  %s  | lessons %d  tokens %d" % (t, happened["any_over_50"], "  ".join(
            "%s %.2f" % (k, v[0].get("any_over_50", -1)) for k, v in sorted(got.items())), len(lessons), tokens), flush=True)


if __name__ == "__main__":
    main()
