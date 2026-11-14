-- now.scored_predictions: every forecast the agent made, next to what happened, once the day is over.
-- outcome is 1 when the event happened, 0 when not; brier = (probability - outcome)^2 (0 perfect, 0.25 a coin flip).
-- Questions (agent.predictions.question) and how each is checked:
--   eu2030.no2.day       a station's daily NO2 mean > 50 (scope station:<code>, zone:<n> = any station of the zone, city = any)
--   who2021.no2.day      the same at 25
--   ser.no2.surcharge60  the 12 background stations' mean > 60 (city only): the SER surcharge fires the day after
--   protocol.no2.preaviso the protocol's preaviso (or higher) is reached by the measurements (city only)
-- Derived sink, mode replace, hourly. A forecast is scored only when its day has at least 18 stations reporting.
WITH p AS (
  SELECT *, row_number() OVER (PARTITION BY target_day, question, scope ORDER BY made_at DESC) AS nth
  FROM aire_madrid.agent.predictions
),
station_day AS (
  SELECT d.day, d.station_code, s.protocol_zone, d.daily_mean
  FROM aire_madrid.now.daily_station d JOIN aire_madrid.ref.stations s USING (station_code)
  WHERE d.pollutant = 'NO2' AND d.daily_mean IS NOT NULL
),
outcomes AS (
  SELECT p.made_at, p.target_day, p.question, p.scope, p.probability, p.expected_value, p.would_restrict, p.run_id,
         p.nth = 1 AS is_latest,
         CASE
           WHEN p.question IN ('eu2030.no2.day', 'who2021.no2.day') THEN (
             SELECT CASE WHEN count(*) = 0 THEN NULL
                         ELSE max(CASE WHEN sd.daily_mean > CASE p.question WHEN 'eu2030.no2.day' THEN 50 ELSE 25 END THEN 1 ELSE 0 END) END
             FROM station_day sd
             WHERE sd.day = p.target_day
               AND (p.scope = 'city'
                    OR (p.scope LIKE 'zone:%' AND sd.protocol_zone = TRY_CAST(split_part(p.scope, ':', 2) AS INTEGER))
                    OR (p.scope LIKE 'station:%' AND sd.station_code = TRY_CAST(split_part(p.scope, ':', 2) AS INTEGER))))
           WHEN p.question = 'ser.no2.surcharge60' THEN (
             SELECT CASE WHEN c.ser_background_mean > 60 THEN 1 ELSE 0 END FROM aire_madrid.now.daily_city c WHERE c.day = p.target_day)
           WHEN p.question = 'protocol.no2.preaviso' THEN (
             SELECT CASE WHEN c.protocol_level <> 'none' THEN 1 ELSE 0 END FROM aire_madrid.now.daily_city c WHERE c.day = p.target_day)
         END AS outcome,
         (SELECT c.stations_reporting FROM aire_madrid.now.daily_city c WHERE c.day = p.target_day) AS stations_reporting
  FROM p
)
SELECT made_at, target_day, question, scope, probability, expected_value, would_restrict, run_id, is_latest,
       outcome,
       CASE WHEN outcome IS NOT NULL THEN round(power(probability - outcome, 2), 4) END AS brier
FROM outcomes
WHERE stations_reporting >= 18 AND target_day < (now() AT TIME ZONE 'Europe/Madrid')::DATE
