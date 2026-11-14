# aire_madrid: Madrid's air, weather and traffic, scored against every rule set

What Madrid's air-quality stations measure, hour by hour since 2010, next to the weather, the traffic and the city's
pollution-protocol decisions, and each day scored against the EU limits in force, the EU limits for 2030, the WHO 2021
guidelines and the city's own triggers. Every value comes from its publisher: Ayuntamiento de Madrid open data (CC BY
4.0) and AEMET OpenData.

## Namespaces

- **ref**: `stations` (24, with the NO2 protocol zone 1-5 and whether it drives the SER parking surcharge),
  `magnitudes` (the city's pollutant and weather codes), `rules` (every rule set as rows: `eu2008`, `eu2030`, `who2021`,
  `protocol2018`, `ser2022`), `past_episodes` (the council's protocol decisions 2017-2021, one row per day).
- **obs**: append-only, partitioned by time.
  - `air_hourly`: hourly means per station and pollutant (magnitude 8 = NO2, 9 = PM2.5, 10 = PM10, 14 = O3), since
    2010; validated history plus real time.
  - `meteo_hourly`: the city's weather stations, same shape (81 wind m/s, 82 direction, 83 temperature, 86 humidity,
    87 pressure, 88 radiation, 89 rain).
  - `traffic`: ~4,900 measurement points every ~5 minutes (vehicles per hour, occupancy, load, M-30 speed).
  - `protocol_feed`: the council's live protocol state, polled every 15 minutes (`is_active` false outside an episode).
  - `weather_forecast`: AEMET's hourly forecast for Madrid, every issue kept (`issued_at`).
- **now**: rebuilt inside LakehouseBox. `daily_station` (daily mean, worst hour, hours above 180 and 200),
  `daily_city` (one row per day: the protocol level the measurements reach, the SER surcharge, stations over the EU 2030
  and WHO daily limits, what the council did), `compliance` (each year, station and rule: exceedances, allowed,
  passes), `scored_predictions` (the agent's forecasts with their outcome and Brier score).
- **agent**: `predictions`, written by the hosted agent `aire_forecaster` every day at noon for the next day.

## How the tables join

```
obs.air_hourly.station_code → ref.stations.station_code      obs.air_hourly.magnitude → ref.magnitudes
now.daily_station (day, station_code) → ref.stations          now.daily_city.day ← ref.past_episodes.day
agent.predictions.question → ref.rules.rule_id               now.scored_predictions = agent.predictions + outcome
```

## Units and conventions

- Concentrations in µg/m³ (CO and hydrocarbons in mg/m³: see `ref.magnitudes.unit`).
- Timestamps are `timestamptz`. A Madrid day is `(hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE`; the city labels
  hours by their end (H01 = 00:00-01:00), stored here as the hour's start.
- A daily mean counts only with at least 18 valid hours (the EU's 75 % rule).
- `obs.*` rows can repeat (the live files are read more than once): keep the latest per key by `__ingest_ts`. The
  `now.*` tables already do.

## Caveats

- Real-time values are unvalidated; the city revises some when it validates them (`is_validated`).
- The protocol level in `now.daily_city` is what the measurements alone reach; the council also requires an
  unfavourable weather forecast and decides with judgement. Checked against its 2017-2021 record: 28 of the 29 days it
  records a level are found, and 10 days reach a level with no action (see docs/research/protocol-check.md in the
  repository).
- No protocol episode has happened since 17 December 2021; `ref.past_episodes` ends there and `obs.protocol_feed`
  carries the live state from the day it started.
- Urb. Embajada (28079055) has been out of service since 1 September 2025.
- Years before 2030 are scored against the 2030 rules on purpose: "how would Madrid have fared".
