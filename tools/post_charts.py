#!/usr/bin/env python3
"""The post's diagrams and charts, as SVG in the site's palette, into docs/charts/:
  idea.svg     the idea: knowledge that resets (a sawtooth) and knowledge that is kept (a ramp). Not data.
  loop.svg     how it runs on LakehouseBox: the city's sources, one catalog, the hosted agent, its record.
  trend.svg    measured: days a year with some station above 50, 2010-2025 (from the catalog).
  reset.svg    measured: the extra error of the forecaster that forgets on the 1st of each month, by week of the month.
  ladder.svg   measured: how much less error than no memory, for each kind of memory (main question).
The two measured ones read data/replay_load/forecasts.parquet (tools/replay_load.py writes it).
"""
import random
from collections import defaultdict

import duckdb

INK, SOFT, MUTED, RULE = "#1a1917", "#4f4a44", "#77706a", "#e5ded4"
ACCENT, TINT, BLUE, LAKE, PALE, OK = "#e0471c", "#fdece3", "#4f98dc", "#e0f1f7", "#9cc3e8", "#3ca66a"
FONT = "font-family=\"Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif\""
MONO = "font-family=\"'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace\""


def svg(w, h, body):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" %s>\n%s\n</svg>\n' % (w, h, FONT, body)


def text(x, y, s, size=14, fill=INK, anchor="start", weight=400, extra=""):
    return ('<text x="%.1f" y="%.1f" font-size="%d" fill="%s" text-anchor="%s" font-weight="%d" %s>%s</text>'
            % (x, y, size, fill, anchor, weight, extra, s))


def box(x, y, w, h, fill="#fff", stroke=RULE, r=10, sw=1.5):
    return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%d" fill="%s" stroke="%s" stroke-width="%s"/>' % (x, y, w, h, r, fill, stroke, sw)


def arrow(x1, y1, x2, y2, color=SOFT, sw=2, dash=""):
    return ('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%s" %s marker-end="url(#a-%s)" stroke-linecap="round"/>'
            % (x1, y1, x2, y2, color, sw, ('stroke-dasharray="%s"' % dash) if dash else "", color.strip("#")))


def marker(color):
    return ('<marker id="a-%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            '<path d="M1 1 L9 5 L1 9" fill="none" stroke="%s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></marker>'
            % (color.strip("#"), color))


def idea():
    w, h, x0, y0, x1, y1 = 960, 500, 90, 410, 920, 60
    b = ['<defs>%s</defs>' % marker(INK),
         arrow(x0, y0, x1, y0, INK, 2), arrow(x0, y0, x0, y1, INK, 2),
         text(x1, y0 + 30, "time", 15, MUTED, "end"),
         text(x0 - 14, y1 + 20, "what the", 14, MUTED, "end"), text(x0 - 14, y1 + 38, "analysis", 14, MUTED, "end"),
         text(x0 - 14, y1 + 56, "knows", 14, MUTED, "end")]
    # the sawtooth: each person or project learns slowly, then the knowledge leaves with them
    d, x = "M%d 330" % (x0 + 20), x0 + 20
    drops = []
    for k in range(4):
        top = 250 - 4 * k
        d += " Q %d 328, %d %d" % (x + 110, x + 170, top)
        if k < 3:
            d += " L %d 330" % (x + 170)
            drops.append((x + 170, top))
        x += 200
    b.append('<path d="%s" fill="none" stroke="%s" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>' % (d, SOFT))
    for dx, top in drops:
        b.append('<circle cx="%d" cy="%d" r="5" fill="#fff" stroke="%s" stroke-width="2.5"/>' % (dx, top, SOFT))
    b.append(text(drops[0][0] + 12, drops[0][1] - 10, "someone moves on", 13, MUTED))
    # the ramp
    b.append('<path d="M%d 318 C %d 300, %d 190, %d 92" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>'
             % (x0 + 20, x0 + 330, x0 + 560, x1 - 40, ACCENT))
    b += [text(x1 - 40, 70, "Agents that keep what they learn in tables", 18, ACCENT, "end", 700),
          text(x1 - 250, 150, "every run starts where the last one ended", 14, ACCENT, "end"),
          text(x0 + 24, 372, "People and projects", 18, SOFT, "start", 700),
          text(x0 + 24, 394, "each one learns, then the knowledge leaves with them", 14, MUTED)]
    return svg(w, h, "\n".join(b))


