# Does the computed protocol level match the council's record?

`sql/now/daily_city.sql` computes, from the hourly measurements alone, the level of the 2018 NO2 protocol each day
reached. Checked on 2026-11-15 against the council's per-episode reports for 2017-2021 (`ref.past_episodes`), with the
city's validated hourly history (2010 to October 2026, 20.8 million rows).

**Days the council records a level on: 28 of 29 found.**

- The one miss: 2017-11-22, preaviso in zone 3 by the council, nothing in the validated data. Likely a revision between
  the real-time values the council decided on and the validated history.
- Two days the council calls aviso come out as preaviso (2017-10-11; and on 2018-12-10 the zones are preaviso, the city
  aviso, which the computation finds).
- The network rule matters. Read as "the same 3 stations above the threshold for 3 consecutive hours", it misses the
  council's city-wide levels of 2019-01-04 and 2020-01-08 and the aviso of 2018-12-10. Read as "3 stations, any, in each
  of 3 consecutive hours", it finds all three. The SQL uses the second reading.

**Days the measurements reach a level and the council did nothing: 10 in 2017-2021.**

| Day | Computed | Zones |
|---|---|---|
| 2017-07-16 | preaviso | 5 |
| 2017-09-20 | aviso | 1 |
| 2017-09-21 | preaviso | 1 |
| 2017-10-07 | aviso | 1 |
| 2017-10-09 | preaviso | 1 |
| 2017-12-20 | preaviso | 2, 3 (and city) |
| 2017-12-22 | preaviso | 1 |
| 2018-08-01 | aviso | 1 (and city) |
| 2018-08-02 | preaviso | 1 |
| 2019-07-12 | preaviso | 1 |

The protocol starts an episode only when AEMET's forecast is also unfavourable (stable air), and the council decides
with real-time data and judgement. Summer days and days before a change of weather are where the measurements and the
decision part. These are the days an agent forecasting the council's decision, not the arithmetic, has to learn. The
2016 protocol (in force until December 2018) had slightly different rules, which may account for some 2017 rows.

**Since 2022:** no day reaches a level in the measurements either (2 station-hours above 180 in 2026, never two of a
zone in consecutive hours), which agrees with the council's "no episode" for every year since.

Station-hours above 200 µg/m³, by year: 2010 336, 2011 513, 2012 171, 2013 158, 2014 215, 2015 554, 2016 222, 2017 326,
2018 102, 2019 96, 2020 13, 2021 11, 2022 1, 2023-2026 0.
