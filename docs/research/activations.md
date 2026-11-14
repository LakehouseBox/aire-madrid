# r133: ground truth for Madrid NO2 protocol activations (sources, tested 2026-11-14/15 UTC)

Raw downloads (CSVs, HTML, PDFs, pdftotext output) are in the `r133/` folder next to this file.

## TL;DR

- **Best historical source: the city's own CSV of activations for the current protocol.** It is
  `JUEGO_DATOS_activacion_protocolo_NO2.csv` on airedemadrid.madrid.es, which is datos.madrid.es dataset
  300403. It has one row per measure, with start and end date/time, episode number, scenario, measure, area
  and the environmental labels affected. It covers 8 episodes, from 11/12/2018 to 17/12/2021. **[verified]**
  - The city also publishes **one PDF report per episode** with a per-day table of the level reached by zone
    (preaviso/aviso) and the scenario applied each day. Reports exist for episodes 4 to 17 (2017–2020) and
    for both 2021 episodes. **[verified]**
  - **Year pages for 2016–2026.** The pages for 2022, 2023, 2024, 2025 and 2026 each say "no se ha producido
    ningún episodio". **[verified]**
- **There has been no NO2 episode since 17 Dec 2021.** For any live demo period in 2022–2026, the ground
  truth is "scenario 0 every day".
- **Best live source: the Informo incidents XML** (`es_contaminacion`/`escenario_contaminacion`, refreshed
  every 5 min). It is empty today. Its field semantics are documented, but I could not get an archived copy
  taken during an episode, because the Wayback Machine returned 429 to every snapshot fetch.
  - In practice, a demo can check "did anything change" by polling that XML plus the two CSVs' `Last-Modified`.
    The O3 CSV was updated on the same evening as its last episode (13/08/2026 21:40 GMT).

---

## 1. Informo incidents XML: live, no history

