-- Load the ref.* tables once, into empty tables (run after `lhbox migrate`):
--   lhbox duckdb --catalog aire_madrid < sql/reference/load_reference.sql
-- Every value has its source in a comment or a source column. Re-running appends duplicates: empty the table first.

-- Stations: datos.madrid.es 212629 (estaciones de control, CC BY 4.0); zone from the NO2 protocol (10 Dec 2018,
-- Anexo I); the 12 SER background stations from the city's SER dynamic-tariff note (25 Jan 2022).
INSERT INTO aire_madrid.ref.stations VALUES
  (28079004, 'Plaza de España', 1, 'Urbana tráfico', -3.7122567, 40.4238823, false, true, NULL),
  (28079008, 'Escuelas Aguirre', 1, 'Urbana tráfico', -3.6823158, 40.4215533, false, true, NULL),
  (28079011, 'Ramón y Cajal', 1, 'Urbana tráfico', -3.6773491, 40.4514734, false, true, NULL),
  (28079016, 'Arturo Soria', 3, 'Urbana fondo', -3.6392422, 40.4400457, true, true, NULL),
  (28079017, 'Villaverde', 5, 'Urbana fondo', -3.7133167, 40.347147, true, true, NULL),
  (28079018, 'Farolillo', 5, 'Urbana fondo', -3.7318356, 40.3947825, true, true, NULL),
  (28079024, 'Casa de Campo', 4, 'Suburbana', -3.7473445, 40.4193577, false, true, NULL),
  (28079027, 'Barajas Pueblo', 3, 'Urbana fondo', -3.5800258, 40.4769179, true, true, NULL),
  (28079035, 'Plaza del Carmen', 1, 'Urbana fondo', -3.7031662, 40.4192091, true, true, NULL),
  (28079036, 'Moratalaz', 2, 'Urbana tráfico', -3.6453104, 40.4079517, false, true, NULL),
  (28079038, 'Cuatro Caminos', 1, 'Urbana tráfico', -3.7071303, 40.4455439, false, true, NULL),
  (28079039, 'Barrio del Pilar', 1, 'Urbana tráfico', -3.7115364, 40.4782322, false, true, NULL),
  (28079040, 'Vallecas', 2, 'Urbana fondo', -3.6515286, 40.3881478, true, true, NULL),
  (28079047, 'Méndez Álvaro', 1, 'Urbana fondo', -3.6868138, 40.3980991, true, true, NULL),
  (28079048, 'Castellana', 1, 'Urbana tráfico', -3.6903729, 40.4398904, false, true, NULL),
  (28079049, 'Parque del Retiro', 1, 'Urbana fondo', -3.6824999, 40.4144444, true, true, NULL),
  (28079050, 'Plaza Castilla', 1, 'Urbana tráfico', -3.6887449, 40.4655841, false, true, NULL),
  (28079054, 'Ensanche de Vallecas', 2, 'Urbana fondo', -3.6121394, 40.3730118, true, true, NULL),
  (28079055, 'Urb. Embajada', 3, 'Urbana fondo', -3.5805649, 40.4623628, true, true, DATE '2025-09-01'),
  (28079056, 'Plaza Elíptica', 5, 'Urbana tráfico', -3.7187679, 40.3850336, false, true, NULL),
  (28079057, 'Sanchinarro', 3, 'Urbana fondo', -3.6605173, 40.4942012, true, true, NULL),
  (28079058, 'El Pardo', 4, 'Suburbana', -3.7746101, 40.5180701, false, true, NULL),
  (28079059, 'Juan Carlos I', 3, 'Suburbana', -3.609031, 40.465144, false, true, NULL),
  (28079060, 'Tres Olivos', 3, 'Urbana fondo', -3.6897308, 40.5005477, true, true, NULL);

