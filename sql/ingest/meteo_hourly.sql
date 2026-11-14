-- Madrid city weather network, real time -> aire_madrid.obs.meteo_hourly. Scheduled SQL, hourly at :27.
-- One row per station, pollutant and hour (hour_start_at, Madrid hours stored as timestamptz), valid hours only (V).
-- The file holds the current Madrid day; this run keeps the last 3 hours, and air_hourly_daily fills each whole
-- day from the 30-day file the next morning. Rows repeat between the two: readers keep the latest per
-- (station_code, magnitude, hour_start_at) by __ingest_ts. Variable codes: ref.magnitudes (81 wind m/s, 82 direction, 83 temperature, 86 humidity, 87 pressure, 88 radiation, 89 rain).
-- Fetched with http_get: the API answers HEAD with Content-Length: 1, so read_csv/read_text would read one byte
-- (research/133 in tablemere, data-sources.md 1a). The body comes back JSON-typed: ->> '$' unwraps the string.
WITH f AS MATERIALIZED (
  SELECT (http_get('https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/meteo_tiemporeal.csv?pageSize=5000')).body ->> '$' AS txt   -- the body comes back JSON-typed: unwrap the string
),
lines AS (
  SELECT string_split(trim(replace(line, chr(65279), '')), ';') AS c
  FROM f, unnest(string_split(replace(txt, chr(13), ''), chr(10))) AS t(line)
  WHERE line LIKE '28;%'
),
hours AS (
  SELECT c[3]::INTEGER AS station, c[4]::INTEGER AS magnitude,
         make_date(c[6]::INTEGER, c[7]::INTEGER, c[8]::INTEGER) AS day, h,
         c[9 + 2 * (h - 1)] AS v, c[10 + 2 * (h - 1)] AS flag
  FROM lines, range(1, 25) AS r(h)
)
SELECT 28079000 + station                                                     AS station_code,
       magnitude,
       timezone('Europe/Madrid', day::TIMESTAMP + to_hours(h - 1))             AS hour_start_at,
       TRY_CAST(v AS DOUBLE)                                                   AS value,
       false                                                                   AS is_validated,
       'madrid-meteo-realtime'                                                       AS source
FROM hours
WHERE flag = 'V' AND TRY_CAST(v AS DOUBLE) IS NOT NULL
  AND timezone('Europe/Madrid', day::TIMESTAMP + to_hours(h - 1)) >= now() - INTERVAL 3 HOUR
