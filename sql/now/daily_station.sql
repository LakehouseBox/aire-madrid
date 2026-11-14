-- now.daily_station: each Madrid day at each station, for NO2, PM10 and PM2.5: the daily mean (when at least 18 of
-- the 24 hours are valid, the EU's 75 % rule), the worst hour, and the hours above the protocol's 180 and 200.
-- Derived sink (scheduled SQL that reads the catalog), mode replace, hourly. De-duplicates obs.air_hourly first.
WITH hourly AS (
  SELECT station_code, magnitude, hour_start_at, value
  FROM aire_madrid.obs.air_hourly
  WHERE magnitude IN (8, 9, 10) AND value IS NOT NULL
  QUALIFY row_number() OVER (PARTITION BY station_code, magnitude, hour_start_at ORDER BY __ingest_ts DESC NULLS LAST) = 1
)
SELECT (hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE                 AS day,
       station_code,
       CASE magnitude WHEN 8 THEN 'NO2' WHEN 9 THEN 'PM2.5' ELSE 'PM10' END AS pollutant,
       count(*)                                                            AS hours_valid,
       CASE WHEN count(*) >= 18 THEN round(avg(value), 1) END              AS daily_mean,
       max(value)                                                          AS max_hour,
       count(*) FILTER (WHERE value > 180)                                 AS hours_over_180,
       count(*) FILTER (WHERE value > 200)                                 AS hours_over_200
FROM hourly
GROUP BY ALL