-- Codes: the city's "intérprete de ficheros de calidad del aire" and its weather-data structure document.
INSERT INTO aire_madrid.ref.magnitudes VALUES
  (1, 'SO2 (sulphur dioxide)', 'µg/m³'), (6, 'CO (carbon monoxide)', 'mg/m³'), (7, 'NO (nitrogen monoxide)', 'µg/m³'),
  (8, 'NO2 (nitrogen dioxide)', 'µg/m³'), (9, 'PM2.5', 'µg/m³'), (10, 'PM10', 'µg/m³'), (12, 'NOx (nitrogen oxides)', 'µg/m³'),
  (14, 'O3 (ozone)', 'µg/m³'), (20, 'Toluene', 'µg/m³'), (30, 'Benzene', 'µg/m³'), (35, 'Ethylbenzene', 'µg/m³'),
  (42, 'Total hydrocarbons', 'mg/m³'), (43, 'Methane', 'mg/m³'), (44, 'Non-methane hydrocarbons', 'mg/m³'),
  (81, 'Wind speed', 'm/s'), (82, 'Wind direction', 'degrees'), (83, 'Temperature', '°C'), (86, 'Relative humidity', '%'),
  (87, 'Pressure', 'mbar'), (88, 'Solar radiation', 'W/m²'), (89, 'Precipitation', 'l/m²');

