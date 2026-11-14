-- Observations: append-only, partitioned by time. Sinks deliver at least once and the live files are re-read, so
-- rows repeat: readers keep the latest per key by __ingest_ts (the now.* tables do).

-- lhbox: format-version=3 partition=month(hour_start_at)
CREATE TABLE IF NOT EXISTS aire_madrid.obs.air_hourly (
  station_code INTEGER NOT NULL,
  magnitude INTEGER NOT NULL,
  hour_start_at TIMESTAMPTZ NOT NULL,
  value DOUBLE,
  is_validated BOOLEAN,
  source VARCHAR NOT NULL,
  __ingest_ts TIMESTAMPTZ
);
COMMENT ON TABLE aire_madrid.obs.air_hourly IS 'Hourly mean of each pollutant at each station of Madrid city''s network. Key: (station_code, magnitude, hour_start_at); keep the latest __ingest_ts. Real time from the city (unvalidated) and history from its hourly files since 2001. Source: Ayuntamiento de Madrid, calidad del aire (CC BY 4.0).';
COMMENT ON COLUMN aire_madrid.obs.air_hourly.magnitude IS 'What was measured: ref.magnitudes (8 = NO2, 9 = PM2.5, 10 = PM10, 14 = O3).';
COMMENT ON COLUMN aire_madrid.obs.air_hourly.hour_start_at IS 'Start of the hour (the city labels hours by their end, local time: H01 = 00:00-01:00 Madrid).';
COMMENT ON COLUMN aire_madrid.obs.air_hourly.value IS 'Hourly mean in the unit of ref.magnitudes (µg/m³ for NO2). Only hours the city marks valid (V).';
COMMENT ON COLUMN aire_madrid.obs.air_hourly.is_validated IS 'True for the city''s validated history; false for real-time values.';

-- lhbox: format-version=3 partition=month(hour_start_at)
CREATE TABLE IF NOT EXISTS aire_madrid.obs.meteo_hourly (
  station_code INTEGER NOT NULL,
  magnitude INTEGER NOT NULL,
  hour_start_at TIMESTAMPTZ NOT NULL,
  value DOUBLE,
  is_validated BOOLEAN,
  source VARCHAR NOT NULL,
  __ingest_ts TIMESTAMPTZ
);
COMMENT ON TABLE aire_madrid.obs.meteo_hourly IS 'Hourly weather at the city''s 26 weather stations (wind, temperature, humidity, pressure, radiation, rain): same codes and shape as obs.air_hourly. Source: Ayuntamiento de Madrid, datos meteorológicos (CC BY 4.0).';

-- lhbox: format-version=3 partition=day(observed_at)
CREATE TABLE IF NOT EXISTS aire_madrid.obs.traffic (
  observed_at TIMESTAMPTZ NOT NULL,
  point_id INTEGER NOT NULL,
  vehicles_per_hour INTEGER,
  occupancy_pct INTEGER,
  load_pct INTEGER,
  service_level INTEGER,
  speed_kmh INTEGER,
  is_error BOOLEAN,
  __ingest_ts TIMESTAMPTZ
);
COMMENT ON TABLE aire_madrid.obs.traffic IS 'Every ~5 minutes, each of Madrid''s ~4,900 traffic measurement points: flow, occupancy, load and (on the M-30) speed. Source: Informo, Ayuntamiento de Madrid (pm.xml, CC BY 4.0).';
COMMENT ON COLUMN aire_madrid.obs.traffic.service_level IS '0 fluid, 1 slow, 2 queues, 3 congested; -1 no data.';
COMMENT ON COLUMN aire_madrid.obs.traffic.speed_kmh IS 'Mean speed, only on the M-30 and ring roads.';
COMMENT ON COLUMN aire_madrid.obs.traffic.is_error IS 'The city flags the reading as an error.';

-- lhbox: format-version=3 partition=month(polled_at)
CREATE TABLE IF NOT EXISTS aire_madrid.obs.protocol_feed (
  polled_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL,
  scenario VARCHAR,
  scenario_date VARCHAR,
  reasons VARCHAR,
  measures VARCHAR,
  exceptions VARCHAR,
  incidents_in_feed BIGINT,
  __ingest_ts TIMESTAMPTZ
);
COMMENT ON TABLE aire_madrid.obs.protocol_feed IS 'The council''s pollution protocol as Informo publishes it, polled every 15 minutes: one row per poll, is_active false outside an episode. The live ground truth from the day this table started; ref.past_episodes holds 2017-2021.';

-- lhbox: format-version=3 partition=month(issued_at)
CREATE TABLE IF NOT EXISTS aire_madrid.obs.weather_forecast (
  issued_at TIMESTAMPTZ NOT NULL,
  hour_start_at TIMESTAMPTZ NOT NULL,
  temperature_c DOUBLE,
  precipitation_mm DOUBLE,
  relative_humidity_pct DOUBLE,
  wind_speed_kmh DOUBLE,
  wind_direction VARCHAR,
  sky VARCHAR,
  source VARCHAR NOT NULL,
  __ingest_ts TIMESTAMPTZ
);
COMMENT ON TABLE aire_madrid.obs.weather_forecast IS 'AEMET''s hourly forecast for the municipality of Madrid, every issue kept (issued_at), so a forecast can be compared with the weather that followed. Calm, dry, clear winter nights are when NO2 builds up. Source: AEMET OpenData (attribution required).';
