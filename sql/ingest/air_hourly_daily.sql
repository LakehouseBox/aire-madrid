-- Madrid city air-quality network, rolling 30 days -> aire_madrid.obs.air_hourly. Scheduled SQL, daily at 06:40 UTC.
-- One row per station, pollutant and hour (hour_start_at, Madrid hours stored as timestamptz), valid hours only (V).
-- The file holds the current Madrid day; this run takes yesterday and the day before, whole, from the
-- 30-day file (calair_tiemporeal_ult), which closes any hour the hourly run missed. Rows repeat between the two: readers keep the latest per
-- (station_code, magnitude, hour_start_at) by __ingest_ts. Pollutant codes: ref.magnitudes (8 = NO2).
-- Fetched with http_get: the API answers HEAD with Content-Length: 1, so read_csv/read_text would read one byte
-- (docs/research/data-sources.md 1a). Its body is text on some DuckDB versions and JSON on others: the
-- to_json/json_extract_string pair gives the text either way.
WITH f AS MATERIALIZED (
  SELECT json_extract_string(to_json((http_get('https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/calair_tiemporeal_ult.csv?pageSize=5000')).body), '$') AS txt
),
raw_lines AS MATERIALIZED (   -- only the lines: a lateral join would carry the whole file along with each one
  SELECT unnest(string_split(replace(txt, chr(13), ''), chr(10))) AS line FROM f
),
lines AS (
  SELECT string_split(trim(replace(line, chr(65279), '')), ';') AS c
  FROM raw_lines
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
       'madrid-realtime-30d'                                                       AS source
FROM hours
WHERE flag = 'V' AND TRY_CAST(v AS DOUBLE) IS NOT NULL
  AND day BETWEEN current_date - 2 AND current_date - 1
