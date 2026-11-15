---
title: "Does an agent get better at its job? We replayed a Madrid winter to find out"
description: "An agent forecasts Madrid's nitrogen dioxide the day before, at the hour the city must announce traffic restrictions. Four forecasters, one winter, 182 days: what memory helped, and what it didn't."
date: 2026-11-16
author: Javier de la Torre
category: Agents
draft: true
resources: "The code|https://github.com/lakehousebox/aire-madrid; The page|<artifact link once public>"
---

Madrid has not activated its nitrogen dioxide (NO2) protocol since December 2021. In 2025 every one of its 23 stations
met the EU limits in force. From 2030 the limits get much stricter. The EU's new directive allows a station's
daily mean above 50 µg/m³ on at most 18 days a year. In 2025 some station in Madrid went over 50 on 54 days; in 2019
it was 201. Seventeen of the 23 stations would have passed the 2030 daily rule in 2025, and six the annual one. Under
the WHO's guidelines, none.

So the question a city will face again is the one the protocol was written for: will tomorrow be bad enough to restrict
traffic? The protocol makes the city announce restrictions before noon the day before. We built an agent that answers
at that hour, every day, and is scored the next day. Then we asked the question everyone building agents asks: does it
get better?

## The setup

Everything lives in one Apache Iceberg catalog on LakehouseBox:

- the city's hourly air quality since 2010 (20.8 million readings);
- its weather stations since 2019;
- traffic every five minutes;
- the protocol's live state and AEMET's forecast.

Scheduled SQL fetches each source and builds the tables the agent reads:

- each day under every rule set (protocol 2018, EU 2030, WHO 2021, the parking surcharge);
- each station's compliance each year;
- each forecast with its Brier score.

The agent is a LakehouseBox hosted agent: a prompt that runs next to the data at 12:00 Madrid time. It writes its
forecasts to a table. Its scores are a table too.

A live agent needs months before a learning curve means anything. So we replayed a past winter instead: 1 October 2024
to 31 March 2025, 182 days. Each day at "noon" four forecasters predicted the next day from what was known at that
hour. All of them used the same model the hosted agent uses.

- **Persistence**, no model: how often, in the last 28 days, a day like yesterday was followed by an event.
- **Fresh**: the model with the day's brief and no memory.
- **Notebook**: the model plus a notebook of up to 12 lessons. Every day it sees how its forecast for yesterday turned
  out and rewrites the notebook. This is what "agent memory" usually means.
- **Record**: the model plus a table computed from its own scored forecasts. It sees how often events happened when it
  gave each probability, and what it said and what happened on the past days most like tomorrow. No prose: memory as
  a query.

The brief was the same for all three model forecasters:

- the last seven days;
- this morning's hours by zone;
- tomorrow's weekday and holidays;
- tomorrow's weather.

There were three questions: will some station's daily mean exceed 50 µg/m³ (the 2030 limit)? Will five or more? Will
the 12 background stations average over 60, the rule that raises parking prices the next day? Each forecast is scored
with the Brier score, the squared error of the probability: 0 is perfect, and lower is better.

## What happened

| Brier score (lower is better) | Record | Notebook | Fresh | Persistence |
|---|---|---|---|---|
| Some station above 50 (35% of days) | **0.146** | 0.154 | 0.168 | 0.200 |
| Five or more above 50 (16% of days) | **0.095** | 0.120 | 0.114 | 0.150 |
| Parking surcharge (2 days all winter) | 0.042 | 0.035 | 0.085 | **0.013** |

What the confidence intervals show (95%, a bootstrap over weeks, since days are not independent):

- **The record forecaster** beat the fresh model on five or more stations and on the surcharge. On "some station
  above 50" its lead is just short of clear: −0.020, with an interval of −0.043 to +0.001. It beat the fixed rule on
  both EU 2030 questions, and it beat the notebook on five or more stations.
- **The notebook** beat the fresh model only on the surcharge.
- **On the surcharge, the fixed rule beat every model.** With 2 events in 182 days, saying "almost never" is the right
  answer.

Three things stand out.

**Memory's first job is calibration.** The model knows the meteorology: calm air, cold clear nights and no rain build
NO2 up. Without memory it applied that knowledge too eagerly. It said 49% on average for an event that happened on 35%
of days, and 20% for a surcharge that happened twice all winter. Both memories mostly removed that bias. The record
forecaster averaged 40%, and the notebook 39%. That is where most of the gain comes from.

**The notebook drifted.** October 2024 was clean. The notebook learned that, one anecdote at a time: *"After several
days with worst ~35-47 and no exceedance in the last 2 days, a forecast day with wind ~0.4 m/s and no rain […] yields
no exceedance; set any_over_50 ≤0.2."* By 18 November, eleven of its twelve lessons capped that probability at 0.2 or less. On
18 November it reasoned that "recent days have stayed below 50" and gave 15%. The fresh model said 90%, and a station
went over. Over the winter, two thirds of all the lessons it wrote (1,381 of 2,066) capped the probability at 0.2 or
less. Lessons written from single cases look precise, with thresholds and ranges. In fact they are a summary of the
recent past, and they are hard to unlearn.

**The record forecaster did not drift.** It never wrote anything down. Each day it got the facts again: "when you said
0.6-0.8, it happened 9 times in 14", and "on the six past days most like tomorrow, you said this, and this happened".
Its memory is a query over the table of its own forecasts, which is just a join for data the catalog already holds. It
was better than or level with the fresh model on every question, by up to 50% on the surcharge.

Neither memory produced a curve that keeps going down. The gain shows up within the first weeks, when there is enough
record to calibrate against, and then holds steady. Honestly put, the agent did not become a better meteorologist. It
became a better-calibrated forecaster of this city, and stayed one.

## What we changed in the live agent

The hosted forecaster now starts each run by reading its record:

- its calibration by probability band;
- the past days most like tomorrow, from a daily weather table joined to what happened. Until it has scored a month of
  its own, it uses the history since 2019 for this.

It still keeps a short memory of open decisions: the forecasts it must close the next day. It writes notes only for
facts the data cannot show, such as a station out of service, a new low-emission rule or roadworks. It never writes
rules drawn from a single day. The forecasts, outcomes, scores and memory are all tables, so anyone can check its work with SQL.

## Limits

- In the replay, tomorrow's weather was given as measured: a perfect forecast, the same for all forecasters. The live
  agent reads AEMET's forecast, which is not perfect.
- The model was not told the year, but it was told the month and the weekday.
- One winter, one model, one city. The surcharge question had two events, too few to rank anyone.
- The protocol's own thresholds (180 µg/m³ in an hour) have not been reached since 2021, so the replay scores the EU
  2030 rule, which is reached often.

## Reproduce it

The repository has the catalog's migrations and every scheduled query. It also has the agent's prompt, the replay
(`tools/replay.py`, with four forecasters and the scoring) and the page. The page is a LakehouseBox artifact that reads
the catalog in your browser: the learning curve, the calibration, the notebook day by day, and every forecast as a
table you can download.
