-- The replay (tools/replay.py): past winters forecast day by day by several forecasters, to see whether one that keeps
-- a notebook of its mistakes gets better. One row per forecaster, day and question; and the notebook, day by day.

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.agent.replay_forecasts (
  replay VARCHAR NOT NULL,
  arm VARCHAR NOT NULL,
  made_on DATE NOT NULL,
  target_day DATE NOT NULL,
  question VARCHAR NOT NULL,
  probability DOUBLE NOT NULL,
  outcome INTEGER NOT NULL,
  brier DOUBLE NOT NULL,
  expected_worst_mean DOUBLE,
  observed_worst_mean DOUBLE,
  rationale VARCHAR
);
COMMENT ON TABLE aire_madrid.agent.replay_forecasts IS 'Replay of a past winter: each day at noon three forecasters predict tomorrow. arm: persistence (a fixed rule: how often a day like yesterday was followed by an event in the last 28 days), fresh (the model, no memory), memory (the model plus its own notebook of lessons and scorecard, rewritten daily after seeing how it did). question: any_over_50 (some station daily NO2 mean > 50, EU 2030), five_over_50 (5+ stations > 50), ser_over_60 (background mean > 60, parking surcharge). brier = (probability - outcome)^2, lower is better. Limits: tomorrow''s weather given as measured (a perfect forecast); the year hidden from the model.';

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.agent.replay_memory (
  replay VARCHAR NOT NULL,
  day DATE NOT NULL,
  lessons VARCHAR NOT NULL,
  note VARCHAR
);
COMMENT ON TABLE aire_madrid.agent.replay_memory IS 'The memory forecaster''s notebook in the replay, as it stood after each day''s review: lessons is a JSON array of up to 12 one-sentence lessons; note is what it changed and why.';
