#!/usr/bin/env python3
"""Load replay results (tools/replay.py output folders) into agent.replay_forecasts and agent.replay_memory.

    python3 tools/replay_load.py --replay "winter 2024-25" data/replay_2425 data/replay_2425_record
writes data/replay_load/*.parquet and prints the lhbox command that replaces that replay's rows in the catalog.
Also prints the score table: mean Brier per arm and question, overall and by month.
"""
import argparse, json, os, subprocess, sys

import duckdb


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--replay", required=True)
    ap.add_argument("dirs", nargs="+")
    ap.add_argument("--load", action="store_true", help="run the lhbox command too")
    a = ap.parse_args()
    fc, mem = [], []
    for d in a.dirs:
        for l in open(os.path.join(d, "forecasts.jsonl")):
            r = json.loads(l)
            for q, p in r["forecast"].items():
                if q == "worst_daily_mean":
                    continue
                fc.append((a.replay, r["arm"], r["made_on"], r["target_day"], q, p, r["outcome"][q], r["brier"][q],
                           r["forecast"].get("worst_daily_mean"), r["outcome"].get("worst_daily_mean"), r.get("rationale")))
        mp = os.path.join(d, "memory.jsonl")
        if os.path.exists(mp):
            for l in open(mp):
                m = json.loads(l)
                mem.append((a.replay, m["day"], json.dumps(m["lessons"], ensure_ascii=False), m.get("note")))
    con = duckdb.connect()
    con.execute("""CREATE TABLE f (replay VARCHAR, arm VARCHAR, made_on DATE, target_day DATE, question VARCHAR,
                   probability DOUBLE, outcome INTEGER, brier DOUBLE, expected_worst_mean DOUBLE,
                   observed_worst_mean DOUBLE, rationale VARCHAR)""")
    con.executemany("INSERT INTO f VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                    [r[:8] + (float(r[8]) if isinstance(r[8], (int, float)) else None,) + r[9:] for r in fc])
    con.execute("CREATE TABLE m (replay VARCHAR, day DATE, lessons VARCHAR, note VARCHAR)")
    if mem:
        con.executemany("INSERT INTO m VALUES (?,?,?,?)", mem)
    os.makedirs("data/replay_load", exist_ok=True)
    con.execute("COPY f TO 'data/replay_load/forecasts.parquet' (FORMAT parquet)")
    con.execute("COPY m TO 'data/replay_load/memory.parquet' (FORMAT parquet)")
    print(con.sql("""SELECT question, arm, count(*) AS days, round(avg(probability), 2) AS said, round(avg(outcome), 2) AS happened,
                            round(avg(brier), 4) AS brier
                     FROM f GROUP BY ALL ORDER BY question, brier"""))
    print(con.sql("""PIVOT (SELECT arm, strftime(target_day, '%Y-%m') AS month, brier FROM f WHERE question = 'any_over_50')
                     ON arm USING round(avg(brier), 3) GROUP BY month ORDER BY month"""))
    sql = ("DELETE FROM aire_madrid.agent.replay_forecasts WHERE replay = '{r}'; "
           "DELETE FROM aire_madrid.agent.replay_memory WHERE replay = '{r}'; "
           "INSERT INTO aire_madrid.agent.replay_forecasts SELECT * FROM 'data/replay_load/forecasts.parquet'; "
           "INSERT INTO aire_madrid.agent.replay_memory SELECT * FROM 'data/replay_load/memory.parquet';"
           ).format(r=a.replay.replace("'", "''"))
    cmd = ["lhbox", "duckdb", "--catalog", "aire_madrid", "--", "-c", sql]
    print(" ".join(cmd[:5]), "-- -c", json.dumps(sql))
    if a.load:
        sys.exit(subprocess.run(cmd).returncode)


if __name__ == "__main__":
    main()
