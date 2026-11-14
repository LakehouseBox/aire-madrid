-- AEMET's hourly forecast for the municipality of Madrid (28079) -> aire_madrid.obs.weather_forecast.
-- Scheduled SQL, every 3 hours. AEMET answers in two steps: the keyed call returns a `datos` URL to fetch at once.
-- The key is the organisation's aemet web integration, through the catalog connection `aemet` (as in embalses).
-- One row per forecast hour and issue: the agent compares what was forecast with what happened.
WITH s AS MATERIALIZED (
  SELECT (http_get('https://opendata.aemet.es/opendata/api/prediccion/especifica/municipio/horaria/28079')).body::JSON ->> 'datos' AS u
),
d AS MATERIALIZED (SELECT (http_get(u)).body::JSON AS j FROM s),
dias AS (
  SELECT j -> 0 ->> 'elaborado' AS issued, unnest(from_json(j -> 0 -> 'prediccion' -> 'dia', '["JSON"]')) AS dia FROM d
),
per AS (   -- one row per (day, hour) from the temperature series; the others join on periodo
  SELECT issued, dia, (dia ->> 'fecha')::DATE AS fecha, unnest(from_json(dia -> 'temperatura', '[{"value":"VARCHAR","periodo":"VARCHAR"}]')) AS t
  FROM dias
)
SELECT timezone('Europe/Madrid', strptime(issued, '%Y-%m-%dT%H:%M:%S'))                       AS issued_at,
       timezone('Europe/Madrid', fecha::TIMESTAMP + to_hours(t.periodo::INT))                  AS hour_start_at,
       TRY_CAST(t.value AS DOUBLE)                                                             AS temperature_c,
       TRY_CAST(list_filter(from_json(dia -> 'precipitacion', '[{"value":"VARCHAR","periodo":"VARCHAR"}]'), lambda x: x.periodo = t.periodo)[1].value AS DOUBLE) AS precipitation_mm,
       TRY_CAST(list_filter(from_json(dia -> 'humedadRelativa', '[{"value":"VARCHAR","periodo":"VARCHAR"}]'), lambda x: x.periodo = t.periodo)[1].value AS DOUBLE) AS relative_humidity_pct,
       TRY_CAST(list_filter(from_json(dia -> 'vientoAndRachaMax', '[{"direccion":["VARCHAR"],"velocidad":["VARCHAR"],"periodo":"VARCHAR"}]'), lambda x: x.periodo = t.periodo AND x.velocidad IS NOT NULL)[1].velocidad[1] AS DOUBLE) AS wind_speed_kmh,
       list_filter(from_json(dia -> 'vientoAndRachaMax', '[{"direccion":["VARCHAR"],"velocidad":["VARCHAR"],"periodo":"VARCHAR"}]'), lambda x: x.periodo = t.periodo AND x.direccion IS NOT NULL)[1].direccion[1] AS wind_direction,
       list_filter(from_json(dia -> 'estadoCielo', '[{"value":"VARCHAR","periodo":"VARCHAR","descripcion":"VARCHAR"}]'), lambda x: x.periodo = t.periodo)[1].descripcion AS sky,
       'aemet-opendata'                                                                        AS source
FROM per
