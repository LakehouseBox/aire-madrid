-- Informo real-time traffic sensors -> aire_madrid.obs.traffic. Scheduled SQL, every 5 min (the feed's cadence).
-- ~4,900 measurement points; regex over the XML (no XML reader in DuckDB). The 's' flag lets .*? cross newlines:
-- without it the query returns no rows. Coordinates are UTM ETRS89 30N with comma decimals; ref.traffic_points
-- carries lon/lat by idelem. The file's timestamp is Madrid wall time.
WITH src AS (SELECT content FROM read_text('https://informo.madrid.es/informo/tmadrid/pm.xml')),
pms AS (
  SELECT regexp_extract(content, '<fecha_hora>([^<]*)</fecha_hora>', 1) AS fecha_hora,
         unnest(regexp_extract_all(content, '<pm>(.*?)</pm>', 1, 's')) AS pm
  FROM src
)
SELECT timezone('Europe/Madrid', strptime(fecha_hora, '%d/%m/%Y %-H:%M:%S'))                       AS observed_at,
       regexp_extract(pm, '<idelem>([^<]*)</idelem>', 1)::INTEGER                                   AS point_id,
       TRY_CAST(nullif(regexp_extract(pm, '<intensidad>([^<]*)</intensidad>', 1), '') AS INTEGER)   AS vehicles_per_hour,
       TRY_CAST(nullif(regexp_extract(pm, '<ocupacion>([^<]*)</ocupacion>', 1), '') AS INTEGER)     AS occupancy_pct,
       TRY_CAST(nullif(regexp_extract(pm, '<carga>([^<]*)</carga>', 1), '') AS INTEGER)             AS load_pct,
       TRY_CAST(nullif(regexp_extract(pm, '<nivelServicio>([^<]*)</nivelServicio>', 1), '') AS INTEGER) AS service_level,
       TRY_CAST(nullif(regexp_extract(pm, '<velocidad>([^<]*)</velocidad>', 1), '') AS INTEGER)     AS speed_kmh,
       regexp_extract(pm, '<error>([^<]*)</error>', 1) = 'S'                                        AS is_error
FROM pms