def loop():
    w, h = 960, 560
    b = ['<defs>%s%s</defs>' % (marker(SOFT), marker(ACCENT))]
    # the city
    b += [box(20, 90, 200, 330, "#fff"), text(40, 120, "The city", 16, INK, "start", 700),
          text(40, 140, "open data, live", 12, MUTED)]
    for i, (a, s) in enumerate((("Air quality", "every station, hourly"), ("Weather", "the city's own stations"),
                                 ("Traffic", "every 5 minutes"), ("Forecast", "tomorrow's weather"))):
        y = 160 + i * 62
        b += [box(36, y, 168, 50, LAKE, "none", 8), text(48, y + 21, a, 14, INK, "start", 600), text(48, y + 39, s, 12, SOFT)]
    # the catalog
    b += [box(290, 40, 380, 462, "#fff", INK, 14, 2), text(310, 72, "On LakehouseBox", 17, INK, "start", 700),
          text(310, 92, "Apache Iceberg tables, and the agent's own record", 12, MUTED)]
    groups = (("What happened", LAKE, ("obs.air_hourly  ·  20.8M rows, from 2010", "obs.meteo_hourly  ·  since 2019",
                                       "now.daily_city  ·  each day under every rule")),
              ("What the agent said", TINT, ("agent.predictions  ·  one row per question",)),
              ("How it did", TINT, ("now.scored_predictions  ·  with the outcome",)),
              ("What it noted and did", "#f5efe7", ("its memory  ·  open decisions, notes", "its runs  ·  every query and step")))
    y = 112
    for title, fill, rows in groups:
        hh = 34 + 24 * len(rows)
        b += [box(308, y, 344, hh, fill, "none", 8), text(322, y + 22, title, 13, INK, "start", 700)]
        for j, r in enumerate(rows):
            b.append(text(322, y + 44 + 24 * j, r, 12, SOFT, "start", 400, MONO))
        y += hh + 12
    # the agent
    b += [box(740, 90, 200, 250, "#fff", ACCENT, 12, 2), text(760, 120, "Hosted agent", 16, INK, "start", 700),
          text(760, 140, "every day at 12:00", 12, MUTED)]
    for i, s in enumerate(("1  reads its record", "2  reads today and", "   tomorrow's weather", "3  writes its forecast",
                           "4  notes what only", "   it can know")):
        b.append(text(760, 172 + i * 24, s, 13, SOFT))
    # readers
    b += [box(740, 380, 200, 140, "#fff"), text(760, 410, "Anyone, with SQL", 16, INK, "start", 700),
          text(760, 434, "a person, another agent,", 13, SOFT), text(760, 454, "a page that reads the", 13, SOFT),
          text(760, 474, "catalog in the browser", 13, SOFT)]
    b += [arrow(222, 255, 286, 255, SOFT), text(254, 244, "scheduled", 11, MUTED, "middle"), text(254, 278, "SQL", 11, MUTED, "middle"),
          arrow(672, 170, 736, 170, ACCENT), text(704, 160, "reads", 11, ACCENT, "middle"),
          arrow(736, 262, 672, 262, ACCENT), text(704, 252, "writes", 11, ACCENT, "middle"),
          arrow(672, 450, 736, 450, SOFT), text(704, 440, "reads", 11, MUTED, "middle")]
    b.append(text(480, 548, "The next day the stations' readings score the forecast, and the score is one more row the agent reads.", 13, MUTED, "middle"))
    return svg(w, h, "\n".join(b))


def reset(con):
    """The forecaster that forgets its record on the 1st of each month, against the same one keeping it, by week of the
    month: mean Brier difference and a 95% interval (bootstrap over the six months)."""
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
    w, h, x0, y0, top = 960, 530, 110, 270, 100
    scale = (y0 - top) / 0.09
    b = [text(20, 34, "What forgetting costs", 22, INK, "start", 700),
         text(20, 60, "Extra error of the forecaster whose record is wiped on the 1st, against the one that keeps it", 14, MUTED)]
    for v in (-0.06, -0.03, 0, 0.03, 0.06, 0.09):
        y = y0 - v * scale
        b.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="%s"/>' % (x0, y, w - 30, y, INK if v == 0 else RULE, 2 if v == 0 else 1))
        b.append(text(x0 - 10, y + 5, ("+%.2f" % v) if v > 0 else ("%.2f" % v), 13, MUTED, "end"))
    bw = (w - x0 - 30) / 4
    labels = {1: ("Week 1", "starts from nothing"), 2: ("Week 2", "catching up"), 3: ("Week 3", "level again"),
              4: ("Rest of the month", "a short record is enough")}
    for k, m, lo, hi in stats:
        cx = x0 + (k - 0.5) * bw
        y = y0 - max(m, 0) * scale
        b.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" rx="4"/>' % (cx - bw * 0.28, y, bw * 0.56, abs(m) * scale, ACCENT if k == 1 else PALE))
        b.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2" stroke-linecap="round"/>' % (cx, y0 - hi * scale, cx, y0 - lo * scale, INK))
        ly = y0 + 0.075 * scale + 30
        b += [text(cx, ly, labels[k][0], 16, INK, "middle", 700), text(cx, ly + 22, "%+.3f" % m, 14, SOFT, "middle", 400, MONO),
              text(cx, ly + 44, labels[k][1], 13, MUTED, "middle")]
    b.append(text(20, 518, "Brier score difference, lower is better; line: 95% interval. Madrid, \"will some station exceed 50 tomorrow?\", Oct 2024 to Mar 2025.", 12, MUTED))
    return svg(w, h, "\n".join(b))


