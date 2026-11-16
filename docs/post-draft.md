---
title: "Always-learning analytics: why agents don't have to start over"
description: "Analytics run by people learns slowly and then forgets when the person or the project moves on. We gave an agent a real daily job, Madrid's air, and measured what keeping its knowledge in tables is worth."
date: 2026-11-16
author: Javier de la Torre
category: Agents
draft: true
image: /assets/blog/always-learning-idea.svg
image_alt: "Two lines over time: a red sawtooth that rises and falls back as people and projects change, and a blue line that keeps rising."
resources: "The code|https://github.com/lakehousebox/aire-madrid; The page|<artifact link once public>"
---

Every analytics team knows this curve. Someone builds a model, a dashboard or a forecast. Over months they learn
where it goes wrong and correct it. Then they move to another project, or leave, and what they learned leaves with
them. The next person starts again, close to the bottom.

![Two curves over time. Red: people and projects, a sawtooth that rises slowly and falls back each time the knowledge leaves with someone. Blue: agents that keep their record in tables, a line that keeps rising.](/assets/blog/always-learning-idea.svg)

That is the red line: a sawtooth. Agents can draw the blue one, under one condition. What they learn must be kept
somewhere the next run, the next agent and the next person can read. In practice that means tables: every decision,
what happened, and how good the decision was. We call it **always-learning analytics**, and we wanted to know whether
it holds up on a real problem, with numbers.

## The job: Madrid's air, decided by noon

Madrid has a protocol for nitrogen dioxide (NO2). When pollution is forecast to be high, the city must announce
traffic restrictions before noon the day before. From 2030, EU rules make the limit much stricter: no station should
average more than 50 µg/m³ on more than 18 days a year. Last winter some station went over 50 on about a third of the
days.

So we gave an agent the city's job. Every day at noon it answers one question: **will some station go over 50
tomorrow?** It gives a probability and is scored the next day against what the stations measured.

Everything lives in one Apache Iceberg catalog on LakehouseBox: the city's hourly air quality since 2010 (20.8
million readings), its weather since 2019, the traffic, and the agent's own forecasts, outcomes and scores. The agent
is a LakehouseBox hosted agent that runs next to the data.

## The test: one winter, five kinds of memory

A live agent needs months before its learning shows. So we replayed a past winter, 1 October 2024 to 31 March 2025:
182 days. Each simulated day at noon, the forecasters saw only what was known at that hour. They all used the same
model and got the same brief: the last week, this morning's readings, tomorrow's weather and calendar. Only their
memory differed:

1. **No memory.** Every day starts from zero.
2. **Notes.** It keeps up to 12 lessons and rewrites them every day after seeing how it did. This is what "agent
   memory" usually means today.
3. **Its record, forgotten monthly.** It queries the table of its own scored forecasts, but the table is wiped on
   the 1st of every month: the person or the project changes.
4. **Its record, kept.** The same, never wiped.
5. **Its record plus the city's tables.** The same, and also the days of the last three years most like tomorrow,
   and what happened on them. The organisation's knowledge, from the first day.

## What we found

**Without memory, the agent makes the same mistake every day.** The model knows the meteorology: calm air and cold
clear nights build NO2 up. But it applied that too eagerly. It said 49% on average for something that happened on 35%
of the days, and it said so all winter. It never learns, because nothing tells it.

**Notes decay.** October 2024 was clean, and the notebook learned that one day at a time. By 18 November, 11 of its 12
lessons capped the chance of an exceedance at 20% or less. That day it said 15%; the model with no memory said 90%,
and a station went over. Over the winter, two thirds of all the lessons it wrote said the same. Notes are a summary of
the last few weeks, written as if they were rules, and they are hard to unlearn. That is the human sawtooth again:
knowledge kept as prose.

**Forgetting costs a week, every time.** In the first week of every month, the forecaster whose record had just been
wiped did worse than the one that kept it: in all six months, and on average exactly as badly as no memory. By the
third week it had caught up again.

![Extra error of the forecaster whose record is wiped on the 1st, by week of the month: clearly worse in week 1, level by week 3.](/assets/blog/always-learning-reset.svg)

**What compounds is what the organisation keeps.** The more knowledge the forecaster could query, the less it got
wrong:

![Less error than no memory, by what the forecaster keeps: notes 8%, record forgotten monthly 9%, record kept 13%, record plus the city's tables 18%.](/assets/blog/always-learning-ladder.svg)

The forecaster that read the city's tables did best: 18% less error than no memory, the one difference among these
that is clearly larger than the noise of a single winter. It did not need a record of its own to start: in October,
its first month, its error was 0.096 against 0.153 with no memory. It was also the only model to match the fixed
"almost never" rule on the rarest question we asked, the parking surcharge, which happened twice all winter. Its own
record could not teach it something that rare; three years of the city's history could.

## What this means

The gain did not come from a smarter model. All five forecasters used the same one. It came from what each was
allowed to keep, and from where that knowledge lived:

- **In a person's head, or in notes,** knowledge drifts and leaves. Every handover is a reset.
- **In tables,** the record does not drift, because it is facts rather than conclusions. It survives a handover: a
  new agent, a new person or a new question starts from it.
- **In shared tables,** one agent's record becomes the next one's starting point. The forecaster that started from
  the city's history did not have to learn the city again.

Its own record helped quickly, but more of it did not help further: a forecaster with three weeks of record did as
well as one with months of it. On one question, accuracy has a ceiling; tomorrow's air can only be predicted so well.
The compounding is not one forecast getting better forever. It is that nothing starts over: every run, every agent
and every new question builds on the tables the last one left.

## What the live agent does now

The hosted forecaster runs every day at noon. Before it forecasts, it reads its record: how often an event happened
when it gave each probability, and what happened on the past days most like tomorrow, from the city's history since
2019. It writes notes only for facts the data cannot show, such as a station out of service or roadworks. Its
forecasts, outcomes, scores and notes are all tables in the catalog, so anyone, person or agent, can check its work
with SQL.

## Limits

- One winter, one city, one model. Most differences between the forecasters are within the noise of 182 days. The
  clear ones are those above: the first week after forgetting, and the city's tables against no memory.
- In the replay, tomorrow's weather was given as it was measured: a perfect forecast, the same for every forecaster.
  The live agent reads a real forecast.
- The model was not told the year, but it was told the month and the weekday.

## Reproduce it

The repository has the catalog's migrations, every scheduled query, the agent's prompt and the replay
(`tools/replay.py`: the five forecasters, the fixed-rule baseline and the scoring). The page is a LakehouseBox artifact
that reads the catalog in your browser: every forecast of every forecaster, the calibration, the notebook day by day,
and a table you can download.
