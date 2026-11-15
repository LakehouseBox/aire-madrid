-- One row per Madrid day with everything the replay needs, read from the catalog into a local file:
--   lhbox duckdb --catalog aire_madrid -- -c "SET VARIABLE lo = DATE '2024-09-01'; SET VARIABLE hi = DATE '2025-04-01';
--     COPY (FROM read_text('tools/replay_days.sql') ...)"   (tools/replay.py runs it)
-- morning_*: hours 00:00-11:59 of the day (what the forecaster knows at noon); day_*: the whole day (the outcome).
-- Weather is the mean over the city's stations: wind (81, m/s), temperature (83, °C), pressure (87, mb), rain (89, mm).
WITH no2 AS (
  SELECT a.station_code, a.hour_start_at, a.value, s.protocol_zone, s.is_ser_background,
         (a.hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE AS day,
         hour(a.hour_start_at AT TIME ZONE 'Europe/Madrid')   AS hr
  FROM aire_madrid.obs.air_hourly a JOIN aire_madrid.ref.stations s USING (station_code)
  WHERE a.magnitude = 8 AND a.hour_start_at >= getvariable('lo')::TIMESTAMPTZ - INTERVAL 10 DAY
    AND a.hour_start_at < getvariable('hi')::TIMESTAMPTZ + INTERVAL 2 DAY
  QUALIFY row_number() OVER (PARTITION BY a.station_code, a.hour_start_at ORDER BY a.__ingest_ts DESC NULLS LAST) = 1
),
morning AS (
  SELECT day,
         round(max(value), 0)                                              AS morning_max_hour,
         round(avg(value) FILTER (WHERE is_ser_background), 1)             AS morning_background_mean,
         round(avg(value) FILTER (WHERE hr BETWEEN 7 AND 10), 1)           AS morning_rush_mean
  FROM no2 WHERE hr < 12 GROUP BY day
),
zone_morning AS (
  SELECT day, string_agg('zone ' || protocol_zone || ': ' || mx, ', ' ORDER BY protocol_zone) AS morning_zone_max
  FROM (SELECT day, protocol_zone, round(max(value), 0) AS mx FROM no2 WHERE hr < 12 GROUP BY ALL) GROUP BY day
),
station_day AS (
  SELECT day, station_code, protocol_zone, avg(value) AS mean, count(*) AS n FROM no2 GROUP BY ALL
),
zone_day AS (
  SELECT day, string_agg('zone ' || protocol_zone || ': ' || mx, ', ' ORDER BY protocol_zone) AS day_zone_worst_mean
  FROM (SELECT day, protocol_zone, round(max(mean) FILTER (WHERE n >= 18), 0) AS mx FROM station_day GROUP BY ALL) GROUP BY day
),
meteo AS (   -- city mean per hour and magnitude (mean over the stations that measure it)
  SELECT hour_start_at, (hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE AS day,
         hour(hour_start_at AT TIME ZONE 'Europe/Madrid') < 12 AS am, magnitude, avg(value) AS v
  FROM (
    SELECT * FROM aire_madrid.obs.meteo_hourly
    WHERE magnitude IN (81, 83, 87, 89) AND hour_start_at >= getvariable('lo')::TIMESTAMPTZ - INTERVAL 10 DAY
      AND hour_start_at < getvariable('hi')::TIMESTAMPTZ + INTERVAL 2 DAY
    QUALIFY row_number() OVER (PARTITION BY station_code, magnitude, hour_start_at ORDER BY __ingest_ts DESC NULLS LAST) = 1
  )
  GROUP BY ALL
),
wx AS (
  SELECT day,
         round(avg(v) FILTER (WHERE magnitude = 81), 1)                    AS wind_ms,
         round(avg(v) FILTER (WHERE magnitude = 81 AND am), 1)             AS morning_wind_ms,
         round(max(v) FILTER (WHERE magnitude = 83), 0)                    AS temp_max_c,
         round(min(v) FILTER (WHERE magnitude = 83), 0)                    AS temp_min_c,
         round(avg(v) FILTER (WHERE magnitude = 87), 0)                    AS pressure_mb,
         round(sum(v) FILTER (WHERE magnitude = 89), 1)                    AS rain_mm
  FROM meteo GROUP BY day
)
SELECT c.day, dayname(c.day) AS weekday,
       c.worst_daily_mean, c.stations_over_eu2030_day, c.ser_background_mean, c.protocol_level,
       m.morning_max_hour, m.morning_background_mean, m.morning_rush_mean, zm.morning_zone_max, zd.day_zone_worst_mean,
       w.wind_ms, w.morning_wind_ms, w.temp_max_c, w.temp_min_c, w.pressure_mb, w.rain_mm
FROM aire_madrid.now.daily_city c
LEFT JOIN morning m USING (day) LEFT JOIN zone_morning zm USING (day) LEFT JOIN zone_day zd USING (day) LEFT JOIN wx w USING (day)
WHERE c.day >= getvariable('lo') - 8 AND c.day < getvariable('hi') + 2
ORDER BY c.day
