-- now.daily_city: one row per Madrid day, the city under every rule set at once.
--   * the NO2 protocol of 2018: the level reached that day (none, preaviso, aviso, alerta), computed hour by hour
--     with the protocol's own counting (2 stations of one zone above the threshold in 2 consecutive hours, or 3
--     stations anywhere in each of 3; alerta: 3 of a zone, 2 in zone 4, for 3 hours), and the zones where it was
--     reached. Checked against the council's reports 2017-2021: see docs/research/protocol-check.md;
--     the weather gate (AEMET's ventilation forecast) is NOT applied: this is what the measurements alone say;
--   * the SER parking surcharge it triggers for the next day (mean of the 12 background stations above 60 / 70);
--   * the EU 2030 and WHO daily limits: how many stations exceeded them;
--   * what the council actually did: ref.past_episodes (2017-2021) and obs.protocol_feed (live).
-- Derived sink, mode replace, hourly.
WITH hourly AS (
  SELECT a.station_code, s.protocol_zone, a.hour_start_at, a.value
  FROM aire_madrid.obs.air_hourly a JOIN aire_madrid.ref.stations s USING (station_code)
  WHERE a.magnitude = 8 AND a.value IS NOT NULL
  QUALIFY row_number() OVER (PARTITION BY a.station_code, a.hour_start_at ORDER BY a.__ingest_ts DESC NULLS LAST) = 1
),
runs AS (   -- for each station-hour and threshold: was it above in this hour and the 1 and 2 hours before?
  SELECT h.*, t.threshold,
         h.value > t.threshold AS above0,
         h.value > t.threshold
           AND lag(h.value) OVER w > t.threshold
           AND lag(h.hour_start_at) OVER w = h.hour_start_at - INTERVAL 1 HOUR AS above2,
         h.value > t.threshold
           AND lag(h.value) OVER w > t.threshold AND lag(h.value, 2) OVER w > t.threshold
           AND lag(h.hour_start_at, 2) OVER w = h.hour_start_at - INTERVAL 2 HOUR AS above3
  FROM hourly h, (VALUES (180), (200), (400)) AS t(threshold)
  WINDOW w AS (PARTITION BY h.station_code, t.threshold ORDER BY h.hour_start_at)
),
hour_level AS (   -- per hour and threshold: met in a zone, or across the network
  SELECT hour_start_at, threshold, protocol_zone,
         CASE WHEN threshold < 400 THEN count(*) FILTER (WHERE above2) >= 2
              ELSE count(*) FILTER (WHERE above3) >= CASE WHEN protocol_zone = 4 THEN 2 ELSE 3 END END AS zone_met
  FROM runs GROUP BY hour_start_at, threshold, protocol_zone
),
network AS (   -- 3 stations anywhere above the threshold in each of 3 consecutive hours (not necessarily the same
               -- stations: this reading matches the council's city-wide levels of 2018-2020; the same-station reading
               -- misses three of them)
  SELECT hour_start_at, threshold,
         min(n) OVER (PARTITION BY threshold ORDER BY hour_start_at RANGE BETWEEN INTERVAL 2 HOUR PRECEDING AND CURRENT ROW) >= 3
           AND count(*) OVER (PARTITION BY threshold ORDER BY hour_start_at RANGE BETWEEN INTERVAL 2 HOUR PRECEDING AND CURRENT ROW) = 3 AS network_met
  FROM (SELECT hour_start_at, threshold, count(*) FILTER (WHERE above0) AS n FROM runs WHERE threshold < 400 GROUP BY hour_start_at, threshold)
),
day_level AS (
  SELECT (hl.hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE AS day,
         max(hl.threshold) FILTER (WHERE hl.zone_met OR coalesce(n.network_met, false)) AS level_threshold,
         string_agg(DISTINCT hl.protocol_zone::VARCHAR, ',' ORDER BY hl.protocol_zone::VARCHAR) FILTER (WHERE hl.zone_met AND hl.threshold = 180) AS zones_preaviso,
         bool_or(coalesce(n.network_met, false) AND hl.threshold = 180) AS network_preaviso
  FROM hour_level hl LEFT JOIN network n USING (hour_start_at, threshold)
  GROUP BY 1
),
station_day AS (
  SELECT (hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE AS day, station_code, count(*) AS n, avg(value) AS mean, max(value) AS mx
  FROM hourly GROUP BY 1, 2
),
city AS (
  SELECT sd.day,
         count(*) FILTER (WHERE sd.n >= 18)                                 AS stations_reporting,
         max(sd.mx)                                                         AS worst_hour,
         max(sd.mean) FILTER (WHERE sd.n >= 18)                             AS worst_daily_mean,
         count(*) FILTER (WHERE sd.n >= 18 AND sd.mean > 50)                AS stations_over_eu2030_day,
         count(*) FILTER (WHERE sd.n >= 18 AND sd.mean > 25)                AS stations_over_who_day,
         count(*) FILTER (WHERE sd.mx > 200)                                AS stations_over_200_hour
  FROM station_day sd GROUP BY sd.day
),
ser AS (    -- the tariff's base: every valid hour of the 12 background stations, 00-23 h
  SELECT (h.hour_start_at AT TIME ZONE 'Europe/Madrid')::DATE AS day, round(avg(h.value), 1) AS ser_background_mean
  FROM hourly h JOIN aire_madrid.ref.stations s USING (station_code)
  WHERE s.is_ser_background GROUP BY 1
),
council AS (
  SELECT day, max(scenario_in_force) AS council_scenario, max(level_reached) AS council_level FROM aire_madrid.ref.past_episodes GROUP BY day
  UNION ALL
  SELECT (polled_at AT TIME ZONE 'Europe/Madrid')::DATE, max(scenario) FILTER (WHERE is_active), NULL
  FROM aire_madrid.obs.protocol_feed GROUP BY 1 HAVING bool_or(is_active)
)
SELECT c.day,
       c.stations_reporting,
       c.worst_hour,
       round(c.worst_daily_mean, 1)                                          AS worst_daily_mean,
       CASE d.level_threshold WHEN 400 THEN 'alerta' WHEN 200 THEN 'aviso' WHEN 180 THEN 'preaviso' ELSE 'none' END AS protocol_level,
       d.zones_preaviso,
       coalesce(d.network_preaviso, false)                                   AS network_preaviso,
       s.ser_background_mean,
       CASE WHEN s.ser_background_mean > 70 THEN 100 WHEN s.ser_background_mean > 60 THEN 60 ELSE 0 END AS ser_surcharge_next_day_pct,
       c.stations_over_eu2030_day,
       c.stations_over_who_day,
       c.stations_over_200_hour,
       k.council_scenario,
       k.council_level
FROM city c
LEFT JOIN day_level d USING (day)
LEFT JOIN ser s USING (day)
LEFT JOIN council k USING (day)
