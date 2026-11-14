# Madrid city NO2 episode protocol: what is in force, and how an agent would apply it

Research date: 2026-11-15. Read-only web research. Markers: **[verified: URL]** = read in a primary or official source; **[press: URL]** = press or secondary; **[unverified]** = inference or not confirmed.

Key primary sources used:

- **P** = the protocol text, *Protocolo de actuación para episodios de contaminación por dióxido de nitrógeno en la ciudad de Madrid*, PDF `ProtocoloNO2AprobFinal_201809.pdf` (20 pages; PDF metadata: created 2018-10-01). The city's official air-quality portal links this file as the protocol. The madrid.es copy is behind Akamai and refuses scripted clients (403), so I read a Wayback copy captured 2024-04-17: https://web.archive.org/web/20240417215614id_/https://www.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Ficheros/ProtocoloNO2AprobFinal_201809.pdf (original URL: https://www.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Ficheros/ProtocoloNO2AprobFinal_201809.pdf).
- **D21** = the latest activation decree, signed by the Delegate for Environment and Mobility (Borja Carabante) on 16/12/2021 at 18:42: https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Portal/02_Actuaciones/ProtocoloNO2/Decretos/2021/20211216Decreto20210153099.pdf
- **PORTAL** = the city's protocol page: https://www.madrid.es/portales/munimadrid/es/Inicio/Medidas-especiales-de-movilidad/Protocolo-de-contaminacion/Protocolo-de-actuacion-para-episodios-de-contaminacion-por-dioxido-de-nitrogeno/?vgnextfmt=default&vgnextoid=fd8718cea863c410VgnVCM1000000b205a0aRCRD&vgnextchannel=00b3cf7588c97610VgnVCM2000001f4a900aRCRD
- **MEM25** = *Calidad del aire 2025*, the city's annual air-quality report: https://airedemadrid.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Publicaciones/Memorias_anuales/Ficheros/MEMORIA_2025%20v2.pdf
- **EST** = the open-data station list: https://datos.madrid.es/egob/catalogo/212629-1-estaciones-control-aire.csv

---

## 1. Current version, approval and revisions

