# The post

"Always-learning analytics: why agents don't have to start over" is written in the main repository, as a draft:
`blog/2026-11-17-always-learning-analytics.md` in tablemere/tablemere (PR #3361), with its images in
`web/assets/blog/always-learning-*`.

Its diagrams are drawn here: `python3 tools/post_charts.py` writes `docs/charts/{idea,loop,trend,reset,ladder}.svg`
(the measured ones read `data/replay_load/forecasts.parquet`, which `tools/replay_load.py` writes). Copy them to
`web/assets/blog/always-learning-<name>.svg` there after a change.
