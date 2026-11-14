-- The city's hourly history files (CSV, `;`, H01..H24 values with V01..V24 validity flags) as obs.air_hourly rows.
-- Used by tools/backfill_air_history.py; :src is a file path, an https URL, or a zip:// member.
SELECT 28079000 + ESTACION::INTEGER                                                         AS station_code,
       MAGNITUD::INTEGER                                                                    AS magnitude,
       timezone('Europe/Madrid', make_date(ANO::INT, MES::INT, DIA::INT)::TIMESTAMP + to_hours(h::INT - 1)) AS hour_start_at,
       TRY_CAST(v AS DOUBLE)                                                                AS value,
       true                                                                                 AS is_validated,
       'madrid-history'                                                                     AS source
FROM (
  UNPIVOT (SELECT * FROM read_csv(getvariable('src'), delim = ';', header = true, all_varchar = true))
  ON (H01, V01) AS '01', (H02, V02) AS '02', (H03, V03) AS '03', (H04, V04) AS '04', (H05, V05) AS '05', (H06, V06) AS '06',
     (H07, V07) AS '07', (H08, V08) AS '08', (H09, V09) AS '09', (H10, V10) AS '10', (H11, V11) AS '11', (H12, V12) AS '12',
     (H13, V13) AS '13', (H14, V14) AS '14', (H15, V15) AS '15', (H16, V16) AS '16', (H17, V17) AS '17', (H18, V18) AS '18',
     (H19, V19) AS '19', (H20, V20) AS '20', (H21, V21) AS '21', (H22, V22) AS '22', (H23, V23) AS '23', (H24, V24) AS '24'
  INTO NAME h VALUE v, flag
)
WHERE flag = 'V' AND TRY_CAST(v AS DOUBLE) IS NOT NULL
