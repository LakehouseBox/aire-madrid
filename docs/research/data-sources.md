# r133: data sources for the Madrid NO2-protocol agent demo

Tested 2026-11-14 23:15–23:45 UTC (00:15–00:45 Madrid, 15 Nov) from a laptop with `curl -A "Mozilla/5.0"`, DuckDB CLI 1.5.5 and
DuckDB 2.0.0 (python, scratch venv). Downloads were kept locally. [verified] = a real request returned the data
described here; [unverified] = documented or searched, not fetched.

## Read first: the portal moved, and one DuckDB setting matters

- **datos.madrid.es is now CKAN.** The old `/egob/catalogo/<id>.csv` links answer 302 to
  `/dataset/<id>/resource/<rid>/download/...`. The CKAN API works: `https://datos.madrid.es/api/3/action/package_show?id=<id>`
  and `package_search?q=...` [verified]. Some resources (`datastore_active: true`) are also in the CKAN datastore. The portal is
  still flaky: several requests hung 60–120 s and succeeded on retry (stations list: timeout, then 0.5 s). A poller must retry.
- **Every real-time feed is served by `ciudadesabiertas.madrid.es/dynamicAPI`**, which answers HEAD with `Content-Length: 1`.
  DuckDB then reads one byte ("Invalid unicode ... not utf-8"). **Fix: `SET force_download = true;`** before
  `read_csv`/`read_json` on those URLs [verified, 1.5.5 and 2.0].
- **The "Desde 2025" history files have a dated filename** (`..._8_20261113_210103.csv`) that changes on each monthly refresh:
  resolve the current URL through `package_show` (or `resource_show?id=201200-1-calidad-aire-horario-csv`) rather than hard-coding.
- **The yearly zips (2001–2024) are readable in DuckDB with the community `zipfs` extension**, including straight over HTTPS:
  `INSTALL zipfs FROM community; LOAD zipfs; SELECT ... FROM read_csv('zip://https://.../201200-6-calidad-aire-horario-zip.zip/dic_mo19.csv', delim=';', header=true, all_varchar=true)` → 744 NO2 rows for Dec 2019 [verified]. Whether the scheduled-SQL runtime allows community extensions is for us to check; otherwise a one-off backfill script unzips.

## 1. Air quality, Madrid city network

### 1a. Real-time hourly (today so far) [verified]
- Dataset: `212531-0-calidad-aire-tiempo-real` (CC BY 4.0, "UPDATE_CONT").
- URLs (same content): `https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/calair_tiemporeal.csv?pageSize=5000`
  (also `.json`, `.xml`). Old `mambiente.madrid.es/opendata/horario.txt` no longer resolves (DNS).
- Request: `curl -A "Mozilla/5.0" -L "https://datos.madrid.es/egob/catalogo/212531-10515086-calidad-aire-tiempo-real.csv"` →
  302 → the CSV above; 200, 18,983 B, 1.0 s, `text/csv`, UTF-8 with BOM, `;`-delimited, CRLF.
- Excerpt:
  ```
  PROVINCIA;MUNICIPIO;ESTACION;MAGNITUD;PUNTO_MUESTREO;ANO;MES;DIA;H01;V01;H02;V02;...;H24;V24
  28;079;11;8;28079011_8_8;2026;11;14;8;V;6;V;4;V;3;V;3;V;3;V;4;V;6;V;11;V;12;V;19;V;...;12;V
  ```
- Shape: one row per station × magnitude × day; 126 rows; **23 stations report NO2 (MAGNITUD 8)** (4, 8, 11, 16, 17, 18, 24,
  27, 35, 36, 38, 39, 40, 47, 48, 49, 50, 54, 56, 57, 58, 59, 60). `Hxx` = mean of hour ending xx:00 local; `Vxx` = `V` valid,
  `N` not valid/not yet measured. Magnitude codes (intérprete PDF): 1 SO2, 6 CO, 7 NO, 8 NO2, 9 PM2.5, 10 PM10, 12 NOx, 14 O3,
  20 toluene, 30 benzene, 35 ethylbenzene, 42 HCT, 43 CH4, 44 NMHC. `PUNTO_MUESTREO` = `<station8>_<magnitude>_<technique>`.
