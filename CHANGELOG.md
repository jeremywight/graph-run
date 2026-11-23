# Changelog

## Unreleased

- **Outside agents:** a new `<outside_agents>` section in `/graph-run` for work done better by a tool outside Claude Code (for example image generation in another agent). It is paired with a Claude coordinator; they exchange files and `READY-n` / `DONE-n` / `ALL-DONE` markers through a shared folder; the setup lives in `graph/agents/` and the protocol is copied into the repo. New templates: `templates/agents/coordinator.md` and `templates/outside-agent.md`. An "Outside agents" table in graph.md.
- **Write back before closing:** at the end of every phase and before any session closes, the lead asks the owner "What should we write back to our graph run?" and records agents, outside agents' setup, protocols, decisions and learned rules, so the team can be recreated after its sessions are gone. Also asked at delivery.

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
