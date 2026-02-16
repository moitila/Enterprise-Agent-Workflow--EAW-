---
type: Spike
card: 7
title: "Investigate alternate DB indexing strategy"
date: 2026-02-16
---

# Question

Can a covering index reduce P99 query latency for the metrics endpoint?

# Hypotheses

A covering index on (user_id, metric_ts) will reduce IO and latency.

# Plan

Create bench workload, measure before/after.

# Findings

(placeholder) — bench results go here.

# Decision

If P99 improves by >20% and write amplification is acceptable, adopt index.

# Next Steps

If adopted, create migration with backfill window and monitor.
