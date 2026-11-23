# <Outside agent>: how to recreate it

<!--
Copy to graph/agents/<name>.md and fill in. /graph-run's <outside_agents> section explains the pattern.
This file is what lets someone rebuild the pipeline after the sessions are closed.
-->

**Why this tool (owner, <date>):** <what it does better than Claude Code can, in the owner's words>. Claude's own alternative, if any: <agent and what it is still used for>.

**Paired with:** the Claude coordinator `.claude/agents/<work>-coordinator.md`.

<Tool> is not a Claude Code agent type, so it cannot be spawned with the Agent tool. The owner starts it.

## Setting it up
1. **The shared folder** (outside the repo): `<path>` with `incoming/`, `feedback/`, a status list and the protocol (copy `graph/design/<work>-coordination.md` there if starting fresh). The outside agent reads and writes only this folder.
2. **Give it read access to the brief:** `<path to the brief>`.
3. **Start a <tool> session** in the shared folder and paste the prompt below. Then start the coordinator.

## The starting prompt
```
You are the <role> for <project>. You <make what> with <your capability>; you never touch the project's repository.

Read, in this order: <protocol file> (you are "<name>" in it), feedback/next.md (your standing instructions,
the learned rules and the current phase), <status list>, and the brief at <path>.

For each batch n:
1. Make the items listed for the batch, as the brief and the standing instructions say.
2. Save them to incoming/ with the brief's exact names; a retry adds -v2, -v3 ...
3. Write incoming/BATCH.md: every item with exactly what you were asked or prompted with.
4. Only then write the empty marker incoming/READY-<n>.
5. Wait for feedback/DONE-<n> (check every <2> minutes), read feedback/batch-<n>.md, and make the retries
   and the next items as batch n+1. Batch numbers only go up; never rewrite a marker.
Stop when ALL-DONE exists in the folder root.
```

## What good looked like
- <batch size, trial set first, the owner's look before each new phase>
- <the learned rules>
- <sizes, formats, and what the coordinator converts on the way in>
