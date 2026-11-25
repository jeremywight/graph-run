# Changelog

## 1.2.0 (2026-11-25)

Security and reliability fixes from a review of the whole repo.

- **Gate:** a check that reads stdin can no longer swallow the checks after it (each one now runs with stdin from `/dev/null`). Before this, such a check could let the gate pass without running the lines below it.
- **Gate:** the attempt counter is read as digits only and never evaluated, so a crafted `graph/.gate_attempts` can't run code. Edits to the counter are denied.
- **Settings:** dropped the unscoped `Read`, `Grep` and `Glob` allow rules (reading inside the project needs no rule) and denied reads of `~/.ssh`, `~/.aws` and `~/.config/gh`. `npx` rules and the sample check use `--no-install`, so a missing tool fails instead of being downloaded.
- **Installer:** `--graph-dir` now also rewrites the paths in `settings.json`, refuses names with characters other than letters, digits and `._/-` (which could have injected shell code into the gate), and reports a missing value. It no longer joins its `.gitignore` lines onto a last line that has no newline.
- **README:** says plainly that the allow rules decide what runs without asking and are not a sandbox, and rates the gate and deny rows accordingly.
- **Existing installs:** `--update` replaces the gate hook but never your `settings.json`. Make the settings changes above by hand.

## 1.1.2 (2026-11-24)

- **Gate commands need approval:** `Edit(.claude/gate-commands)` moved from `allow` to `ask` in `settings.json`. The Stop hook runs each line of that file as a shell command, outside Claude's permission rules, so a silent edit could run blocked commands (`curl`, `rm`, `git push`) or open the gate with `true`. `/graph-run` writes the file at planning, so this adds one prompt when you approve the plan. Existing installs: `--update` doesn't touch `settings.json`, so make this change by hand.

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
