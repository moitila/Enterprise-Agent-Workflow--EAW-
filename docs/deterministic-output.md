# Deterministic Output

EAW enforces a contract for output artifacts so they are machine-readable, versionable, and auditable.

Contract

- Every dossier is a Markdown file with a deterministic filename: `<TYPE>_<CARD>.md` (e.g., `feature_12345.md`).
- Context is stored under `out/<CARD>/context/<repoKey>/` with fixed filenames: `git-status.txt`, `git-diff.patch`, `changed-files.txt`, `rg-symbols.txt`.
- Templates must include sections in a predictable order so downstream tools can parse them.

Recommended sections (order is important):
1. Metadata (type, card, title, date)
2. Understanding / Summary
3. Scope / Impact Map
4. Risk
5. Strategy / Plan
6. Tests / Validation
7. Evidence / Context references
8. Decisions / Next steps

Rules
- No environment-specific paths embedded in the artifact; use `config/repos.conf` to map repo keys to paths.
- Use placeholders for dates and normalize them to ISO 8601 (`YYYY-MM-DD`).
- All commands that gather context must log outputs to the `out/` directory to ensure determinism.