- URL: `https://informo.madrid.es/informo/tmadrid/incid_aytomadrid.xml` (datos.madrid.es dataset
  202062-0-trafico-incidencias-viapublica: "se incluyen los escenarios del protocolo de actuación por
  episodios de contaminación… actualiza… 5 minutos").
- Request: `curl -A "Mozilla/5.0" https://informo.madrid.es/informo/tmadrid/incid_aytomadrid.xml` → `200 107784 bytes`;
  113 `<Incidencia>`, all `<es_contaminacion>N</es_contaminacion>`, scenario fields self-closed. **[verified]**
  ```
  <es_contaminacion>N</es_contaminacion><escenario_contaminacion /><fecha_escenario_contaminacion />
  <descripcion_escenario /><medidas_escenario /><excepciones_escenario />
  ```
- Field semantics, from the official structure PDF (`…/202062-1-trafico-incidencias-viapublica/download/estructura_ds_incidencias_via_publica.pdf`,
  200, 364 kB). **[verified]**
  - `es_contaminacion`: S/N, "si la incidencia corresponde con un escenario de contaminación".
  - `escenario_contaminacion`: "Identificación del escenario activo… Si no hay escenario activo… en blanco".
  - `fecha_escenario_contaminacion`: activation date.
  - `descripcion_escenario`: short text of the reasons for activation.
  - `medidas_escenario`: the measures.
  - `excepciones_escenario`: the exceptions.
  - A pollution incident has `tipoincid` = **10** ("contaminación"), and its utm_x/utm_y/longitud/latitud are **NaN**.
    So it is one city-wide record, not a geolocated one.
- What a populated record looks like: **[unverified]**.
  - No example was found on the web.
  - Wayback CDX does list captures: `http://web.archive.org/cdx/search/cdx?url=informo.madrid.es/informo/tmadrid/incid_aytomadrid.xml`
    has 18 captures 2018-06 → 2024-01, and `informo.munimadrid.es/...` (the old host) has 33 captures 2015-05 → 2019-04.
  - Some of those captures fall **inside known episodes**:
    - `20171207115954` (07/12/2017, scenario 2) on informo.munimadrid.es
    - `20190226065524` (26/02/2019, scenario 1)
    - `20190114053554` (14/01/2019, aviso day; scenario 1 announced for 15/01)
  - Every `id_` fetch returned **HTTP 429** ("flagged as suspected abusive bot traffic"). WebFetch is refused
    for web.archive.org, and the Chrome extension was not connected.
  - **To do:** open those three URLs in a normal browser:
    `https://web.archive.org/web/20171207115954id_/http://informo.munimadrid.es:80/informo/tmadrid/incid_aytomadrid.xml`
- History: none. It is a current-state snapshot only, and the archive is sparse (about one capture a month).

## 3. Ayuntamiento: open data + air-quality portal (the historical ground truth)

### 3a. NO2 activations CSV (datos.madrid.es 300403). **[verified]**
- URL: `https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Portal/04_Bases/04%20Ficheros/JUEGO_DATOS_activacion_protocolo_NO2.csv`
- Request: `curl -A "Mozilla/5.0" <url>` → `200 4064 bytes`. Encoding is ISO-8859-1, `;` separated, CRLF line ends,
  45 lines. `Last-Modified: Sun, 29 Jun 2025 14:20:21 GMT`.
- Header: `FECHA INICIO;HORA INICIO;FECHA FIN;HORA FIN;EPISODIO;ESCENARIO;MEDIDA;ÁMBITO GEOGRÁFICO;CATEGORÍA AMBIENTAL A;…B;…C;…ECO;…CERO`
- Excerpt:
  ```
  12/12/2018;6:30;12/12/2018;22:00;1;2;PROHIBICIÓN CIRCULACIÓN;M30 E INTERIOR M30;1;;;;
  12/12/2018;9:00;12/12/2018;21:00;1;2;PROHIBICIÓN ESTACIONAMIENTO;ZONA SER;1;1;1;;
  16/12/2021;6:00;17/12/2021;23:59;8;1;REDUCCIÓN VELOCIDAD A 70 KM/H;M30 Y ACCESOS;1;1;1;1;1
  ```
- Scope:
  - Episodes 1–8 of the 10/12/2018 protocol only.
  - It omits the 5–7 Dec 2018 episode, which ran under the Oct-2018 version.
  - It omits everything from 2016 to Jan 2018.
  - It records **activations (scenarios), not the preaviso/aviso levels**. Those are in the PDF reports (3c).
- Dataset metadata (CKAN `package_search`): metadata_modified 2026-07-23. The structure PDF is
  `estructuradsepisodiosno2.pdf` (200).

### 3b. O3 activations CSV (datos.madrid.es 300402). **[verified]**, for context
- `…/JUEGO_DATOS_activacion_protocolo_O3.csv`: 200, 16,121 bytes, `Last-Modified: Thu, 13 Aug 2026 21:40:39 GMT`.
- 57 episodes, 03/07/2013 → 13/08/2026. Every row is "INFORMACIÓN A LA POBLACIÓN", so there are no traffic measures.
- The header is corrupted (the first column is named `16:08`).
- It shows the city updates these CSVs on the day of an episode, which makes the NO2 CSV's 2025 date plausible
  as "nothing new".

### 3c. Air-quality portal: episode reports, year pages, decrees. **[verified]**
- Index: `https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Alta-contaminacion-protocolos-y-episodios/Dioxido-de-nitrogeno-NO2-/Informes-sobre-episodios-de-contaminacion-por-dioxido-de-nitrogeno/?vgnextfmt=default&vgnextoid=0ab214b9c4dcb810VgnVCM2000001f4a900aRCRD&vgnextchannel=ac8e471c5c503710VgnVCM1000008a4a900aRCRD`
  (200, HTML). It links:
  - one page per year, 2016–2026 (`…/2021-Episodios-de-contaminacion-Protocolo-dioxido-de-nitrogeno-/?…`)
  - the CSV
  - a "Decretos de activación" page
- Year pages:
  - 2016–2021 list each episode with its measures and a PDF report.
  - **2022, 2023, 2024, 2025 and 2026** each say: "En la ciudad de Madrid en el año 20xx no se ha producido
    ningún episodio con elevados niveles de concentración de dióxido de nitrógeno."
- Episode PDFs: `https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/ProtocoloNO2/Episodios/Epi{4..17}_….pdf`
  plus the two 2021 PDFs (all 200). The `www.madrid.es` copies return 403 to curl; the same path on
  airedemadrid works.
  - Each report has a "SECUENCIA DE SUPERACIONES Y ESCENARIOS ALCANZADOS" table with these rows:
    meteorological forecast, level per zone (Preaviso/Aviso), TOTAL, and Actuaciones (scenario per day).
  - Each also has the hourly station values behind the trigger.
  - Text extracts with pdftotext.
- Decrees page (`…/Decretos-de-activacion…`): 19 decrees from 2016-10-30 to 2021-12-16, at
  `…/Portal/02_Actuaciones/ProtocoloNO2/Decretos/YYYY/YYYYMMDDDecretoNNN.pdf` (all 200).
  - They are scanned images with no text layer.
  - They are worded conditionally ("si… se alcanzasen… se adoptarán"), so they show **authorisation**, not the
    day-by-day outcome. Use the reports instead.
- Protocol in force (portal page): 10/12/2018. Its levels:
  - **Preaviso**: 2 stations in a zone >180 µg/m³ for 2 consecutive hours, or 3 stations anywhere >180 for 3 hours.
  - **Aviso**: the same rule at 200.
  - **Alerta**: 3 stations in a zone (2 in zone 4) >400 for 3 hours.
  - An episode needs a level exceeded **and** an unfavourable weather forecast.
  - There are 5 scenarios (1–4 + alerta).
- The portal has no live "current level" widget and no feed. Citizen channels are SMS alerts, the "Aire de
  Madrid" app and X @airedemadrid.

### 3d. datos.madrid.es state (item 5). **[verified, 2026-11-14 ~23:20 UTC]**
- The portal is now **CKAN 2.9.11** (`/api/3/action/status_show` returned 200 once, then timed out after 45 s
  on a retry).
- Behaviour looks like a cache in front of a struggling origin:
  - `package_search?q=contaminacion|protocolo|episodios` → 200 in 0.1–0.3 s.
  - `package_search?q=escenario` → timeout after 30 s.
  - `/dataset/300403-…` and `package_show?id=300403-…` → timeout after 45 s.
  - `/egob/catalogo.json` (old URL) → 404 after 34 s.
  - `/portal/site/egob` → 301 to `/` after 40 s; `/` → 200 in 1.7 s.
- The resource files themselves are hosted on airedemadrid.madrid.es and informo.madrid.es, and those are fast
  and reliable. **Link to those directly, not to the portal.**
- Other relevant datasets: 201200 (hourly air quality since 2001), 212531/300755 (real time), 212629 (stations).

## 4. Other sources
- **Comunidad de Madrid** regional framework protocol (Decreto 140/2017, modified by Decreto 38/2023; 7 zones;
  Información-Preaviso / Aviso / Alerta; zone 1 = Madrid city). No machine-readable activation history was found;
  municipal protocols remain the operative ones for Madrid city. **[unverified beyond search results]**
  (comunidad.madrid/node/48272; BOCM-20230421-1)
- **Press (diario.madrid.es "notas de prensa")** carries the daily announcements, for example "mañana jueves se
  reduce la velocidad máxima a 70 km/h en la M-30". It is useful for the evening-before announcement timing.
  Only used here for 2016.
- **X accounts** (@airedemadrid, @MADRID, @informo, @EMTmadrid): not tested. X needs login and has no free API.
  Not a viable machine source.
- **BOAM**: not searched in depth. The decrees on the portal are the activation acts.

---

## 5. Historical activations (NO2), day by day

Source keys:
- **R**: the city's per-episode PDF report (SECUENCIA table) **[verified]**
- **C**: the open-data CSV **[verified]**
- **Y**: the year page **[verified]**
- **P**: press **[unverified/partly conflicting]**

"Level" is the day on which the preaviso/aviso was **reached**. The scenario is applied from the **next day**
(protocol logic), from 06:00. Measures by scenario:
- Esc 1 = 70 km/h on M-30 and the accesses inside M-40.
- Esc 2 (2016–Oct 2018) = Esc 1 + SER parking ban inside M-30.
- Esc 2 (from Dec 2018) = Esc 1 + SER ban for vehicles not Cero/ECO (09–21h) + traffic ban on M-30 and inside
  it for vehicles without a DGT label (06:30–22h).
- Esc 3 (2016 protocol) = odd/even plate restriction inside M-30.

| Episode | Day | Level reached (zones) | Scenario in force | Source |
|---|---|---|---|---|
| 2016-a | 29/10–02/11/2016 | n/a | Esc 1 (70 km/h) and Esc 2 (SER ban) on some days; per-day not extracted | Y (no PDF); decree 750 of 30/10/2016 |
| 2016-b | 21–25/12/2016 | n/a | Esc 1 (70 km/h) | Y; decree 881 of 22/12/2016 |
| 2016-c | 28/12/2016 | n/a | Esc 2 (SER ban) | P (diariomotor; elindependiente) ; decree 888 of 27/12/2016 |
| 2016-c | 29/12/2016 | n/a | **Esc 3** (odd plates only, inside M-30, 06:30–21:00); the only Esc 3 ever | P (elindependiente, legaltoday/Reuters) |
| 2016-c | 30/12/2016 | n/a | back to Esc 2 (press conflicting) | P |
| Epi4 | 09/03/2017 | Aviso (Z1) | none | R |
| | 10/03/2017 | | Esc 1 | R |
| | 11/03/2017 | | Esc 2 | R |
| | 12/03/2017 | | deactivated | R |
| Epi5 | 28/09/2017 | Preaviso (Z1) | none | R |
| | 29/09–01/10/2017 | | Esc 1 | R |
| | 02/10/2017 | | deactivated | R |
| Epi6 | 10/10/2017 | Preaviso (Z1, Z5) | none | R |
| | 11/10/2017 | Aviso (Z1), Preaviso (Z5) | Esc 1 | R |
| | 12/10/2017 | Preaviso (Z1) | Esc 1 | R |
| | 13–14/10/2017 | | Esc 2 | R |
| | 15/10/2017 | | Esc 1 | R |
| | 16/10/2017 | | deactivated | R |
| Epi7 | 23/10/2017 | Aviso (Z1) | none | R |
| | 24/10/2017 | Preaviso (Z1) | Esc 1 | R |
| | 25/10/2017 | Aviso (Z1, Z3) | Esc 2 | R |
| | 26/10/2017 | Aviso (Z1), Preaviso (Z3) | Esc 2 | R |
| | 27/10/2017 | | Esc 2 | R |
| | 28/10/2017 | | Esc 1 | R |
| | 29/10/2017 | | deactivated | R |
| Epi8 | 15/11/2017 | Preaviso (Z1) | none | R |
| | 16–17/11/2017 | Preaviso (Z1) | Esc 1 | R |
| | 18–20/11/2017 | Preaviso (Z1; Z5 on 20th) | Esc 2 (no SER on Sunday 19th) | R |
| | 21/11/2017 | Aviso (Z1, Z5), Preaviso (Z3) | Esc 2 | R |
| | 22/11/2017 | Preaviso (Z3) | Esc 2 | R |
| | 23/11/2017 | | Esc 2 | R |
| | 24/11/2017 | | Esc 1 | R |
| | 25/11/2017 | | deactivated | R |
| Epi9 | 05/12/2017 | Aviso (Z1, Z3), Preaviso (Z5) | none | R |
| | 06/12/2017 | | Esc 1 | R |
| | 07/12/2017 | | Esc 2 | R |
| | 08/12/2017 | | Esc 1 | R |
| | 09/12/2017 | | deactivated | R |
| Epi10 | 23/01/2018 | Preaviso (Z1) | none | R |
| | 24/01/2018 | | Esc 1 | R |
| | 25/01/2018 | | deactivated | R |
| Epi11 | 04/12/2018 | Aviso (Z1) | none | R (protocol of Oct 2018; not in CSV) |
| | 05/12/2018 | | Esc 1 | R |
| | 06/12/2018 | | Esc 2 (public holiday: SER not applied) | R |
| | 07/12/2018 | | Esc 1 | R |
| Epi12 / CSV ep.1 | 10/12/2018 | Preaviso (Z1, Z3), Aviso (whole city) | none | R |
| | 11/12/2018 | | Esc 1 | R, C |
| | 12/12/2018 | | **Esc 2** with circulation ban (06:30–22:00) + SER ban (09–21) | R, C |
| Epi13 / CSV ep.2 | 24/12/2018 | Preaviso (Z1) | none | R |
| | 25/12/2018 | | Esc 1 | R, C |
| | 26/12/2018 | Aviso (Z1) | Esc 1 | R, C |
| | 27/12/2018 | | Esc 1 | R, C |
| | 28/12/2018 | | **Esc 2** with circulation ban + SER ban (the CSV lists the ban; the report also says a decree suspended the circulation ban for 28–31 Dec for holiday traffic: conflicting) | R, C |
| Epi14 / CSV ep.3 | 31/12/2018 | Preaviso (Z1) | none | R |
| | 01–06/01/2019 | Preaviso (whole city) on 04/01 | Esc 1 | R, C |
| Epi15 / CSV ep.4 | 14/01/2019 | Aviso (Z1), Preaviso (Z2, Z3, Z5, city) | none | R |
| | 15/01/2019 | Preaviso (Z5) | Esc 1 | R, C |
| | 16–17/01/2019 | | **Esc 2** with circulation ban + SER ban | R, C |
| | 18/01/2019 | | Esc 1 | R, C |
| Epi16 / CSV ep.5 | 25/02/2019 | Preaviso (Z1, city) | none | R |
| | 26/02–01/03/2019 | | Esc 1 | R, C |
| Epi17 / CSV ep.6 | 08/01/2020 | Preaviso (Z1, Z3, city) | none | R |
| | 09–10/01/2020 | | Esc 1 | R, C |
| 2021-a / CSV ep.7 | 16/01/2021 | Preaviso (Z1) | none | R |
| | 17–19/01/2021 | Preaviso (Z5) on 18/01 | Esc 1 | R, C |
| 2021-b / CSV ep.8 | 15/12/2021 | Preaviso (Z1, city) | none | R |
| | 16–17/12/2021 | | Esc 1 | R, C |
| none | 2022, 2023, 2024, 2025, 2026 (to date) | none | none ("no se ha producido ningún episodio") | Y |

Notes and caveats:
- Some report weekday labels are off by one (Epi12 "10/12/2018 Martes", Epi17 "8/1/2020 Lunes"). The dates
  are taken as given.
- Escenario 3 and 4 of the 2018 protocol have **never** been activated. The EU alert level (400) has never been
  reached in Madrid.
- Whether the protocol was revised after 2018 was not found. The portal still calls the 10/12/2018 protocol
  current.
- 2015 episodes (old 2015 protocol, e.g. the SER ban of 13/11/2015) are outside scope and not compiled.
