-- The council's live pollution-protocol state, from Informo's incidents feed -> aire_madrid.obs.protocol_feed.
-- Scheduled SQL, every 15 min. One row per run: during an episode the feed carries one city-wide incident with
-- es_contaminacion = S and the active scenario, its date, reasons, measures and exceptions (tipoincid 10, no
-- coordinates; field meanings: the feed's structure PDF, research/133). Outside an episode the row says so
-- (is_active false), so the table is the observed history of the protocol from the day this sink started.
WITH src AS (SELECT content FROM read_text('https://informo.madrid.es/informo/tmadrid/incid_aytomadrid.xml')),
inc AS (SELECT unnest(regexp_extract_all(content, '<Incidencia>(.*?)</Incidencia>', 1, 's')) AS i FROM src),
pol AS (
  SELECT true AS hit,
         nullif(regexp_extract(i, '<escenario_contaminacion>([^<]*)</escenario_contaminacion>', 1), '')             AS scenario,
         nullif(regexp_extract(i, '<fecha_escenario_contaminacion>([^<]*)</fecha_escenario_contaminacion>', 1), '') AS scenario_date,
         nullif(regexp_extract(i, '<descripcion_escenario>([^<]*)</descripcion_escenario>', 1, 's'), '')            AS reasons,
         nullif(regexp_extract(i, '<medidas_escenario>([^<]*)</medidas_escenario>', 1, 's'), '')                    AS measures,
         nullif(regexp_extract(i, '<excepciones_escenario>([^<]*)</excepciones_escenario>', 1, 's'), '')            AS exceptions
  FROM inc
  WHERE regexp_extract(i, '<es_contaminacion>([^<]*)</es_contaminacion>', 1) = 'S'
)
SELECT now()                         AS polled_at,
       coalesce(bool_or(pol.hit), false) AS is_active,
       max(pol.scenario)             AS scenario,
       max(pol.scenario_date)        AS scenario_date,
       max(pol.reasons)              AS reasons,
       max(pol.measures)             AS measures,
       max(pol.exceptions)           AS exceptions,
       (SELECT count(*) FROM inc)    AS incidents_in_feed
FROM (SELECT 1) AS one LEFT JOIN pol ON true