-- Rules. EU today: Directive 2008/50/EC. EU 2030: Directive (EU) 2024/2881, Annex I (limit values to be met by
-- 1 Jan 2030). WHO: Global Air Quality Guidelines 2021 (24-hour levels are the 99th percentile, about 3-4 days a
-- year). Protocol: Madrid NO2 protocol of 10 Dec 2018 (levels need 2 stations of a zone for 2 consecutive hours or
-- 3 anywhere for 3; alerta 3 stations of a zone, 2 in zone 4, for 3 hours). SER: OMS art. 52.2.e, daily mean of
-- the 12 background stations the day before.
INSERT INTO aire_madrid.ref.rules VALUES
  ('eu2008', 'eu2008.no2.hour', 'NO2', 'hour', 200, 18, DATE '2010-01-01', 'Hourly mean above 200 µg/m³, at most 18 hours a year per station', 'https://eur-lex.europa.eu/eli/dir/2008/50/oj'),
  ('eu2008', 'eu2008.no2.year', 'NO2', 'year', 40, NULL, DATE '2010-01-01', 'Annual mean at most 40 µg/m³ per station', 'https://eur-lex.europa.eu/eli/dir/2008/50/oj'),
  ('eu2008', 'eu2008.pm10.day', 'PM10', 'day', 50, 35, DATE '2005-01-01', 'Daily mean above 50 µg/m³, at most 35 days a year', 'https://eur-lex.europa.eu/eli/dir/2008/50/oj'),
  ('eu2008', 'eu2008.pm10.year', 'PM10', 'year', 40, NULL, DATE '2005-01-01', 'Annual mean at most 40 µg/m³', 'https://eur-lex.europa.eu/eli/dir/2008/50/oj'),
  ('eu2008', 'eu2008.pm25.year', 'PM2.5', 'year', 25, NULL, DATE '2015-01-01', 'Annual mean at most 25 µg/m³', 'https://eur-lex.europa.eu/eli/dir/2008/50/oj'),
  ('eu2030', 'eu2030.no2.hour', 'NO2', 'hour', 200, 3, DATE '2030-01-01', 'Hourly mean above 200 µg/m³, at most 3 hours a year per station', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.no2.day', 'NO2', 'day', 50, 18, DATE '2030-01-01', 'Daily mean above 50 µg/m³, at most 18 days a year per station', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.no2.year', 'NO2', 'year', 20, NULL, DATE '2030-01-01', 'Annual mean at most 20 µg/m³ per station', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.pm10.day', 'PM10', 'day', 45, 18, DATE '2030-01-01', 'Daily mean above 45 µg/m³, at most 18 days a year', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.pm10.year', 'PM10', 'year', 20, NULL, DATE '2030-01-01', 'Annual mean at most 20 µg/m³', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.pm25.day', 'PM2.5', 'day', 25, 18, DATE '2030-01-01', 'Daily mean above 25 µg/m³, at most 18 days a year', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('eu2030', 'eu2030.pm25.year', 'PM2.5', 'year', 10, NULL, DATE '2030-01-01', 'Annual mean at most 10 µg/m³', 'https://eur-lex.europa.eu/eli/dir/2024/2881/oj'),
  ('who2021', 'who2021.no2.day', 'NO2', 'day', 25, 3, NULL, '24-hour mean above 25 µg/m³ on at most 3-4 days a year (99th percentile)', 'https://www.who.int/publications/i/item/9789240034228'),
  ('who2021', 'who2021.no2.year', 'NO2', 'year', 10, NULL, NULL, 'Annual mean at most 10 µg/m³', 'https://www.who.int/publications/i/item/9789240034228'),
  ('who2021', 'who2021.pm25.day', 'PM2.5', 'day', 15, 3, NULL, '24-hour mean above 15 µg/m³ on at most 3-4 days a year', 'https://www.who.int/publications/i/item/9789240034228'),
  ('who2021', 'who2021.pm25.year', 'PM2.5', 'year', 5, NULL, NULL, 'Annual mean at most 5 µg/m³', 'https://www.who.int/publications/i/item/9789240034228'),
  ('protocol2018', 'protocol.no2.preaviso', 'NO2', 'hour', 180, NULL, DATE '2018-12-10', 'Preaviso: above 180 µg/m³ at 2 stations of a zone for 2 consecutive hours, or 3 anywhere for 3', 'https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Alta-contaminacion-protocolos-y-episodios/Dioxido-de-nitrogeno-NO2-/?vgnextfmt=default&vgnextchannel=ac8e471c5c503710VgnVCM1000008a4a900aRCRD'),
  ('protocol2018', 'protocol.no2.aviso', 'NO2', 'hour', 200, NULL, DATE '2018-12-10', 'Aviso: above 200 µg/m³, same station and hour counts as preaviso', 'https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Alta-contaminacion-protocolos-y-episodios/Dioxido-de-nitrogeno-NO2-/?vgnextfmt=default&vgnextchannel=ac8e471c5c503710VgnVCM1000008a4a900aRCRD'),
  ('protocol2018', 'protocol.no2.alerta', 'NO2', 'hour', 400, NULL, DATE '2018-12-10', 'Alerta: above 400 µg/m³ at 3 stations of a zone (2 in zone 4) for 3 consecutive hours', 'https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Alta-contaminacion-protocolos-y-episodios/Dioxido-de-nitrogeno-NO2-/?vgnextfmt=default&vgnextchannel=ac8e471c5c503710VgnVCM1000008a4a900aRCRD'),
  ('ser2022', 'ser.no2.surcharge60', 'NO2', 'day', 60, NULL, DATE '2022-01-26', 'SER parking +60 % the next day when the mean of the 12 background stations exceeds 60 µg/m³', 'https://www.madrid.es/portales/munimadrid/es/Inicio/Actualidad/Noticias/La-nueva-tarifa-dinamica-del-SER-entra-en-funcionamiento-este-miercoles/?vgnextoid=7cb226793119e710VgnVCM2000001f4a900aRCRD&vgnextchannel=a12149fa40ec9410VgnVCM100000171f5a0aRCRD'),
  ('ser2022', 'ser.no2.surcharge70', 'NO2', 'day', 70, NULL, DATE '2022-01-26', 'SER parking +100 % the next day when that mean exceeds 70 µg/m³', 'https://www.madrid.es/portales/munimadrid/es/Inicio/Actualidad/Noticias/La-nueva-tarifa-dinamica-del-SER-entra-en-funcionamiento-este-miercoles/?vgnextoid=7cb226793119e710VgnVCM2000001f4a900aRCRD&vgnextchannel=a12149fa40ec9410VgnVCM100000171f5a0aRCRD');

-- Past episodes, 2017-2021: the city's per-episode reports (R, "Secuencia de superaciones y escenarios alcanzados",
-- airedemadrid.madrid.es/.../ProtocoloNO2/Episodios/) and its activations CSV (C, datos.madrid.es 300403).
-- One row per day; the level is the one reached that day, the scenario the one in force that day.
INSERT INTO aire_madrid.ref.past_episodes
SELECT d::DATE, episode, CASE WHEN d = first_day THEN level_reached END, scenario, source
FROM (VALUES
  ('Epi4',  DATE '2017-03-09', DATE '2017-03-09', DATE '2017-03-09', 'aviso (Z1)', 'none', 'R'),
  ('Epi4',  DATE '2017-03-10', DATE '2017-03-10', NULL, NULL, '1', 'R'),
  ('Epi4',  DATE '2017-03-11', DATE '2017-03-11', NULL, NULL, '2', 'R'),
  ('Epi5',  DATE '2017-09-28', DATE '2017-09-28', DATE '2017-09-28', 'preaviso (Z1)', 'none', 'R'),
  ('Epi5',  DATE '2017-09-29', DATE '2017-10-01', NULL, NULL, '1', 'R'),
  ('Epi6',  DATE '2017-10-10', DATE '2017-10-10', DATE '2017-10-10', 'preaviso (Z1, Z5)', 'none', 'R'),
  ('Epi6',  DATE '2017-10-11', DATE '2017-10-11', DATE '2017-10-11', 'aviso (Z1), preaviso (Z5)', '1', 'R'),
  ('Epi6',  DATE '2017-10-12', DATE '2017-10-12', DATE '2017-10-12', 'preaviso (Z1)', '1', 'R'),
  ('Epi6',  DATE '2017-10-13', DATE '2017-10-14', NULL, NULL, '2', 'R'),
  ('Epi6',  DATE '2017-10-15', DATE '2017-10-15', NULL, NULL, '1', 'R'),
  ('Epi7',  DATE '2017-10-23', DATE '2017-10-23', DATE '2017-10-23', 'aviso (Z1)', 'none', 'R'),
  ('Epi7',  DATE '2017-10-24', DATE '2017-10-24', DATE '2017-10-24', 'preaviso (Z1)', '1', 'R'),
  ('Epi7',  DATE '2017-10-25', DATE '2017-10-25', DATE '2017-10-25', 'aviso (Z1, Z3)', '2', 'R'),
  ('Epi7',  DATE '2017-10-26', DATE '2017-10-26', DATE '2017-10-26', 'aviso (Z1), preaviso (Z3)', '2', 'R'),
  ('Epi7',  DATE '2017-10-27', DATE '2017-10-27', NULL, NULL, '2', 'R'),
  ('Epi7',  DATE '2017-10-28', DATE '2017-10-28', NULL, NULL, '1', 'R'),
  ('Epi8',  DATE '2017-11-15', DATE '2017-11-15', DATE '2017-11-15', 'preaviso (Z1)', 'none', 'R'),
  ('Epi8',  DATE '2017-11-16', DATE '2017-11-17', DATE '2017-11-16', 'preaviso (Z1)', '1', 'R'),
  ('Epi8',  DATE '2017-11-18', DATE '2017-11-20', DATE '2017-11-18', 'preaviso (Z1; Z5 on the 20th)', '2', 'R'),
  ('Epi8',  DATE '2017-11-21', DATE '2017-11-21', DATE '2017-11-21', 'aviso (Z1, Z5), preaviso (Z3)', '2', 'R'),
  ('Epi8',  DATE '2017-11-22', DATE '2017-11-22', DATE '2017-11-22', 'preaviso (Z3)', '2', 'R'),
  ('Epi8',  DATE '2017-11-23', DATE '2017-11-23', NULL, NULL, '2', 'R'),
  ('Epi8',  DATE '2017-11-24', DATE '2017-11-24', NULL, NULL, '1', 'R'),
  ('Epi9',  DATE '2017-12-05', DATE '2017-12-05', DATE '2017-12-05', 'aviso (Z1, Z3), preaviso (Z5)', 'none', 'R'),
  ('Epi9',  DATE '2017-12-06', DATE '2017-12-06', NULL, NULL, '1', 'R'),
  ('Epi9',  DATE '2017-12-07', DATE '2017-12-07', NULL, NULL, '2', 'R'),
  ('Epi9',  DATE '2017-12-08', DATE '2017-12-08', NULL, NULL, '1', 'R'),
  ('Epi10', DATE '2018-01-23', DATE '2018-01-23', DATE '2018-01-23', 'preaviso (Z1)', 'none', 'R'),
  ('Epi10', DATE '2018-01-24', DATE '2018-01-24', NULL, NULL, '1', 'R'),
  ('Epi11', DATE '2018-12-04', DATE '2018-12-04', DATE '2018-12-04', 'aviso (Z1)', 'none', 'R'),
  ('Epi11', DATE '2018-12-05', DATE '2018-12-05', NULL, NULL, '1', 'R'),
  ('Epi11', DATE '2018-12-06', DATE '2018-12-06', NULL, NULL, '2 (holiday: no SER measure)', 'R'),
  ('Epi11', DATE '2018-12-07', DATE '2018-12-07', NULL, NULL, '1', 'R'),
  ('Epi12', DATE '2018-12-10', DATE '2018-12-10', DATE '2018-12-10', 'preaviso (Z1, Z3), aviso (city)', 'none', 'R'),
  ('Epi12', DATE '2018-12-11', DATE '2018-12-11', NULL, NULL, '1', 'R, C'),
  ('Epi12', DATE '2018-12-12', DATE '2018-12-12', NULL, NULL, '2', 'R, C'),
  ('Epi13', DATE '2018-12-24', DATE '2018-12-24', DATE '2018-12-24', 'preaviso (Z1)', 'none', 'R'),
  ('Epi13', DATE '2018-12-25', DATE '2018-12-25', NULL, NULL, '1', 'R, C'),
  ('Epi13', DATE '2018-12-26', DATE '2018-12-26', DATE '2018-12-26', 'aviso (Z1)', '1', 'R, C'),
  ('Epi13', DATE '2018-12-27', DATE '2018-12-27', NULL, NULL, '1', 'R, C'),
  ('Epi13', DATE '2018-12-28', DATE '2018-12-28', NULL, NULL, '2 (traffic ban listed in C, suspended per R)', 'R, C'),
  ('Epi14', DATE '2018-12-31', DATE '2018-12-31', DATE '2018-12-31', 'preaviso (Z1)', 'none', 'R'),
  ('Epi14', DATE '2019-01-01', DATE '2019-01-06', DATE '2019-01-04', 'preaviso (city) on 4 Jan', '1', 'R, C'),
  ('Epi15', DATE '2019-01-14', DATE '2019-01-14', DATE '2019-01-14', 'aviso (Z1), preaviso (Z2, Z3, Z5, city)', 'none', 'R'),
  ('Epi15', DATE '2019-01-15', DATE '2019-01-15', DATE '2019-01-15', 'preaviso (Z5)', '1', 'R, C'),
  ('Epi15', DATE '2019-01-16', DATE '2019-01-17', NULL, NULL, '2', 'R, C'),
  ('Epi15', DATE '2019-01-18', DATE '2019-01-18', NULL, NULL, '1', 'R, C'),
  ('Epi16', DATE '2019-02-25', DATE '2019-02-25', DATE '2019-02-25', 'preaviso (Z1, city)', 'none', 'R'),
  ('Epi16', DATE '2019-02-26', DATE '2019-03-01', NULL, NULL, '1', 'R, C'),
  ('Epi17', DATE '2020-01-08', DATE '2020-01-08', DATE '2020-01-08', 'preaviso (Z1, Z3, city)', 'none', 'R'),
  ('Epi17', DATE '2020-01-09', DATE '2020-01-10', NULL, NULL, '1', 'R, C'),
  ('2021-a', DATE '2021-01-16', DATE '2021-01-16', DATE '2021-01-16', 'preaviso (Z1)', 'none', 'R'),
  ('2021-a', DATE '2021-01-17', DATE '2021-01-19', DATE '2021-01-18', 'preaviso (Z5) on 18 Jan', '1', 'R, C'),
  ('2021-b', DATE '2021-12-15', DATE '2021-12-15', DATE '2021-12-15', 'preaviso (Z1, city)', 'none', 'R'),
  ('2021-b', DATE '2021-12-16', DATE '2021-12-17', NULL, NULL, '1', 'R, C')
) AS t(episode, d_from, d_to, first_day, level_reached, scenario, source),
  generate_series(d_from, d_to, INTERVAL 1 DAY) AS g(d);
