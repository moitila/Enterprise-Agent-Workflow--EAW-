# Risk Model

This practical risk model focuses on signals that matter in complex systems.

- Hotspots: files or modules that change often or that historically cause regressions.
- Regression potential: likelihood that a change will break existing behaviour (depends on test coverage, complexity, and coupling).
- Blast radius: the scope of impact if a change fails (service level, consumers, downstream systems).
- Gates: required checks before merging (unit tests, integration tests, staged rollout, feature flags).

Practical use:
- Map hotspots early when defining scope.
- Use blast-radius to decide deployment strategy (canary, feature flag, or full roll-out).
- Define clear regression tests in the dossier and make them part of the gate.

Signals collected by EAW's context capture help quantify these dimensions deterministically.
