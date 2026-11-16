#!/usr/bin/env python3
"""The post's three charts, as SVG, from data/replay_load/forecasts.parquet (tools/replay_load.py writes it):
  docs/charts/idea.svg      the idea: knowledge that resets (a sawtooth) and knowledge that is kept (a ramp). Not data.
  docs/charts/reset.svg     measured: the extra error of the forecaster that forgets on the 1st of each month, by week of the month.
  docs/charts/ladder.svg    measured: how much less error than no memory, for each kind of memory (main question).
"""
import duckdb

INK, MUTED, GRID, BLUE, RED, PALE = "#1d2733", "#6b7785", "#e3e8ee", "#2f7fd0", "#d9534f", "#9cc3e8"
FONT = "font-family=\"Inter, system-ui, -apple-system, 'Segoe UI', sans-serif\""


def svg(w, h, body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" %s>\n<rect width="%d" height="%d" fill="#fff"/>\n%s\n</svg>\n'
            % (w, h, FONT, w, h, body))


def text(x, y, s, size=13, fill=INK, anchor="start", weight=400):
    return '<text x="%.1f" y="%.1f" font-size="%d" fill="%s" text-anchor="%s" font-weight="%d">%s</text>' % (x, y, size, fill, anchor, weight, s)


def idea():
    w, h, x0, y0, x1, y1 = 720, 360, 60, 300, 690, 40
    b = ['<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (x0, y0, x1, y0, INK),
         '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (x0, y0, x0, y1, INK),
         text(x1, y0 + 24, "time", 13, MUTED, "end"), text(x0 - 10, y1 + 4, "what the", 12, MUTED, "end"),
         text(x0 - 10, y1 + 20, "analysis", 12, MUTED, "end"), text(x0 - 10, y1 + 36, "knows", 12, MUTED, "end")]
    # sawtooth: learn slowly, then reset when the person or the project moves on
    pts, x = [], x0 + 10
    for k in range(4):
        pts += ["%d,%d" % (x, 250), "%d,%d" % (x + 130, 190 - 6 * k)]
        x += 150
        pts.append("%d,%d" % (x - 20, 190 - 6 * k))
        pts.append("%d,%d" % (x - 20, 250))
    b.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % (" ".join(pts[:-1]), RED))
    b.append('<path d="M%d 240 C %d 200, %d 120, %d 70" fill="none" stroke="%s" stroke-width="3.5"/>' % (x0 + 10, x0 + 220, x0 + 420, x1 - 10, BLUE))
    b += [text(x1 - 10, 60, "agents that keep their record in tables", 14, BLUE, "end", 600),
          text(x1 - 10, 78, "every run starts where the last one ended", 12, MUTED, "end"),
          text(x0 + 20, 276, "people and projects: each one learns, then the knowledge leaves with them", 13, RED, "start", 600)]
    return svg(w, h, "\n".join(b))


def reset(con):
    """The forecaster that forgets its record on the 1st of each month, against the same one keeping it, by week of the
    month: mean Brier difference and a 95% interval (bootstrap over the six months)."""
    import random
    from collections import defaultdict
    rows = con.execute("""SELECT arm, made_on, brier FROM 'data/replay_load/forecasts.parquet'
                          WHERE question = 'any_over_50' AND arm IN ('reset', 'record') AND made_on < DATE '2025-04-01'""").fetchall()
    b_ = defaultdict(dict)
    for a, d, v in rows:
        b_[a][d] = v
    stats = []
    for k in (1, 2, 3, 4):
        by_month = defaultdict(list)
        for d in b_["reset"]:
            if min((d.day - 1) // 7, 3) + 1 == k:
                by_month[(d.year, d.month)].append(b_["reset"][d] - b_["record"][d])
        months = list(by_month.values())
        flat = [x for m in months for x in m]
        random.seed(1)
        bs = sorted(sum(s) / len(s) for s in ([x for _ in months for x in random.choice(months)] for _ in range(4000)))
        stats.append((k, sum(flat) / len(flat), bs[100], bs[3900]))
    w, h, x0, y0, top = 720, 410, 90, 210, 70
    scale = (y0 - top) / 0.09
    b = [text(20, 30, "What forgetting costs: extra error after the record is wiped on the 1st", 15, INK, "start", 600),
         text(20, 50, "The same forecaster, record wiped monthly vs kept, by week of the month (95% interval)", 12, MUTED)]
    for v in (-0.06, -0.03, 0, 0.03, 0.06, 0.09):
        y = y0 - v * scale
        b.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="%s"/>' % (x0, y, w - 30, y, INK if v == 0 else GRID, 1.5 if v == 0 else 1))
        b.append(text(x0 - 8, y + 4, ("+%.2f" % v) if v > 0 else ("%.2f" % v), 11, MUTED, "end"))
    bw = (w - x0 - 30) / 4
    labels = {1: "week 1", 2: "week 2", 3: "week 3", 4: "rest of month"}
    for k, m, lo, hi in stats:
        cx = x0 + (k - 0.5) * bw
        y = y0 - max(m, 0) * scale
        b.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" rx="3"/>' % (cx - bw * 0.3, y, bw * 0.6, abs(m) * scale, RED if k == 1 else PALE))
        b.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.5"/>' % (cx, y0 - hi * scale, cx, y0 - lo * scale, INK))
        b.append(text(cx, y0 + 0.075 * scale + 18, labels[k], 13, INK, "middle", 600))
        b.append(text(cx, y0 + 0.075 * scale + 36, "%+.3f" % m, 12, MUTED, "middle"))
    b.append(text(20, 398, "Brier score difference (lower is better), Madrid, \"some station above 50 tomorrow\", Oct 2024 - Mar 2025.", 11, MUTED))
    return svg(w, h, "\n".join(b))


def ladder(con):
    r = dict(con.execute("""SELECT arm, avg(brier) FROM 'data/replay_load/forecasts.parquet'
                            WHERE question = 'any_over_50' GROUP BY arm""").fetchall())
    rows = [("fresh", "No memory"), ("memory", "Notes it rewrites daily"), ("reset", "Its record, forgotten monthly"),
            ("record", "Its record, kept"), ("history", "Its record + the city's tables")]
    w, h, x0, top, bh = 720, 300, 250, 60, 34
    base = r["fresh"]
    scale = (w - x0 - 90) / 0.2
    b = [text(20, 30, "Less error than no memory, by what the forecaster keeps", 15, INK, "start", 600)]
    for i, (k, label) in enumerate(rows):
        y = top + i * (bh + 12)
        gain = (base - r[k]) / base
        b.append(text(x0 - 12, y + bh / 2 + 5, label, 13, INK, "end"))
        b.append('<rect x="%d" y="%d" width="%.1f" height="%d" fill="%s" rx="3"/>' % (x0, y, max(gain, 0.002) * scale, bh, BLUE if k in ("record", "history") else PALE))
        b.append(text(x0 + max(gain, 0) * scale + 8, y + bh / 2 + 5, "%d%%  (Brier %.3f)" % (round(gain * 100), r[k]) if k != "fresh" else "baseline (Brier %.3f)" % r[k], 12, MUTED))
    b.append(text(20, 290, "Madrid, \"some station above 50 tomorrow\", 182 days, winter 2024-25, the same model throughout.", 11, MUTED))
    return svg(w, h, "\n".join(b))


if __name__ == "__main__":
    con = duckdb.connect()
    open("docs/charts/idea.svg", "w").write(idea())
    open("docs/charts/reset.svg", "w").write(reset(con))
    open("docs/charts/ladder.svg", "w").write(ladder(con))
    print("wrote docs/charts/{idea,reset,ladder}.svg")
