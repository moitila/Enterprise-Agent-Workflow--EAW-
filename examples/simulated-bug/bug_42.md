---
type: Bug
card: 42
title: "Crash on startup when config missing"
date: 2026-02-16
---

# Expected vs Actual

Expected: service starts with default configuration.
Actual: process exits with stack trace due to nil dereference.

# Reproduction

Start service with empty config directory.

# Diagnosis (evidence)

Error trace indicates null pointer in config loader; missing default fallback.

# Minimal Fix

Add fallback defaults in the loader and guard nil access.

# Regression Plan

Unit test for defaulting + smoke start in CI.
