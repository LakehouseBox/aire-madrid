-- now.compliance: each year, each station, each NO2/PM rule of ref.rules: how many hours or days broke it, how many
-- the rule allows, the annual mean, and whether the year passes. Years before a rule was in force are scored
-- anyway: "how would Madrid have fared". Derived sink, mode replace, daily.
WITH d AS (SELECT * FROM aire_madrid.now.daily_station),
y AS (
  SELECT year(day) AS year, station_code, pollutant,
         count(*) FILTER (WHERE daily_mean IS NOT NULL)                AS days_valid,
         sum(hours_valid)::BIGINT                                      AS hours_valid,
         sum(daily_mean * hours_valid) / nullif(sum(hours_valid) FILTER (WHERE daily_mean IS NOT NULL), 0) AS annual_mean_approx,
         sum(hours_over_200)::BIGINT                                   AS hours_over_200,
         list(daily_mean) FILTER (WHERE daily_mean IS NOT NULL)        AS means
  FROM d GROUP BY ALL
)
SELECT y.year, y.station_code, r.rule_set, r.rule_id, r.averaging, r.threshold_ugm3, r.allowed_per_year,
       y.days_valid,
       CASE r.averaging
         WHEN 'day'  THEN len(list_filter(y.means, lambda m: m > r.threshold_ugm3))
         WHEN 'hour' THEN CASE WHEN r.threshold_ugm3 = 200 THEN y.hours_over_200 END
       END::BIGINT                                                     AS exceedances,
       round(y.annual_mean_approx, 1)                                  AS annual_mean,
       CASE r.averaging
         WHEN 'year' THEN y.annual_mean_approx <= r.threshold_ugm3
         WHEN 'day'  THEN len(list_filter(y.means, lambda m: m > r.threshold_ugm3)) <= coalesce(r.allowed_per_year, 0)
         WHEN 'hour' THEN y.hours_over_200 <= coalesce(r.allowed_per_year, 0)
       END                                                             AS passes
FROM y JOIN aire_madrid.ref.rules r ON r.pollutant = y.pollutant
WHERE r.rule_set IN ('eu2008', 'eu2030', 'who2021')
  AND NOT (r.averaging = 'hour' AND r.threshold_ugm3 <> 200)
