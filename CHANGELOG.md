# Changelog

## 1.1.1 (2026-11-23)

- **README:** "What you get" now says exactly what the kit installs (the command, two agents, the gate, settings) and states plainly that each run proposes custom specialists for its task, which you approve before their agent files are written. The case-study excerpts moved to "Example from the case study", with each agent labelled as from the kit or proposed for that project.

## 1.1.0 (2026-11-23)

- **Outside agents:** a new `<outside_agents>` section in `/graph-run` for work done better by a tool outside Claude Code (for example image generation in another agent). It is paired with a Claude coordinator; they exchange files and `READY-n` / `DONE-n` / `ALL-DONE` markers through a shared folder; the setup lives in `graph/agents/` and the protocol is copied into the repo. New templates: `templates/agents/coordinator.md` and `templates/outside-agent.md`. An "Outside agents" table in graph.md.
- **Test-only code kept out by the build:** the production build itself fails when test-only or debug code is present (platforms often run only the build), with the same check in the gate; an example line in `examples/gate-commands.security`.
- **Flaky checks:** fix how a test waits before anything else; a tolerance on a timing or rate threshold loosens the check and needs the owner's approval, logged.
- **Write back before closing:** at the end of every phase and before any session closes, the lead asks the owner "What should we write back to our graph run?" and records agents, outside agents' setup, protocols, decisions and learned rules, so the team can be recreated after its sessions are gone. Also asked at delivery. Work with large outputs kept outside the repo (recordings, marketing GIFs) keeps its agent and recipe in the repo.

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