def ladder(con):
    r = dict(con.execute("""SELECT arm, avg(brier) FROM 'data/replay_load/forecasts.parquet'
                            WHERE question = 'any_over_50' GROUP BY arm""").fetchall())
    rows = [("fresh", "No memory", "every day from zero"), ("memory", "Notes", "lessons it rewrites daily"),
            ("reset", "Its record, wiped monthly", "the person or project changes"),
            ("record", "Its record, kept", "a query over its own scored forecasts"),
            ("history", "Its record + the city's tables", "three years of days like tomorrow")]
    w, h, x0, top, bh = 960, 470, 330, 90, 46
    base = r["fresh"]
    scale = (w - x0 - 150) / 0.2
    b = [text(20, 34, "The more it can query, the less it gets wrong", 22, INK, "start", 700),
         text(20, 60, "Error removed, compared with the same model with no memory", 14, MUTED)]
    for i, (k, label, sub) in enumerate(rows):
        y = top + i * (bh + 22)
        gain = (base - r[k]) / base
        b += [text(x0 - 16, y + 20, label, 16, INK, "end", 600), text(x0 - 16, y + 40, sub, 12, MUTED, "end")]
        b.append('<rect x="%d" y="%d" width="%.1f" height="%d" fill="%s" rx="5"/>'
                 % (x0, y, max(gain * scale, 4), bh, ACCENT if k == "history" else (BLUE if k == "record" else (RULE if k == "fresh" else PALE))))
        b.append(text(x0 + max(gain * scale, 4) + 12, y + 30, ("%d%% less error" % round(gain * 100)) if k != "fresh" else "the baseline", 15,
                      INK if k != "fresh" else MUTED, "start", 700 if k in ("history", "record") else 400))
    b.append(text(20, 458, "Brier score. Madrid, \"will some station exceed 50 tomorrow?\", 182 days, winter 2024-25, the same model throughout.", 12, MUTED))
    return svg(w, h, "\n".join(b))


# Days in each year with some station's daily NO2 mean above 50 µg/m³, from the catalog (2026-11-17):
#   SELECT year(day), count(*) FILTER (WHERE stations_over_eu2030_day > 0) FROM aire_madrid.now.daily_city GROUP BY 1
YEARS = {2010: 309, 2011: 299, 2012: 246, 2013: 210, 2014: 221, 2015: 251, 2016: 257, 2017: 282, 2018: 247, 2019: 201,
         2020: 129, 2021: 102, 2022: 101, 2023: 105, 2024: 69, 2025: 54}


def trend():
    w, h, x0, y0, top = 960, 480, 70, 380, 110
    scale = (y0 - top) / 320
    bw = (w - x0 - 30) / len(YEARS)
    b = [text(20, 34, "Madrid's air keeps getting cleaner", 22, INK, "start", 700),
         text(20, 60, "Days in the year when some station averaged more than 50 µg/m³ of NO2", 14, MUTED)]
    for v in (0, 100, 200, 300):
        y = y0 - v * scale
        b.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="%s"/>' % (x0, y, w - 30, y, INK if v == 0 else RULE, 2 if v == 0 else 1))
        b.append(text(x0 - 10, y + 5, str(v), 13, MUTED, "end"))
    for i, (yr, v) in enumerate(YEARS.items()):
        x = x0 + i * bw + 6
        b.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" rx="3"/>' % (x, y0 - v * scale, bw - 12, v * scale, BLUE if yr >= 2022 else PALE))
        b.append(text(x + (bw - 12) / 2, y0 + 22, "%02d" % (yr % 100) if yr not in (2010, 2025) else str(yr), 12, MUTED if yr not in (2010, 2025) else INK, "middle", 400 if yr not in (2010, 2025) else 700))
        if yr in (2010, 2019, 2022, 2025):
            b.append(text(x + (bw - 12) / 2, y0 - v * scale - 8, str(v), 14, INK, "middle", 700))
    ylim = y0 - 18 * scale
    b.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="2" stroke-dasharray="6 5"/>' % (x0, ylim, w - 30, ylim, ACCENT))
    b.append(text(x0 + 10, ylim - 9, "the EU's limit from 2030: 18 days a year", 14, ACCENT, "start", 700,
                  'paint-order="stroke" stroke="#fff" stroke-width="5" stroke-linejoin="round"'))
    x22 = x0 + 12 * bw
    b.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.5" stroke-dasharray="3 4"/>' % (x22, top + 10, x22, y0 - 108 * scale, SOFT))
    b.append(text(x22 + 8, top + 24, "since 2022, every station", 13, SOFT, "start", 600))
    b.append(text(x22 + 8, top + 42, "meets today's EU limits", 13, SOFT, "start", 600))
    b.append(text(20, 468, "Madrid's air quality network, daily mean per station. Computed from the city's open data in the catalog.", 12, MUTED))
    return svg(w, h, "\n".join(b))


if __name__ == "__main__":
    con = duckdb.connect()
    for name, s in (("idea", idea()), ("loop", loop()), ("trend", trend()), ("reset", reset(con)), ("ladder", ladder(con))):
        open("docs/charts/%s.svg" % name, "w").write(s)
    print("wrote docs/charts/{idea,loop,trend,reset,ladder}.svg")
