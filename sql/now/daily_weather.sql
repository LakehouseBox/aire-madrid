-- now.daily_weather: one row per Madrid day since 2019, the city's weather as the mean over its weather stations:
-- mean wind (m/s), the day's highest and lowest hourly temperature (°C), mean pressure (mb), total rain (mm), and the
-- morning (00:00-11:59) wind. Today is partial. With now.daily_city it answers "what happened on days like this":
-- the forecaster joins it to its own scored forecasts (now.scored_predictions) to find past days like tomorrow.
-- Derived sink, mode replace, hourly.
WITH hourly AS (   -- the city mean per hour and magnitude
  SELECT hour_start_at, magnitude, avg(value) AS v
  FROM (
    SELECT * FROM aire_madrid.obs.meteo_hourly
    WHERE magnitude IN (81, 83, 87, 89)
    QUALIFY row_number() OVER (PARTITION BY station_code, magnitude, hour_start_at ORDER BY __ingest_ts DESC NULLS LAST) = 1
  )
  GROUP BY ALL
)
SELECT (hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE                              AS day,
       round(avg(v) FILTER (WHERE magnitude = 81), 1)                                  AS wind_ms,
       round(avg(v) FILTER (WHERE magnitude = 81
                            AND hour(hour_start_at AT TIME ZONE 'Europe/Madrid') < 12), 1) AS morning_wind_ms,
       round(max(v) FILTER (WHERE magnitude = 83), 1)                                  AS temp_max_c,
       round(min(v) FILTER (WHERE magnitude = 83), 1)                                  AS temp_min_c,
       round(avg(v) FILTER (WHERE magnitude = 87), 0)                                  AS pressure_mb,
       round(sum(v) FILTER (WHERE magnitude = 89), 1)                                  AS rain_mm,
       count(DISTINCT hour_start_at)                                                   AS hours
FROM hourly
GROUP BY 1
ORDER BY 1