| Fact | Status |
|---|---|
| The protocol in force was **approved definitively by the Junta de Gobierno de la Ciudad de Madrid on 10 December 2018** (reference ANM 2018\44). It took effect the same day. | [verified: PORTAL]; [verified: https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Alta-contaminacion-protocolos-y-episodios/Dioxido-de-nitrogeno-NO2-/?vgnextfmt=default&vgnextchannel=ac8e471c5c503710VgnVCM1000008a4a900aRCRD] |
| History: initial approval in **June 2018**, then approval by the Junta de Gobierno on **27 September 2018**, then re-approval on **10 December 2018** with **BOAM publication on 12 December 2018**. The September agreement was annulled so the text could first go to the Comunidad de Madrid's Sección de Calidad del Aire, as Decreto 140/2017 requires. | 27 Sept: [verified: https://transparencia.madrid.es/portales/transparencia/es/Portada/Novedades-en-el-portal/Protocolo-de-actuacion-para-episodios-de-contaminacion-por-dioxido-de-nitrogeno/?vgnextoid=d0086a4e9ac0d510VgnVCM1000001d4a900aRCRD&vgnextchannel=1f3fcfff5e520610VgnVCM2000001f4a900aRCRD]. Annulment and BOAM 12/12/2018: [press: https://cppm.es/boam-12-12-2018-aprobacion-definitiva-protocolo-episodios-contaminacion-por-dioxido-de-nitrogeno-en-madrid/]. June initial approval: [press: https://cobcm.net/blog/aprobado-inicialmente-el-protocolo-de-contaminacion-por-dioxido-de-nitrogeno/] |
| Official PDFs on the sede electrónica: `ProtocoloContaminacióno01oct2018.pdf` and `ProtocolocontaminaDioxido12dic2018.pdf` under https://sede.madrid.es/UnidadWeb/UGNormativas/Normativa/2018/ficheros/. Both return 403 to scripted clients and have no Wayback copy, so **I could not compare the October and December texts**. The PDF I read (P) is the one the city links as "Protocolo PDF (BOAM 12/12/2018)". | [verified: URLs found; content unread] |
| **No revision after 2018 found.** The December 2021 activation decree still applies "*el Protocolo… aprobado por Acuerdo de la Junta de Gobierno de 10 de diciembre de 2018*". MEM25 (2025) and the 2026 portal pages still cite the 10/12/2018 protocol. The text promises annual evaluation (§9), but no amending agreement has been published. | [verified: D21]; [verified: PORTAL]; [unverified that no amendment exists: searches for 2021/2023/2024 amendments found none] |
| Its predecessor, approved 21 January 2016 and in force from 1 February 2016, is repealed (P §10). The 2018 changes: odd/even number-plate bans replaced by bans by DGT environmental label; a 5th scenario added (Escenario 4 = 4 days at aviso; Alerta now its own scenario); the "3 stations anywhere in the network" trigger added; Escenario 3 can also be reached by 3 days at preaviso. | [verified: P]; [press: cppm.es above] |
| What did change around the protocol after 2018 (not amendments to it): **Ordenanza de Movilidad Sostenible** of 5 Oct 2018 (art. 35: legal basis for episode measures); **Ordenanza 4/2021 de Calidad del Aire y Sostenibilidad** (OCAS) of 30 Mar 2021 (arts. 39–40: short-term action plans, declaration of an episode); **SER dynamic tariff** from 26 Jan 2022 (see §4). | [verified: D21]; [verified: https://www.madrid.es/portales/munimadrid/es/Inicio/Actualidad/Noticias/La-nueva-tarifa-dinamica-del-SER-entra-en-funcionamiento-este-miercoles/?vgnextoid=7cb226793119e710VgnVCM2000001f4a900aRCRD&vgnextchannel=a12149fa40ec9410VgnVCM100000171f5a0aRCRD] |
| Regional framework: **Decreto 140/2017** (Comunidad de Madrid, *Protocolo Marco*), amended by **Decreto 38/2023 of 19 April 2023** (BOCM no. 94, 21/04/2023). The amendment extends the duty to adopt a local protocol to municipalities over 50,000 inhabitants. It also says that when Madrid city activates a scenario, neighbouring municipalities over 50,000 may activate theirs. **It does not change Madrid city's thresholds.** The framework says municipal thresholds may be stricter but never laxer (quoted in P). | [verified: https://www.bocm.es/boletin/CM_Orden_BOCM/2023/04/21/BOCM-20230421-1.PDF]; [verified: P] |
| The city's scenario web pages show newer summaries (image files named `Escenario1_2025.jpg` and similar) that **differ from P** in two ways: (a) Escenario 1 lists a "*Recargo del 100% sobre tarifas de estacionamiento en zona SER*"; (b) Escenario 2 says "*prohibición de circulación en todo el término municipal a los vehículos más contaminantes*", where P says inside and on the M-30. (a) comes from the SER tariff ordinance, not the protocol. (b) most likely reflects the Madrid 360 low-emission zone (vehicles without a label are now restricted citywide anyway). **Neither change corresponds to a published amendment I could find.** | [verified: https://www.madrid.es/portales/munimadrid/es/Inicio/Medio-ambiente/Escenario-1-/?vgnextfmt=default&vgnextoid=f1efd044d09cb810VgnVCM1000001d4a900aRCRD&vgnextchannel=3edd31d3b28fe410VgnVCM1000000b205a0aRCRD and the Escenario-2 page]; interpretation [unverified] |

---

## 2. Zoning: five zones, 24 stations

Zone boundaries (P, Anexo I) [verified: P]:

- **Zona 1**: inside the M-30.
- **Zona 2 (sureste)**: bounded by Avda. de Andalucía, Calle 30, the M-23 continuing along the R-3, and the municipal boundary.
- **Zona 3 (noreste)**: bounded by the M-23/R-3, Calle 30 up to the M-40 on the west, then north along the M-40 to the municipal boundary. Includes part of Barajas airport.
- **Zona 4 (noroeste)**: bounded by the municipal boundary to the north, the M-40 north, Calle 30 to the A-5, and the municipal boundary.
- **Zona 5 (suroeste)**: bounded by the southern edge of Casa de Campo, Calle 30, Avda. de Andalucía and the municipal boundary.

Stations per zone: the zone assignment and type are from P §2 [verified: P]; the codes are from EST [verified: EST].

| Zone | Station (protocol name) | Code (EST) | Type in P | Type in EST |
|---|---|---|---|---|
| 1 (interior M-30) | Escuelas Aguirre | 28079008 | traffic | Urbana tráfico |
| 1 | Castellana | 28079048 | traffic | Urbana tráfico |
| 1 | Plaza de Castilla | 28079050 | traffic | Urbana tráfico |
| 1 | Ramón y Cajal | 28079011 | traffic | Urbana tráfico |
| 1 | Cuatro Caminos | 28079038 | traffic | Urbana tráfico |
| 1 | Plaza de España | 28079004 | traffic | Urbana tráfico |
| 1 | Barrio del Pilar | 28079039 | traffic | Urbana tráfico |
| 1 | Plaza del Carmen | 28079035 | background | Urbana fondo |
| 1 | Méndez Álvaro | 28079047 | background | Urbana fondo |
| 1 | Retiro | 28079049 | background | Urbana fondo |
| 2 (sureste) | Moratalaz | 28079036 | traffic | Urbana tráfico |
| 2 | Vallecas | 28079040 | background | Urbana fondo |
| 2 | Ensanche de Vallecas | 28079054 | background | Urbana fondo |
| 3 (noreste) | Arturo Soria | 28079016 | background | Urbana fondo |
| 3 | Sanchinarro | 28079057 | background | Urbana fondo |
| 3 | Urbanización Embajada | 28079055 | background | Urbana fondo |
| 3 | Barajas Pueblo | 28079027 | background | Urbana fondo |
| 3 | Tres Olivos | 28079060 | background | Urbana fondo |
| 3 | Juan Carlos I | 28079059 | suburban | Suburbana |
| 4 (noroeste) | El Pardo | 28079058 | suburban | Suburbana |
| 4 | Casa de Campo | 28079024 | suburban | Suburbana |
| 5 (suroeste) | Fernández Ladreda (= **Plaza Elíptica**) | 28079056 | traffic | Urbana tráfico |
| 5 | Farolillo | 28079018 | background | Urbana fondo |
| 5 | Villaverde | 28079017 | background | Urbana fondo |

Notes for an agent:

- Zone sizes: 10 / 3 / 6 / 2 / 3 stations, 24 in total. Barrio del Pilar is in Zona 1 although it lies north of the M-30. That is how the protocol assigns it; use the table, not geometry. [verified: P]
- "Fernández Ladreda" in P is code 28079056, which EST names *Plaza Elíptica*. The plaza's official name is Plaza de Fernández Ladreda. [verified: EST lists 28079056 as Plaza Elíptica; the 2019 episode report names the station "Plaza Fernández Ladreda"]
- **Urb. Embajada (28079055) has been out of service since 1 September 2025** (Metro Line 5 works). Zona 3 currently reports 5 stations. [verified: MEM25]
- The hourly open data uses these same 8-digit codes (28079 + station number).

---

## 3. Trigger rules (levels)

P §3 [verified: P; restated identically in D21 and PORTAL]. All values are **hourly NO2 concentrations in µg/m³**; "simultáneamente" means the stations exceed the value in the same hours.

| Level | Threshold | Condition A (zonal) | Condition B (network-wide) |
|---|---|---|---|
| **Preaviso** | > 180 | any **2 stations of the same zone** exceed 180 at the same time for **2 consecutive hours** | any **3 stations of the whole network** exceed 180 at the same time for **3 consecutive hours** |
| **Aviso** | > 200 | any 2 stations of the same zone, at the same time, 2 consecutive hours | any 3 stations of the network, at the same time, 3 consecutive hours |
| **Alerta** | > 400 | any **3 stations of the same zone** (**2 in Zona 4**, which has only 2 stations) at the same time for **3 consecutive hours** | (none) |

The protocol says "superan" (exceed), so a value of exactly 180 does not count. [verified: P wording; strict inequality is my reading, unverified]

Footnote 2 of P: levels may be "*registrados o previstos*" according to the city's air-quality prediction model, so a level can count as reached on a **forecast** basis. [verified: P]

**Role of the weather forecast** (P §1 and §4): an *episode* exists only when there is a "*situación meteorológica desfavorable*" **and** the measured or forecast level exceeds (or there is a high probability of exceeding) a level. "Unfavourable" means atmospheric stability that prevents ventilation: clear skies, no wind, night-time radiative inversions, an anticyclone and subsidence inversion. The source for predicting it is **AEMET's official forecasts**. Verbatim from P §4: "*Una vez se haya superado o se prevea superar alguno de los niveles citados, y si la previsión meteorológica es desfavorable, se considerará iniciado un episodio de contaminación.*" [verified: P]

**Deactivation** (P §6): "*El episodio no se dará por concluido mientras persista la situación meteorológica desfavorable y, aún sin superarse los niveles de preaviso o aviso, las concentraciones de dióxido de nitrógeno continúen o se prevea que sigan siendo elevadas*". The Grupo Operativo keeps whatever measures it judges appropriate. D21 adds: "*Todas las medidas ordenadas se desactivarán tan pronto como dejen de darse los escenarios definidos… previo informe de la Dirección General de Sostenibilidad y Control Ambiental.*" **There is no numeric off-threshold in the 2018 text.** [verified: P, D21] (The 2016 protocol had one: keep Escenario 1 while levels stayed above 160 µg/m³ with an unfavourable forecast. **It is not in the 2018 text.** [press: https://www.madrid.es/portales/munimadrid/es/Inicio/Actualidad/Noticias/Aprobado-el-nuevo-Protocolo-para-Episodios-de-Alta-Contaminacion-por-NO2?vgnextchannel=a12149fa40ec9410VgnVCM100000171f5a0aRCRD&vgnextfmt=default&vgnextoid=9cb4008bcc362510VgnVCM1000000b205a0aRCRD, a 2016 note])

---

## 4. Scenarios and measures

### Scenario entry rules (P §4) [verified: P]

"Day" means a calendar day on which the level was reached (in practice judged on the day's hourly series; most exceedances happen in the evening).

| Scenario | Entry condition |
|---|---|
| **Escenario 1** | 1 day at preaviso |
| **Escenario 2** | 2 consecutive days at preaviso, **or** 1 day at aviso |
| **Escenario 3** | 3 consecutive days at preaviso, **or** 2 consecutive days at aviso |
| **Escenario 4** | 4 consecutive days at aviso |
| **Escenario Alerta** | 1 day at alerta |

**Escalation is gradual in practice.** Activation "always starts with Escenario 1" [press: cppm.es]. The January 2019 episode shows it: an *aviso* on Monday 14/01/2019, which by the table would be Escenario 2, produced **Escenario 1** on Tuesday 15/01. Escenario 2 came on 16 and 17/01, after a further preaviso day and an unfavourable forecast, then a step down to Escenario 1 on 18/01. [verified: episode report https://www.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/ProtocoloNO2/Episodios/Epi15_2019_15a18Ene.pdf] The reason is in P §6 and D21: parking and traffic restrictions must be announced before 12:00 the day before (below), so on the first day only the speed limit can apply. The FAQ says so directly: "the first day there are no parking or circulation restrictions; it is activated the night before." [verified: https://www.madrid.es/portales/munimadrid/es/ContenidosBasicos/Dudas-frecuentes-sobre-el-Protocolo-de-actuacion-para-episodios-de-contaminacion-por-dioxido-de-nitrogeno/?vgnextfmt=default&vgnextoid=1f0746ed8e456610VgnVCM2000001f4a900aRCRD&vgnextchannel=a1cc8f348af1c310VgnVCM2000000c205a0aRCRD]. D21 also writes the escalation as a calendar: Escenario 1 on day 1 and day 2, then Escenarios 2, 3 and 4 starting "successively" on the following days if they occur.

### Measures per scenario (P §4–5, confirmed verbatim in D21) [verified: P, D21]

Labels: 0 = "CERO EMISIONES", ECO, C, B; "sin etiqueta" (A) = no DGT label. "Ban X" means vehicles **without** a label in the allowed set may not circulate or park.

| Measure | Esc. 1 | Esc. 2 | Esc. 3 | Esc. 4 | Alerta |
|---|---|---|---|---|---|
| Information and recommendations (health advice Anexo II; heating thermostats ≤ 21 °C; company mobility plans) | yes | yes | yes | yes (health advice becomes "exceptional": restrict outdoor sport and after-school outdoor activities) | yes (exceptional) |
| Promotion of public transport | yes | yes | yes | yes | yes |
| Reinforcement of public transport (request to the Consorcio Regional de Transportes) | no | yes | yes | yes | yes |
| **70 km/h on the M-30 and accesses** (the DGT asked to do the same on interurban access roads inside the M-40) | yes | yes | yes | yes | yes |
| **Circulation ban inside and on the M-30** | no | allowed: 0/ECO/C/B (bans A) | (covered by citywide A ban) | allowed: **0/ECO/C** (bans **B** and A) | (covered by citywide ban) |
| **Circulation ban in the whole municipality** | no | no | allowed: 0/ECO/C/B (bans A) | allowed: 0/ECO/C/B (bans A) | allowed: **0/ECO only** (bans C, B, A) |
| **SER parking ban** (in SER spaces and hours) | no | allowed: 0/ECO (+ residents in own barrio, other Anexo IV exceptions) | same | same | allowed: **0 only** (ECO lose the exemption) + residents etc. |
| Free-roaming taxis (and VTC not in service) | no | no | *recommended* not to circulate (except Eurotaxi, 0, ECO) | *recommended* | **banned** (except Eurotaxi, 0, ECO); booked-but-empty taxis count as occupied |
| Municipal fleet carrying staff | | 100% restricted unless 0/ECO (from Esc. 2 on; D21) | same | same | same |

Hours and details:

- **Circulation bans apply 06:30–22:00** [verified: P §5.2, D21].
- **The speed limit applies from 06:00** of the first day after the exceedance and lasts until the episode ends [verified: FAQ]. D21 notes it takes legal effect once the variable-message signs show it.
- **SER parking restrictions** follow SER hours: Mon–Fri 09:00–21:00, Sat 09:00–15:00 (August and 24/31 Dec 09:00–15:00; no service on Sundays and holidays) [verified: FAQ]. In practice, a holiday cancels the parking measure: in the 5–7 Dec 2018 episode "the parking measure was not effective because the day of application was a holiday" [verified: 2018 episodes page https://www.madrid.es/portales/munimadrid/es/ContenidosBasicos/2018-Episodios-de-contaminacion-Protocolo-dioxido-de-nitrogeno-/?vgnextfmt=default&vgnextoid=754d0d81f9652710VgnVCM1000001d4a900aRCRD&vgnextchannel=a1cc8f348af1c310VgnVCM2000000c205a0aRCRD].
- **Exceptions** to circulation bans: public transport; workers starting or ending between 00:00 and 06:30 (employer certificate); PMR card holders carrying the holder; emergency services; street cleaning; **high-occupancy vehicles with 3 or more people**; **motorbikes, mopeds, tricycles, bicycles and personal mobility vehicles**; residents and SER-authorised commercial vehicles; taxis in service; and others [verified: D21 list a–o, which follows OMS art. 35.5]. Note that P's Anexo IV did *not* exempt motorbikes or mopeds ("incluidos ciclomotores"), but D21's list (m) does. **The two texts disagree; an agent should follow the latest decree** [verified: P vs D21].
- **Exceptional measures** (P §7, Anexo III) can be proposed by the Grupo Operativo if aviso or alerta persist after Esc. 4 or Alerta measures: further label restrictions, heating limits, limits on industry and construction, solvents and similar. [verified: P]
- **Suspension**: the Grupo Operativo may suspend or postpone measures that would backfire, such as congestion, holiday traffic operations or public-order reasons. [verified: P §6]

### Interaction with the SER dynamic tariff and Madrid 360 / ZBE

- **SER dynamic tariff** (since 26 Jan 2022; legal basis OMS art. 52.2.e and the SER tax ordinance). It is **separate from the protocol** and triggered by the **previous day's 00:00–23:00 mean NO2 over the 12 urban-background stations**: Tres Olivos, Sanchinarro, Barajas Pueblo, Urb. Embajada, Arturo Soria, Plaza del Carmen, Retiro, Méndez Álvaro, Vallecas, Villaverde, Farolillo, Ensanche de Vallecas.
  - Above 60 µg/m³: +60% surcharge.
  - Above 70 µg/m³: +100%.
  - **When a protocol scenario that still allows parking is declared (i.e. Escenario 1): +100%.**
  - Zero-emission vehicles are exempt.

  [verified: city news 25/01/2022, URL in §1]. This is why the 2025 Escenario 1 page lists a 100% SER surcharge. The tariff has fired without the protocol: +60% in December 2023 and +100% on 16 Jan 2025. In the words of the press reports, it "*no supone una activación del protocolo*", and "*Este protocolo lleva sin activarse desde diciembre de 2021*" [press: https://www.servimedia.es/noticias/madrid-duplica-tarifas-zona-ser-niveles-concentracion-dioxido-nitrogeno/1411441586; press: https://www.cope.es/actualidad/espana/noticias/madrid-activa-recargo-tarifa-base-del-ser-por-aumento-niveles-no2-20231220_3059676].
- **Madrid 360 / ZBE**: the low-emission zones (ZBE Distrito Centro, ZBE Plaza Elíptica, and the citywide ZBE for vehicles without a label) restrict label-A vehicles **permanently**. That makes the protocol's A-only bans in Escenarios 2 and 3 largely redundant today. The bans that still bite are B inside the M-30 (Esc. 4), C and B citywide (Alerta), and the SER parking bans. The FAQ notes that in Esc. 1, unlabelled vehicles still cannot enter the ZBE de Especial Protección Distrito Centro or park in SER (ordinary rules) [verified: FAQ]. Exact current ZBE dates for label-A vehicles registered in Madrid (2025 warning letters, 2026 fines or a further moratorium) are contradictory in the press [press: https://www.carwow.es/noticias/6443/madrid-2026-restricciones-etiquetas-fin-moratoria; https://www.infobae.com/espana/agencias/2024/12/12/madrid-no-multara-hasta-2026-a-los-coches-sin-etiqueta-ambiental/] [unverified].

---

## 5. Decision process

- **Who declares**: once a scenario is reached, the **Delegate of the Área de Gobierno** responsible for air quality (Medio Ambiente y Movilidad) signs a **Decreto** that activates the protocol and schedules the progressive measures. The exceptions are when the prediction system "*indique la reversión de la situación*" or exceptional circumstances apply [verified: P §6]. Legal basis today: OMS art. 35.7 and OCAS art. 40.4 [verified: D21]. The Dec 2021 decree was signed on 16/12/2021 at 18:42, the day after the evening exceedance [verified: D21].
- **The technical trigger**: a report by the **Dirección General de Sostenibilidad y Control Ambiental** (Servicio de Calidad del Aire), based on the *Sistema de Vigilancia, Predicción e Información de la Calidad del Aire* [verified: D21]. Information measures start "as soon as possible" once that directorate judges the conditions met [verified: P Anexo II].
- **Coordination**: the **Grupo Operativo**, chaired by the Coordinador/a General de Medio Ambiente (Sostenibilidad y Movilidad). It *may* be convened at Esc. 1 and *must* be at Esc. 2. Its ~25 members include AEMET, DGT, Guardia Civil, EMT, Calle 30, Consorcio de Transportes, Cercanías, Policía Municipal, Salud Pública and the Comunidad de Madrid. It can call in prediction-model experts. At alerta, or when alerta is forecast, the **Comisión de Calidad del Aire de la Ciudad de Madrid** is convened urgently [verified: P §8].
- **Timing**:
  - The Esc. 1 speed limit applies **at 06:00 the morning after** the exceedance and is activated the night before.
  - Parking and circulation measures (Esc. 2 and above) must be **announced before 12:00 of the day before** they apply.
  - Information and speed measures apply "the day after" a scenario is reached, or when exceedance is forecast.

  [verified: P §6, D21 "*antes de las 12 a.m. del día anterior*" (sic, meaning noon), FAQ].
- **Channels**: madrid.es, the *Aire de Madrid* app, free SMS, @airedemadrid / @EmergenciasMad / @policiademadrid / @AMovilidadMad / @EMTmadrid, M-30, EMT, Metro and Cercanías panels, and the media. Decrees are published in BOAM and BOCM [verified: FAQ; D21].
- **Forecasting**:
  - **Weather**: AEMET's official forecasts define "unfavourable" (P footnote 1). AEMET also sits on the Grupo Operativo.
  - **NO2**: the city runs its own statistical / machine-learning forecast, **SOCAIRE**, developed by **UNED's AI department and the company Inverence**. It has four independent subsystems (NO2, O3, PM10, PM2.5), hourly forecasts up to **48 h** (72 h in development), and inputs from AEMET, **ECMWF**, **WRF** (NCAR), **Copernicus CAMS**, the monitoring network and the school calendar. For NO2 it predicts per station and **per protocol zone**, "*con el objetivo de prever la probabilidad global de activación del protocolo*" [verified: https://airedemadrid.madrid.es/portales/calidadaire/es/Actuaciones-municipales/Sistema-integral-de-calidad-del-aire/Prediccion/Modelos-de-prediccion/?vgnextfmt=default&vgnextoid=fecefc8047df4710VgnVCM2000001f4a900aRCRD&vgnextchannel=4a7e471c5c503710VgnVCM1000008a4a900aRCRD].
  - An older city page says SOCAIRE replaced an earlier neural-network system (SERENA) and mentions CALIOPE among the inputs [press/secondary: search snippet of http://www.mambiente.madrid.es/opencms/calaire/SistemaIntegral/SistPrediccion/, not read] [unverified]. CAMS, ECMWF and WRF are verified as inputs; **CALIOPE is not, on the current page.**
- **How the forecast was used in practice**: the episode reports print a "Previsión meteorológica: Favorable/Desfavorable" row per day next to the levels per zone. In Jan 2019, Escenario 2 ran on days marked "Desfavorable" and stepped down when the forecast turned "Favorable" [verified: Epi15 report]. The Dec 2021 report marks the exceedance day 15/12 "Desfavorable" and 16–17/12 "Favorable", yet Esc. 1 was kept on 16–17/12 by decree. So the forecast row is not a mechanical on/off [verified: https://www.madrid.es/UnidadesDescentralizadas/Sostenibilidad/CalidadAire/Portal/02_Actuaciones/ProtocoloNO2/Episodios/Ficheros/EPISODIO_16_18_DICIEMBRE_2021_PROTOCOLO_NO2.pdf].

### Worked example (Dec 2021, from the official report)

On 15/12/2021, hourly values at the Zona 1 stations:

| Hour | Ramón y Cajal | Cuatro Caminos | Barrio del Pilar |
|---|---|---|---|
| 19:00 | 218 | 202 | – |
| 20:00 | 245 | 191 | – |
| 21:00 | – | 183 | 186 |

That is 2 Zona 1 stations above 180 for 2 consecutive hours (19:00, 20:00): **preaviso in Zona 1**. Network-wide, Ramón y Cajal, Cuatro Caminos, Ensanche de Vallecas, Villaverde and others were above 180 for 3 hours: **preaviso "toda la ciudad"**.

Note that Ramón y Cajal and Cuatro Caminos were both above **200** at 19:00, but only one station was above 200 at 20:00, so there was **no aviso**. Result: Escenario 1 (70 km/h) on 16 and 17/12. [verified: report above]

---

## 6. Activations 2017–2026

From the city's yearly episode pages (index: https://www.madrid.es/portales/munimadrid/es/ContenidosBasicos/Informes-sobre-episodios-de-contaminacion-por-dioxido-de-nitrogeno/?vgnextfmt=default&vgnextoid=0ab214b9c4dcb810VgnVCM2000001f4a900aRCRD&vgnextchannel=a1cc8f348af1c310VgnVCM2000000c205a0aRCRD) [verified for every row, from each year's page]:

| Year | Episodes | Dates and highest measures | Protocol |
|---|---|---|---|
| 2017 | 7 (incl. 26 Dec 2016 – 2 Jan 2017) | 26/12/16–2/1/17: speed, SER ban, odd/even plate ban inside M-30 on 29 Dec (Esc. 3). 9–11 Mar; 29 Sep–1 Oct; 10–15 Oct; 23–29 Oct; 15–25 Nov; 5–9 Dec: speed + SER parking ban (Esc. 2) | 2016 |
| 2018 | 4 | 23–25 Jan (speed); 5–7 Dec (speed + SER, but the SER part fell on a holiday); **11–12 Dec** and **25–28 Dec** (speed + SER + A-label ban inside and on the M-30 = Esc. 2) | 2016 until 9 Dec, then 2018 |
| 2019 | 3 | 1–6 Jan (speed, Esc. 1); **15–18 Jan (Esc. 2)**; 26 Feb–1 Mar (Esc. 1) | 2018 |
| 2020 | 1 | 8–10 Jan (Esc. 1, speed) | 2018 |
| 2021 | 2 | 16–19 Jan (Esc. 1); **16–18 Dec (Esc. 1) = the last activation** | 2018 |
| 2022 | 0 | "*no se ha producido ningún episodio con elevados niveles de concentración de dióxido de nitrógeno*" | |
| 2023 | 0 | same statement | |
| 2024 | 0 | same statement | |
| 2025 | 0 | same; MEM25: "*En 2025 no se ha activado el protocolo… en ninguna ocasión*" | |
| 2026 | 0 (to date) | same statement on the 2026 page | |

Patterns:

- **Under the 2018 protocol: 8 episodes in total** (2 in Dec 2018, 3 in 2019, 1 in 2020, 2 in 2021). **Escenario 2 was the highest ever reached** (Dec 2018 ×2, Jan 2019). **Escenarios 3, 4 and Alerta have never been activated** under it, and **alerta (400) has never been reached** in Madrid (P introduction; MEM25 2025).
- Episode numbering in the report filenames (Epi9…Epi17) shows 17 episodes between Nov 2015 and Jan 2020 [verified: filenames].
- **NO2 has fallen**: in 2023, 2024 and 2025, **no station exceeded the 200 µg/m³ hourly limit even once**, and no station exceeded the 40 µg/m³ annual limit. The 2025 annual means ranged from 9 (El Pardo) to 32 (Plaza Elíptica) [verified: MEM25 table]. Activations have stopped since December 2021, and the dynamic SER surcharge, a much lower bar of 60–70 µg/m³ daily mean, is now the measure that actually fires [press: servimedia 2025].
- **EU Directive 2024/2881** (2030 limits): NO2 **hourly 200 µg/m³ with at most 3 exceedances a year** (was 18), **new daily limit 50 µg/m³ with at most 18 days a year**, and **annual limit 20 µg/m³** (was 40) [verified: EEA, https://www.eea.europa.eu/en/analysis/publications/air-quality-status-report-2025/benchmark-analysis-against-the-standards-in-the-revised-directive-eu-2024-2881]. The NO2 alert threshold (400 µg/m³ over 3 h) is, to my knowledge, unchanged [unverified: not read in the directive's annex]. Relevance: the protocol's levels (180/200/400) are hourly peaks and do not depend on the annual limit. But with 2025 annual means up to 32 µg/m³, Madrid would fail the 2030 annual limit of 20 at most stations, and the new daily limit of 50 sits close to the dynamic tariff's 60/70 triggers. **No Madrid announcement found about revising the protocol for 2030** [unverified].

---

## Algorithm sketch for an agent (derived from P; interpretive choices flagged)

1. For each hour *h* and each level L ∈ {180, 200, 400}:
   - **Zonal test**: count the stations in each zone with value > L in **both** *h−1* and *h* (L = 400: three hours, *h−2*..*h*). Preaviso or aviso is met if any zone has ≥ 2. Alerta is met if any zone has ≥ 3, or ≥ 2 in Zona 4.
   - **Network test** (180 and 200 only): count the stations with value > L in each of *h−2*, *h−1*, *h*. The level is met if ≥ 3.
   - Interpretive choice: "the same stations" over the consecutive hours. P says "dos estaciones cualesquiera… superan, simultáneamente… durante dos horas consecutivas", read here as the same stations [unverified reading; the Dec 2021 report agrees with it].
2. **Daily level** = the highest level met during that calendar day.
3. **Episode on** if day-level ≥ preaviso **and** AEMET (or a proxy: stable anticyclone, low wind, inversion) is unfavourable for the next day. A forecast exceedance from SOCAIRE-like predictions can stand in for a measured one.
4. **Scenario for tomorrow**: use the consecutive-day table, capped at one step above yesterday's scenario, and Escenario 1 on the first day.
5. **Announce**: Esc. 1 by the evening (applies 06:00). Esc. 2 and above before 12:00 of the previous day. Restrictions run 06:30–22:00; SER rules follow SER hours (none on Sundays and holidays).
6. **Off**: when no scenario condition holds and the weather turns favourable. Step down (e.g. 2 → 1) rather than switching off while the forecast stays unfavourable.

## Biggest uncertainties

1. **Dec 2018 text vs the PDF read.** The sede PDFs (01oct2018, 12dic2018) were unreadable (403). The PDF I read is the city-linked text created 1 Oct 2018. Whether the 10 Dec re-approval changed any wording is unconfirmed; the 2021 decree's measures match it exactly.
2. **Web-summary drift.** The 2025 scenario pages differ from the legal text (Esc. 2 "whole municipality"; SER surcharge in Esc. 1). This is likely the ZBE and tariff overlay, not an amendment.
3. **Motorbike exemption**: P bans mopeds; the decrees exempt motorbikes and mopeds.
4. **No numeric deactivation rule** and no machine-readable definition of "unfavourable" weather: both are judgement calls by the Grupo Operativo and AEMET.
5. **ZBE status for label-A vehicles in 2026** is contradictory in the press.
6. **The 2024/2881 NO2 alert threshold** is not verified from the directive text.
