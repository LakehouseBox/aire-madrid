#!/usr/bin/env python3
"""Backfill obs.meteo_hourly from the city's hourly weather history (datos.madrid.es 300352, CC BY 4.0), 2019 on.

Same coded format as the air-quality history (magnitudes 81-89: wind speed and direction, temperature, humidity,
pressure, radiation, rain), so tools/history_rows.sql reads it. One CSV per month up to 2024, then one "desde 2025"
CSV up to last month; their resource names are opaque, so every CSV resource is read and the rows deduplicated.
Writes data/meteo_history.parquet; load it once:

    python3 tools/backfill_meteo_history.py
    lhbox duckdb --catalog aire_madrid -- -c "INSERT INTO aire_madrid.obs.meteo_hourly
        SELECT *, now() FROM 'data/meteo_history.parquet'"
"""
import argparse, json, os, sys

import duckdb

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from backfill_air_history import ROWS_SQL, get  # noqa: E402

PKG = "https://datos.madrid.es/api/3/action/package_show?id=300352-0-meteorologicos-horarios"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/meteo_history.parquet")
    a = ap.parse_args()
    os.makedirs("data/raw/meteo", exist_ok=True)
    res = [r for r in json.loads(get(PKG))["result"]["resources"] if (r.get("format") or "").upper() == "CSV"]
    con = duckdb.connect()
    first = True
    for i, r in enumerate(res):
        path = "data/raw/meteo/%03d.csv" % i
        if not os.path.exists(path):
            open(path, "wb").write(get(r["url"]))
        con.execute("SET VARIABLE src = ?", [path])
        try:
            con.execute(("CREATE TABLE meteo AS " if first else "INSERT INTO meteo ") +
                        "SELECT * FROM (%s) WHERE magnitude BETWEEN 80 AND 89" % ROWS_SQL)
            first = False
        except duckdb.Error as exc:  # a malformed month is reported, not fatal
            print("  skipped %s: %s" % (r.get("name"), str(exc)[:120]), file=sys.stderr)
            continue
        lo, hi = con.execute("SELECT min(hour_start_at)::DATE::VARCHAR, max(hour_start_at)::DATE::VARCHAR FROM meteo").fetchone()
        print("%3d/%d %-40s table spans %s .. %s" % (i + 1, len(res), r.get("name", "")[:40], lo, hi), flush=True)
    con.execute("CREATE TABLE dedup AS SELECT DISTINCT ON (station_code, magnitude, hour_start_at) * FROM meteo ORDER BY ALL")
    con.execute("UPDATE dedup SET source = 'madrid-meteo-history'")
    con.execute("COPY dedup TO '%s' (FORMAT parquet, COMPRESSION zstd)" % a.out)
    n, lo, hi = con.execute("SELECT count(*), min(hour_start_at)::VARCHAR, max(hour_start_at)::VARCHAR FROM dedup").fetchone()
    print("%s: %d rows, %s to %s" % (a.out, n, lo, hi))


if __name__ == "__main__":
    main()
