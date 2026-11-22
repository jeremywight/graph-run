# Changelog

## 1.0.0 (2026-11-22)

First public release, after the kit's first real run built [The Matchmaker](https://playthematchmaker.com).

- `/graph-run` command: bounded nodes, plan approval, correction and learning edges, handoff files for pausing and resuming.
- Specialists: the lead lists the judgment tests can't make, proposes a reviewer for each gap at plan approval, and proposes more when feedback shows a gap nobody gates.
- Security in three layers: checks on every stop, a design review for nodes that add attack surface, and a release gate.
- Human gates: plan approval, product decisions, reviewer escalations, risk acceptance, exhausted retries and irreversible actions.
- Agents: `graph-implementer` and a read-only `graph-verifier` that checks scope and looks for weakened or circular tests.
- Stop-hook gate with a 3-attempt cap, and permission settings that stop agents editing their own guardrails.
- Templates: domain and security reviewers, four example specialists, owner feedback, step prompts.
- Installer with `--update` (backs up what it replaces) and `--graph-dir`.
