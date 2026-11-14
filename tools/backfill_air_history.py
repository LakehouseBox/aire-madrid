#!/usr/bin/env python3
"""Backfill obs.air_hourly from the city's hourly history (datos.madrid.es 201200, CC BY 4.0), 2010 to last month.

Writes data/air_history.parquet; load it once into the catalog (README, "Setting it up"):

    python3 tools/backfill_air_history.py --from-year 2010
    lhbox duckdb --catalog aire_madrid -- -c "INSERT INTO aire_madrid.obs.air_hourly
        SELECT *, now() FROM 'data/air_history.parquet'"

The portal (CKAN) is slow and sometimes hangs for a minute: every request is retried. The yearly zips have opaque
names, so each is mapped to its year by the files inside (ene_mo19.csv = January 2019). Needs `pip install duckdb`.
"""
import argparse, io, json, os, re, sys, time, urllib.request, zipfile

import duckdb

PKG = "https://datos.madrid.es/api/3/action/package_show?id=201200-0-calidad-aire-horario"
HERE = os.path.dirname(os.path.abspath(__file__))
ROWS_SQL = open(os.path.join(HERE, "history_rows.sql"), encoding="utf-8").read()
ROWS_SQL = "\n".join(l for l in ROWS_SQL.splitlines() if not l.startswith("--"))
UA = {"User-Agent": "aire-madrid-backfill (+https://github.com/lakehousebox/aire-madrid)"}


def get(url, tries=5):
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=180) as r:
                return r.read()
        except Exception as exc:  # the portal hangs, then answers on retry
            print("  retry %d after %s" % (i + 1, exc), file=sys.stderr)
            time.sleep(5 * (i + 1))
    raise SystemExit("could not fetch %s" % url)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--from-year", type=int, default=2010, help="first year (the network was reorganised in 2009-2010)")
    ap.add_argument("--out", default="data/air_history.parquet")
    a = ap.parse_args()
    os.makedirs("data/raw", exist_ok=True)
    res = json.loads(get(PKG))["result"]["resources"]
    con = duckdb.connect()
    first = True
    for r in res:
        fmt, url = (r.get("format") or "").upper(), r["url"]
        if fmt == "CSV":                                        # "desde 2025": one CSV up to last month
            path = "data/raw/since2025.csv"
            open(path, "wb").write(get(url))
            files = [path]
        elif fmt == "ZIP":
            z = zipfile.ZipFile(io.BytesIO(get(url)))
            names = [n for n in z.namelist() if n.lower().endswith(".csv")]
            years = {2000 + int(m.group(1)) for n in names for m in [re.search(r"_mo(\d\d)\.csv$", n, re.I)] if m}
            if not years or max(years) < a.from_year:
                continue
            files = []
            for n in names:
                p = os.path.join("data/raw", os.path.basename(n))
                open(p, "wb").write(z.read(n))
                files.append(p)
        else:
            continue
        for p in files:
            con.execute("SET VARIABLE src = ?", [p])
            q = "SELECT * FROM (%s) WHERE year(hour_start_at) >= %d" % (ROWS_SQL, a.from_year)
            con.execute(("CREATE TABLE air AS " if first else "INSERT INTO air ") + q)
            first = False
        print("%-45s %s" % (r.get("name", "")[:45], ", ".join(os.path.basename(p) for p in files[:2]) + (" …" if len(files) > 2 else "")))
    con.execute("CREATE TABLE dedup AS SELECT DISTINCT ON (station_code, magnitude, hour_start_at) * FROM air ORDER BY ALL")
    con.execute("COPY dedup TO '%s' (FORMAT parquet, COMPRESSION zstd)" % a.out)
    n, lo, hi = con.execute("SELECT count(*), min(hour_start_at)::VARCHAR, max(hour_start_at)::VARCHAR FROM dedup").fetchone()
    print("%s: %d rows, %s to %s" % (a.out, n, lo, hi))


if __name__ == "__main__":
    main()