- Cadence/latency: covers the current local day only; at 00:17 local the file still held all 24 hours of the 14th (so the day's
  last hour was in within ~17 min); hourly refresh. JSON API pages (`page`, `totalRecords`, `contentMD5`).
- Interpreter PDF: `https://datos.madrid.es/dataset/212531-0-calidad-aire-tiempo-real/resource/212531-4-calidad-aire-tiempo-real/download/interprete_ficheros_20calidad_20del_20aire_global.pdf`.

**Working DuckDB query (NO2, one row per station-hour, valid only)** [verified: 552 rows = 23 × 24, both 1.5.5 and 2.0]:
```sql
SET force_download = true;  -- the API answers HEAD with Content-Length: 1
WITH raw AS (
  SELECT * FROM read_csv('https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/calair_tiemporeal.csv?pageSize=5000',
                         delim=';', header=true, all_varchar=true)
  WHERE MAGNITUD = '8'),                                   -- 8 = NO2
vals  AS (UNPIVOT (SELECT ESTACION, ANO, MES, DIA, COLUMNS('^H\d\d$') FROM raw) ON COLUMNS('^H') INTO NAME h VALUE v),
flags AS (UNPIVOT (SELECT ESTACION, ANO, MES, DIA, COLUMNS('^V\d\d$') FROM raw) ON COLUMNS('^V') INTO NAME h VALUE f)
SELECT make_timestamp(vals.ANO::INT, vals.MES::INT, vals.DIA::INT, 0, 0, 0) + to_hours(substr(vals.h,2)::INT) AS hour_end_local,
       vals.ESTACION::INT AS station, v::DOUBLE AS no2_ugm3, f AS validity
FROM vals JOIN flags ON vals.ESTACION=flags.ESTACION AND vals.ANO=flags.ANO AND vals.MES=flags.MES AND vals.DIA=flags.DIA
                     AND substr(vals.h,2)=substr(flags.h,2)
WHERE f = 'V';
```
(Exact text tested is in `no2_live.sql` in the research folder.)
Note `hour_end_local` is Europe/Madrid wall time (H24 = midnight of the next day).

### 1b. Real-time accumulated (rolling ~30 days) [verified]
- Dataset `300755-0-calidad-aire-tiempo-real-acumula`:
  `https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/calair_tiemporeal_ult.csv?pageSize=5000` (+ `.json`, `.xml`).
