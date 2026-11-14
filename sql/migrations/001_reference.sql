-- Reference tables: stations and their protocol zones, pollutant and weather codes, the rule sets, traffic points,
-- and the city's own record of past NO2 episodes. Loaded by sql/reference/load_reference.sql.
-- `lhbox migrate` format: plain DuckDB DDL, applied once in file order; `-- lhbox:` lines carry what DDL cannot.

CREATE SCHEMA IF NOT EXISTS aire_madrid.ref;
CREATE SCHEMA IF NOT EXISTS aire_madrid.obs;
CREATE SCHEMA IF NOT EXISTS aire_madrid.now;
CREATE SCHEMA IF NOT EXISTS aire_madrid.agent;

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.ref.stations (
  station_code INTEGER NOT NULL,
  station_name VARCHAR NOT NULL,
  protocol_zone INTEGER NOT NULL,
  station_type VARCHAR,
  longitude DOUBLE,
  latitude DOUBLE,
  is_ser_background BOOLEAN NOT NULL,
  measures_no2 BOOLEAN NOT NULL,
  out_of_service_since DATE
);
COMMENT ON TABLE aire_madrid.ref.stations IS 'The 24 stations of Madrid city''s air-quality network, with the zone (1-5) the NO2 protocol of 10 Dec 2018 assigns each. The zone comes from the protocol text, not from geometry (Barrio del Pilar is zone 1 although north of the M-30). Source: Ayuntamiento de Madrid, estaciones de control (datos.madrid.es 212629, CC BY 4.0) and the protocol, Anexo I.';
COMMENT ON COLUMN aire_madrid.ref.stations.station_code IS '8-digit code, 28079 + station number (28079008 = Escuelas Aguirre). Joins obs.air_hourly.';
COMMENT ON COLUMN aire_madrid.ref.stations.protocol_zone IS 'NO2 protocol zone: 1 inside the M-30, 2 south-east, 3 north-east, 4 north-west, 5 south-west.';
COMMENT ON COLUMN aire_madrid.ref.stations.station_type IS 'Urbana tráfico, Urbana fondo or Suburbana, as the city classifies it.';
COMMENT ON COLUMN aire_madrid.ref.stations.is_ser_background IS 'One of the 12 urban-background stations whose daily NO2 mean drives the SER parking surcharge (+60 % above 60, +100 % above 70 µg/m³).';
COMMENT ON COLUMN aire_madrid.ref.stations.out_of_service_since IS 'Set when the station stopped reporting (Urb. Embajada: Metro line 5 works, 1 Sep 2025).';

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.ref.magnitudes (
  magnitude INTEGER NOT NULL,
  name VARCHAR NOT NULL,
  unit VARCHAR NOT NULL
);
COMMENT ON TABLE aire_madrid.ref.magnitudes IS 'The city''s codes for what a station measures, shared by the air-quality and the weather networks (8 = NO2 in µg/m³, 83 = temperature in °C). Source: the city''s interpreter of its air-quality files.';

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.ref.rules (
  rule_set VARCHAR NOT NULL,
  rule_id VARCHAR NOT NULL,
  pollutant VARCHAR NOT NULL,
  averaging VARCHAR NOT NULL,
  threshold_ugm3 DOUBLE NOT NULL,
  allowed_per_year INTEGER,
  in_force_from DATE,
  description VARCHAR NOT NULL,
  source_url VARCHAR NOT NULL
);
COMMENT ON TABLE aire_madrid.ref.rules IS 'Every rule Madrid''s air is measured against here, as data: the EU limits in force today (Directive 2008/50/EC), the EU limits for 2030 (Directive (EU) 2024/2881), the WHO 2021 guidelines, and the city''s own triggers (NO2 protocol levels, SER parking surcharge). A stricter rule set is a new rule_set, not new code.';
COMMENT ON COLUMN aire_madrid.ref.rules.averaging IS 'hour, day (calendar-day mean of the hourly values, Madrid days) or year.';
COMMENT ON COLUMN aire_madrid.ref.rules.allowed_per_year IS 'Exceedances a year that still comply (hour or day rules); null when none is allowed or for annual means.';

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.ref.past_episodes (
  day DATE NOT NULL,
  episode VARCHAR NOT NULL,
  level_reached VARCHAR,
  scenario_in_force VARCHAR,
  source VARCHAR NOT NULL
);
COMMENT ON TABLE aire_madrid.ref.past_episodes IS 'The council''s NO2 protocol decisions 2017-2021, one row per day of each episode: the level reached that day (and in which zones) and the scenario in force. Built from the city''s per-episode reports and its activations CSV (datos.madrid.es 300403). No episode has happened since 17 Dec 2021: every day absent here is a day without one. The ground truth for back-tests.';
