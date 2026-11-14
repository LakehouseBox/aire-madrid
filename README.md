# aire-madrid

**How would Madrid fare under the 2030 rules, and can an agent tell, the day before, when the city would have to
restrict traffic?**

Madrid has not activated its nitrogen dioxide (NO2) pollution protocol since December 2021, and in 2025 every station
met the EU limits in force. From 2030 the EU's limits get much stricter (Directive (EU) 2024/2881), and the WHO's
guidelines are stricter still. This project keeps Madrid's air, weather and traffic in one open Apache Iceberg catalog
on [LakehouseBox](https://lakehousebox.com), scores every day against every rule set, and runs an agent that forecasts
tomorrow at noon (the city's own deadline for announcing restrictions) and is scored the day after.

## What 2025 looks like under each rule set

From the city's own hourly data, computed by [`sql/now/compliance.sql`](sql/now/compliance.sql):

| Rule set | NO2 rule | Stations that pass (of 23) |
|---|---|---|
| EU, in force | hourly 200 µg/m³ at most 18 times; annual mean 40 | 23 / 23 |
| EU 2030 | daily mean 50 at most 18 days | 17 |
| EU 2030 | annual mean 20 | 6 |
| WHO 2021 | daily mean 25 at most 3-4 days | 0 |

In 2025 some station exceeded the 2030 daily limit on 54 days. Checks against what was published: the parking
surcharge rule (the 12 background stations above 70 µg/m³) fires for 16 January 2025 (background mean 70.4 on the
15th), the day the press reported it; the worst annual mean, 31.7 at Plaza Elíptica, matches the city's report (32).

Checked against the council's own record for 2017-2021: the protocol level computed from the measurements finds 28 of
the 29 days the council records one, and 10 more days where the numbers reached a level and the council, weighing the
weather, did not act ([`docs/research/protocol-check.md`](docs/research/protocol-check.md)). Those are the days an
agent has to learn.

## The agent

`aire_forecaster` ([`agent/forecaster.md`](agent/forecaster.md)) is a LakehouseBox hosted agent: a prompt LakehouseBox
runs next to the data, on a schedule. Every day at 12:00 Madrid time it:

1. closes yesterday's forecasts against what the stations measured (`now.scored_predictions`, a Brier score each) and
   writes down what it learned when it was wrong;
2. reads today's hours, the last week, AEMET's forecast for tomorrow, the city's weather stations and traffic;
3. writes its forecasts for tomorrow to `agent.predictions`: the probability of breaking the EU 2030 daily limit (city
   and each of the five protocol zones), the WHO guideline, the parking surcharge and the protocol's first level, and
   whether it would have the city restrict traffic;
4. emails when it would.

Its forecasts, its scores and its memory are tables in the catalog, so whether it is getting better is a query.

## What's in the catalog

| Namespace | What |
|---|---|
| `ref` | `stations` (24, with the protocol zone), `magnitudes` (pollutant codes), `rules` (every rule set as data), `past_episodes` (the council's decisions 2017-2021, day by day) |
| `obs` | `air_hourly` (since 2010, live), `meteo_hourly`, `traffic` (~4,900 points every 5 min), `protocol_feed` (the council's live protocol state), `weather_forecast` (AEMET, every issue kept) |
| `now` | rebuilt inside LakehouseBox: `daily_station`, `daily_city` (the city under every rule set, each day), `compliance` (each year, station and rule), `scored_predictions` |
| `agent` | `predictions` |

[`docs/AGENTS.md`](docs/AGENTS.md) explains every table for an agent; LakehouseBox serves it at the catalog root.

## How it works

```
the city's feeds, AEMET ──► scheduled SQL in LakehouseBox ──► obs.* ──► scheduled SQL (sql/now/) ──► now.*
                                                                                     │
                                       aire_forecaster (noon) ◄──────────────────────┘──► agent.predictions
```

- **Ingestion is SQL** ([`sql/ingest/`](sql/ingest)): each source is one DuckDB query LakehouseBox runs on a schedule.
  The traffic and protocol feeds are XML, read with `read_text` and regular expressions; the city's real-time CSV is
  fetched with `http_get` (its server reports a one-byte length to DuckDB's usual readers).
- **The rules are data** (`ref.rules`): a stricter rule set is new rows, not new code.
- **Everything is code.** Tables are migrations ([`sql/migrations/`](sql/migrations)), the catalog, sinks and agent
  are declared in [`lakehouse.yaml`](lakehouse.yaml), and CI applies `main` ([`.github/workflows/lakehouse.yml`](.github/workflows/lakehouse.yml)).

## Setting it up

```sh
lhbox catalog create aire_madrid --project public-data   # once
lhbox migrate --catalog aire_madrid
lhbox duckdb --catalog aire_madrid < sql/reference/load_reference.sql    # once, into empty ref tables
python3 tools/backfill_air_history.py --from-year 2010                   # writes data/air_history.parquet
lhbox duckdb --catalog aire_madrid -- -c "INSERT INTO aire_madrid.obs.air_hourly SELECT *, now() FROM 'data/air_history.parquet'"
lhbox apply -f lakehouse.yaml
lhbox agent update aire_forecaster --topic forecasts --topic lessons     # memory topics: not in lakehouse.yaml yet
```

## Sources

Official sources only, credited as their publishers ask:

- **Ayuntamiento de Madrid**, open data (CC BY 4.0): air quality real time and hourly history (datasets 212531,
  300755, 201200), weather stations (300392, 300352), stations (212629), NO2 protocol activations (300403), Informo
  traffic and incidents (pm.xml, incid_aytomadrid.xml).
- **Ayuntamiento de Madrid**, the NO2 protocol of 10 December 2018 and its episode reports (airedemadrid.madrid.es).
- **AEMET OpenData**: the hourly forecast for Madrid.
- **EU** Directives 2008/50/EC and (EU) 2024/2881; **WHO** Global Air Quality Guidelines 2021.

The research behind it, each claim with its source: [`docs/research/`](docs/research) (the protocol, every
source tested, the activation history).

## Licence

Code: Apache 2.0. Data: as each source licenses it (above).