- Same format. At test time: 2026-10-16 → 2026-11-14, 3,780 rows. **This closes the gap** between the monthly history file
  (ends at last month's end) and today, and lets a poller that missed hours catch up. Not yet validated data (real-time).

### 1c. Historical hourly since 2001 [verified]
- Dataset `201200-0-calidad-aire-horario` (CC BY 4.0, MONTHLY; metadata modified 2026-11-13).
- **2025 → last complete month, one plain CSV** (22.2 MB, also JSON 77 MB / XML 91 MB):
  `https://datos.madrid.es/dataset/201200-0-calidad-aire-horario/resource/201200-1-calidad-aire-horario-csv/download/201200-0-calidad-aire-horario_8_20261113_210103.csv`
  → 200, 22,194,930 B in 0.95 s; 84,162 rows; quoted `;` CSV, same columns as 1a. DuckDB reads it directly over HTTPS (1.4 s):
  NO2 2025-01 … 2026-10, 23 stations each month. Last day 2026-10-31 (refreshed ~13th of the following month).
- **2001–2024: one zip per year** (5–7.5 MB), each holding 12 months × {csv, txt, xml}, e.g. 2019:
  `.../resource/201200-6-calidad-aire-horario-zip/download/201200-6-calidad-aire-horario-zip.zip` (`ene_mo19.csv` … `dic_mo19.csv`).
  2001 zip checked: identical CSV header (values zero-padded, `00020`). The `.txt` is the older comma variant
  (`28,079,004,01,38,02,2019,12,01,00006,V,...`). 2024's zip has an `Anio24/` folder prefix. Full resource list (year→rid) via
  `package_show`. Total ~150 MB of zips for 24 years.
- Caveat for baselines: the network was reorganised in 2009–2010 (stations closed/renumbered); use 2010+ for the 24-station set.
- Daily means since 2001 also exist (`201410-0-calidad-aire-diario`) [listed, not fetched].

### 1d. Stations (codes, coordinates, type) [verified]
- Dataset `212629-0-estaciones-control-aire`:
  `https://datos.madrid.es/dataset/212629-0-estaciones-control-aire/resource/212629-0-estaciones-control-aire-csv/download/212629-0-estaciones-control-aire-csv.csv`
  (5.3 KB, UTF-8 BOM, 24 stations; also XLS and `.geo`). First request timed out at 120 s, retry 0.5 s.
- Columns: `CODIGO;CODIGO_CORTO;ESTACION;DIRECCION;LONGITUD_ETRS89;LATITUD_ETRS89;ALTITUD;COD_TIPO;NOM_TIPO;NO2;SO2;CO;PM10;PM2_5;O3;BTX;...;COORDENADA_X_ETRS89;COORDENADA_Y_ETRS89;LONGITUD;LATITUD`
  e.g. `28079008;8;Escuelas Aguirre;...;UT;Urbana tráfico;X;X;X;X;X;X;X;...;-3.6823158;40.4215533`. Types UT (urban traffic),
  UF (urban background), S (suburban). Decimal LONGITUD/LATITUD columns are ready to use; UTM columns use comma decimals.
- **Not in the file: the protocol zone (1–5) of each station.** It is in the protocol decree (2018) / airedemadrid page; it is a
  24-row lookup the agent should carry as a table (source to cite: the 2021 decree PDF under
  `airedemadrid.madrid.es/.../ProtocoloNO2/Decretos/2021/20211216Decreto20210153099.pdf`, [unverified content]).

### 1e. Ground truth: past NO2 protocol activations [verified]
- Dataset `300403-0-calidad-aire-episodios-no2` (CC BY 4.0):
  `https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Portal/04_Bases/04%20Ficheros/JUEGO_DATOS_activacion_protocolo_NO2.csv`
  → 200, 4,064 B, ISO-8859-1, `;`, 44 rows.
  ```
  FECHA INICIO;HORA INICIO;FECHA FIN;HORA FIN;EPISODIO;ESCENARIO;MEDIDA;ÁMBITO GEOGRÁFICO;CATEGORÍA AMBIENTAL A;...;CERO
  11/12/2018;6:00;12/12/2018;5:59;1;1;REDUCCIÓN VELOCIDAD A 70 KM/H;M30 Y ACCESOS;1;1;1;1;1
  16/12/2021;6:00;17/12/2021;23:59;8;1;PROMOCIÓN TRANSPORTE PÚBLICO;TODA LA CIUDAD;;;;;
  ```
- 8 episodes, 2018-12-11 → 2021-12-17 (protocol in force since 2018-12-10); none recorded since. These are the labels to
  back-test the agent's recommendations against. Earlier episodes (2016–2018 protocol) are not in this file.
- Rules, from the official page (airedemadrid, NO2 protocol, fetched) [verified]: **preaviso** = 2 stations of one zone > 180
  µg/m³ for 2 consecutive hours, or 3 stations anywhere > 180 for 3 consecutive hours; **aviso** = same with 200; **alerta** =
  3 stations of one zone (2 in zone 4) > 400 for 3 hours. An episode starts only if, in addition, the meteorological forecast
  is unfavourable (stable atmosphere, poor ventilation). Five scenarios by level and persistence.

### 1f. EEA E2a "up-to-date" (alternative feed) [verified]
- API: `POST https://eeadmz1-downloads-api-appservice.azurewebsites.net/ParquetFile/urls` with
  `{"countries":["ES"],"cities":["Madrid"],"pollutants":["NO2"],"dataset":1,"source":"API"}` → a CSV list of Parquet URLs,
  one per sampling point, e.g. `https://eeadmz1batchservice02.blob.core.windows.net/airquality-p/ES/SP_28079008_8_8.parquet`.
  (dataset 1 = E2a up-to-date, 2 = E1a verified 2013+, 3 = AirBase 2002–2012; Swagger at `/swagger/v1/swagger.json`.)
- DuckDB reads the Parquet directly: Escuelas Aguirre 2026 = 6,887 hourly rows, 2026-01-01 → 2026-11-14 00:00, max 191 µg/m³.
  Columns `Samplingpoint, Pollutant, Start, End, Value, Unit, AggType, Validity, Verification, ResultTime, DataCapture, FkObservationLog`;
  missing = `-999` with `Validity -1`.
- Latency ~1 day (latest `End` 2026-11-14 00:00 at 23:30 UTC on the 14th; `ResultTime` 00:39), so **worse than the city feed
  for "today"**, but cleaner for backfill (Parquet, typed, validity) and the list also includes regional stations near Madrid.
  Licence: EEA data, reuse permitted with attribution (CC BY 4.0 per EEA policy) [licence unverified on this endpoint].

## 2. Air-quality forecasts

### 2a. Madrid's own forecast [partly verified]
- `airedemadrid.madrid.es` → Servicios y recomendaciones → **Predicción diaria**: "Índices de calidad del aire previstos para cada
  una de las cinco zonas ... Actualización diaria". It is an iframe of `https://analisiscalidadaire.madrid.es/prediccion`, which
  answered **403 Access Denied (Akamai)** to our scripted request. No open-data file or API for the city's NO2 forecast was found
  in the CKAN catalog. Treat as not machine-available.
- **AEMET's daily ventilation forecast for Madrid, published by the city** [verified]: a PDF per day,
  `https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Publicaciones/Prediccion_AEMET/Ficheros/2026/11_Noviembre/Ventilacion_MADRID_20261114.pdf`
  (240 KB; listing page keeps ~25 days, 2026-10-20 → 2026-11-14). Content: yesterday's situation and the forecast — synoptic
  situation, "inversión de niveles bajos persistente e intensa" (yes/no), low pressure, precipitation probability, wind
  ("Flojo SW"), **Ventilación: Favorable/Desfavorable**. This is exactly the protocol's "meteorological forecast" input. Not
  DuckDB-readable (PDF); an agent can read it, or a poller can `pdftotext` it into a row.

### 2b. Open-Meteo Air Quality API (CAMS Europe) [verified]
- `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=40.4168&longitude=-3.7038&hourly=nitrogen_dioxide,pm10,pm2_5,ozone&forecast_days=5&past_days=1&timezone=Europe/Madrid&domains=cams_europe`
  → 200, 5.8 KB JSON, 0.2 s; 144 hourly values, µg/m³, grid cell 40.4,-3.70 (0.1° ≈ 10 km). Excerpt 15 Nov:
  `00:00 7.8, ... 20:00 12.3`. Forecast horizon up to 5 days (4 days CAMS Europe), updated as CAMS runs (daily 00 UTC run).
- History: `start_date/end_date` back to 2013 works (2013-06-01 returned values). On episode days it is high: 2021-01-17 peaks
  121 µg/m³ (grid mean, so below station peaks). Note: history is CAMS analysis/reanalysis, not the forecast as issued.
- DuckDB: `SELECT unnest(hourly.time) t, unnest(hourly.nitrogen_dioxide) no2 FROM read_json('<url>')` works (no force_download).
- **Licence: data CC BY 4.0, but the free API is for non-commercial use only** (open-meteo.com/en/terms: "You may only use the
  free API services for non-commercial purposes"; < 10,000 calls/day, 5,000/h, 600/min). A company demo likely needs the paid
  API key (customer-api.open-meteo.com) or a self-hosted Open-Meteo, or CAMS directly (2c).

### 2c. Copernicus CAMS European AQ forecasts (ADS) [verified that a key is required]
- Catalogue: `https://ads.atmosphere.copernicus.eu/api/catalogue/v1/collections/cams-europe-air-quality-forecasts` → 200,
  licence CC-BY-4.0, 0.1° ensemble median of 11 models, daily, 4 days ahead, hourly.
- Retrieval `POST .../api/retrieve/v1/processes/cams-europe-air-quality-forecasts/execution` without a key → **401**. Needs a free
  ADS account + API key + licence acceptance (not registered). Output NetCDF/GRIB: not DuckDB-friendly; a poller would convert.

### 2d. CALIOPE (BSC) [unverified as data]
- `https://caliope.bsc.es/en/caliope-air-quality-forecast`: 48 h forecast for the Iberian Peninsula (4 km), Catalonia and
  Barcelona; "Updated 07:00 UTC on Fri 13 Nov 2026" at test time. Web viewer only; no public API or file feed found. Not usable
  for ingestion without asking BSC.

## 3. Weather

### 3a. Open-Meteo forecast [verified]
- `https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,precipitation,pressure_msl,boundary_layer_height,cloud_cover&forecast_days=3&timezone=Europe/Madrid`
  → 200, 4.5 KB, 0.21 s. **boundary_layer_height is available** (15 Nov 00:00–02:00: 385, 435, 445 m). Units km/h, °, mm, hPa, m.
  Up to 16 days; hourly model updates. Same licence caveat as 2b (free = non-commercial).
- **What was forecast the day before** (for honest back-tests): `previous-runs-api.open-meteo.com` with `*_previous_day1`
  variables [verified, recent days only], and `historical-forecast-api.open-meteo.com` (archived high-res forecasts, 2021-01-17
  returned values) [verified].

### 3b. Open-Meteo archive (ERA5) for backfill [verified]
- `https://archive-api.open-meteo.com/v1/archive?latitude=40.4168&longitude=-3.7038&start_date=2017-01-01&end_date=2017-01-03&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,precipitation,pressure_msl,boundary_layer_height&timezone=Europe/Madrid`
  → 200, 72 hours, all variables incl. boundary_layer_height (35 m on the 2017-01-01 inversion night). ERA5 1940→, ~5-day lag.

### 3c. AEMET OpenData [verified that a key is required]
- `https://opendata.aemet.es/opendata/api/prediccion/especifica/municipio/horaria/28079` without a key → 200 with
  `{"code": "80", "description": "Error, token not found in cache"}`. Needs a free API key (email registration; not done).
  Two-step: the call returns a JSON with a `datos` URL to fetch. Hourly municipal forecast (temp, wind, precip, ...), no boundary
  layer. Licence: AEMET reuse terms (attribution). The ventilation PDF (2a) is the AEMET product the protocol actually uses.

### 3d. Madrid city meteorological network [verified]
- **Same coded format as air quality** (PROVINCIA;MUNICIPIO;ESTACION;MAGNITUD;...;H01;V01...). Magnitudes: 81 wind speed (m/s),
  82 wind direction (°), 83 temperature (°C), 86 relative humidity (%), 87 pressure (mb), 88 solar radiation (W/m²),
  89 precipitation (l/m²).
- Real-time: `https://ciudadesabiertas.madrid.es/dynamicAPI/API/query/meteo_tiemporeal.csv?pageSize=5000` (dataset 300392;
  200, 15 KB, 92 rows, today) and rolling ~30 days `.../meteo_tiemporeal_ult.csv?pageSize=5000` (dataset 300754; 2026-10-16 →
  11-14). `SET force_download=true` needed in DuckDB, as in 1a.
- History (dataset `300352-0-meteorologicos-horarios`, since 2019): monthly CSV/TXT/XML per month 2019–2024 plus one "Desde 2025"
  CSV `.../resource/300352-180-meteorologicos-horarios-csv/download/300352-0-meteorologicos-horarios_41_20261113_213459.csv`
  (read by DuckDB over HTTPS: 26 stations, magnitudes 81–89, 2025-01 → 2026-10).
- Stations: `.../300360-0-meteorologicos-estaciones/resource/300360-1-meteorologicos-estaciones-csv/download/300360-1-meteorologicos-estaciones-csv.csv`
  (26 rows, ISO-8859-1, with which magnitudes each measures and decimal LONGITUD/LATITUD).

## 4. Traffic

### 4a. Informo real-time pm.xml [verified]
- `https://informo.madrid.es/informo/tmadrid/pm.xml` → 200, 2.19 MB, 0.23 s, `application/xml`, ETag + Last-Modified
  (Sat 14 Nov 23:20:02 GMT) so a poller can use conditional GETs. `<fecha_hora>15/11/2026 0:15:02</fecha_hora>`, ~5 min cadence.
- 4,904 `<pm>` elements; 4,852 have `descripcion`; 311 (M-30 / ring roads) carry `<velocidad>` instead of being urban;
  4,546 with `error = N`. Fields: idelem, descripcion, accesoAsociado, intensidad (veh/h), ocupacion (%), carga (0–100),
  nivelServicio, intensidadSat, error, subarea, st_x/st_y (UTM ETRS89 30N, comma decimals), velocidad (km/h, M-30 only).
- **DuckDB parses it with regex** (no XML extension needed). Working query (1.5.5 CLI 0.33 s; 2.0 python 0.42 s; 4,904 rows):
```sql
WITH src AS (SELECT content FROM read_text('https://informo.madrid.es/informo/tmadrid/pm.xml')),
pms AS (
  SELECT regexp_extract(content, '<fecha_hora>([^<]*)</fecha_hora>', 1) AS fecha_hora,
         unnest(regexp_extract_all(content, '<pm>(.*?)</pm>', 1, 's')) AS pm      -- 's': dot matches newline
  FROM src)
SELECT
  strptime(fecha_hora, '%d/%m/%Y %-H:%M:%S')                                                   AS observed_local,
  regexp_extract(pm, '<idelem>([^<]*)</idelem>', 1)::INTEGER                                   AS idelem,
  nullif(regexp_extract(pm, '<descripcion>([^<]*)</descripcion>', 1), '')                      AS descripcion,
  TRY_CAST(nullif(regexp_extract(pm, '<intensidad>([^<]*)</intensidad>', 1), '') AS INTEGER)   AS intensidad,
  TRY_CAST(nullif(regexp_extract(pm, '<ocupacion>([^<]*)</ocupacion>', 1), '') AS INTEGER)     AS ocupacion,
  TRY_CAST(nullif(regexp_extract(pm, '<carga>([^<]*)</carga>', 1), '') AS INTEGER)             AS carga,
  TRY_CAST(nullif(regexp_extract(pm, '<nivelServicio>([^<]*)</nivelServicio>', 1), '') AS INTEGER) AS nivel_servicio,
  TRY_CAST(nullif(regexp_extract(pm, '<velocidad>([^<]*)</velocidad>', 1), '') AS INTEGER)     AS velocidad,
  regexp_extract(pm, '<error>([^<]*)</error>', 1)                                              AS error,
  TRY_CAST(replace(nullif(regexp_extract(pm, '<st_x>([^<]*)</st_x>', 1), ''), ',', '.') AS DOUBLE) AS utm_x,
  TRY_CAST(replace(nullif(regexp_extract(pm, '<st_y>([^<]*)</st_y>', 1), ''), ',', '.') AS DOUBLE) AS utm_y
FROM pms;
```
  Caveats: without the `'s'` option `.*?` stops at newlines and you get 0 rows; `descripcion` keeps XML entities (`&amp;`);
  for lon/lat either join the locations file (4c) on `idelem = id` or `ST_Transform(ST_Point(utm_x, utm_y), 'EPSG:25830', 'EPSG:4326')`
  with the spatial extension. The file's own UTF-8 BOM did not disturb `read_text`.

### 4b. Traffic history since 2013 (15-min per point) [verified]
- Dataset `208627-0-transporte-ptomedida-historico` (CC BY 4.0, MONTHLY, 163 resources, ~14.5 GB of zips in total).
- Monthly zips, newest naming `.../resource/208627-<n>-transporte-ptomedida-historico/download/MM-YYYY.zip`, e.g. October 2026:
  `https://datos.madrid.es/dataset/208627-0-transporte-ptomedida-historico/resource/208627-162-transporte-ptomedida-historico/download/10-2026.zip`
  → 200, 96.2 MB in 4.8 s; contains one `10-2026.csv` of **815 MB** (~20 M rows). Published ~3rd of the next month (Oct on Nov 3).
  Older months have generic names (`208627-0-...-zip.zip` = Dec 2022 etc.); map rid → month via `package_show` descriptions.
- Format: `id;"fecha";"tipo_elem";"intensidad";"ocupacion";"carga";"vmed";"error";periodo_integracion`
  e.g. `1006;"2026-10-01 00:00:00";"C30";"1440";"4";"0";"56";"N";5`. tipo_elem URB / C30 (M-30); vmed only on M-30.
- For the demo, aggregate on ingest (e.g. hourly city-wide and per-zone intensity) rather than land 20 M rows a month.
  `zipfs` over HTTPS should work as in 1c but a 815 MB member is heavy for a scheduled job [not tested at this size].

### 4c. Measurement-point locations [verified]
- Dataset `202468-0-intensidad-trafico`, monthly snapshots (CSV, XLSX, zip/shape), e.g.
  `https://datos.madrid.es/dataset/202468-0-intensidad-trafico/resource/202468-309-intensidad-trafico/download/pmed_ubicacion_10-2026.csv`
  → 714 KB, ISO-8859-1, 5,089 points: `"tipo_elem";distrito;id;"cod_cent";"nombre";utm_x;utm_y;longitud;latitud`
  (`id` = pm.xml `idelem` and the history `id`; decimal lon/lat included).

### 4d. JSON/CSV variant of the real-time feed
- None found on datos.madrid.es; the catalog's real-time traffic resources are XML only. The pm.xml + regex query above is the
  way. [searched, not exhaustive: the CKAN `q=trafico` search timed out once]

## 5. Other useful sources

- **Calle 30 (M-30) real time** [verified]: `https://mc30.es/xml-data/DatosTrafico.xml` (1.2 KB: totalVehiculosCalle30 3,569,
  velocidadMediaSuperficie 78.26 at 2026-11-15 00:20; **tunnel values stale since 2026-10-28 23:59**) and
  `https://mc30.es/xml-data/estado_trafico.xml` (segment states with polylines). Dataset 212117 (CC BY). pm.xml already carries
  the M-30 speeds per point, so this is optional.
- **Public car parks occupancy, real time** (dataset `50027-0-aparcamientosocupacionyservicios`): a SOAP service
  `https://servayto.madrid.es/MTPAR_WSINFO/InfoParking?wsdl` [unverified]; monthly history `300346-0-aparcamientos-ocupa-historico`.
- **SER (regulated street parking)**: tickets per parking meter, quarterly (`300470-0-ser-uso-parquimetros`), zones, meters
  [listed, unverified]. Too slow a cadence for the daily decision; useful as context only.
- **ZBE / Madrid 360**: static camera and street layers (`300654-0-circulacion-camaras-trafico`, `300229-0-trafico-madrid-central`,
  `300530-0-zona-bajas-emisiones-eliptica`) [listed]. Good for a map, not a signal.
- **EMT buses**: real-time arrivals API `https://openapi.emtmadrid.es/v3/transport/busemtmad/stops/<stopId>/arrives/all/` and a
  GTFS-RT service-alerts protobuf `https://openapi.emtmadrid.es/v1/bus/servicealerts/proto` (dataset 900029, licence
  "emt-madrid"). Without login the API answers `{"code": "80", "description": "Error, token not found in cache"}`
  [verified]: needs a free MobilityLabs/EMT account (not registered). Not needed for the NO2 decision.

## Suggested ingestion plan (from what worked)

| table | source | how | cadence |
|---|---|---|---|
| `no2_hourly` (and other magnitudes) | 1a real-time CSV (+1b rolling 30 d for catch-up) | scheduled SQL, `force_download`, UNPIVOT, MERGE on (station, hour) | every 20–30 min |
| backfill 2010–2024 | 1c yearly zips | `zipfs` or one-off script | once |
| backfill 2025→last month | 1c "Desde 2025" CSV (URL via package_show) | scheduled SQL | monthly |
| `stations` (+ protocol zone) | 1d CSV + hand-made zone lookup | once | yearly |
| `protocol_episodes` | 1e CSV (latin1) | once / monthly | — |
| `weather_forecast` | Open-Meteo forecast (paid key for commercial) | scheduled SQL read_json | hourly / per model run |
| `weather_history` | Open-Meteo archive + historical-forecast | backfill | once |
| `city_meteo_hourly` | 3d real-time + history | same SQL as NO2 | 30 min |
| `ventilation_forecast` | 2a AEMET PDF | small poller (pdftotext) or the agent reads it | daily |
| `no2_forecast_cams` | Open-Meteo AQ (or ADS with key) | scheduled SQL read_json | daily |
| `traffic_5min` | pm.xml | scheduled SQL regex query (above) | 5 min |
| `traffic_history` | 4b monthly zips | poller, aggregated | monthly |
