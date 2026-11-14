-- What the forecasting agent writes: one row per question it answers each day, checked by now.scored_predictions.

-- lhbox: format-version=2
CREATE TABLE IF NOT EXISTS aire_madrid.agent.predictions (
  made_at TIMESTAMPTZ NOT NULL,
  target_day DATE NOT NULL,
  question VARCHAR NOT NULL,
  scope VARCHAR NOT NULL,
  probability DOUBLE NOT NULL,
  expected_value DOUBLE,
  would_restrict BOOLEAN,
  rationale VARCHAR,
  run_id VARCHAR
);
COMMENT ON TABLE aire_madrid.agent.predictions IS 'The agent''s forecasts, written at noon for the next Madrid day (the protocol''s own deadline for announcing restrictions). question names a rule in ref.rules (eu2030.no2.day, who2021.no2.day, protocol.no2.preaviso, ser.no2.surcharge60, …); scope is a station code, a zone (zone:1) or city. probability is its P(exceeded); now.scored_predictions checks it the day after.';
COMMENT ON COLUMN aire_madrid.agent.predictions.would_restrict IS 'Whether the agent would have the city restrict traffic tomorrow under this rule set (its recommendation, not the city''s decision).';
COMMENT ON COLUMN aire_madrid.agent.predictions.run_id IS 'The hosted agent run that wrote it: its reasoning and memory are in that run.';
