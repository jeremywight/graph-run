# Step <NN>: <node id and name>

Agent: `<graph-implementer | graph-verifier | your reviewer>`
May start when: <the steps that must be verified and committed first>

## Prompt (copy as written)

> You are building node <id> of a /graph-run graph in <repo path>. Read <input paths> first.
>
> Allowed paths: <globs>. If the work needs any other file, stop and report it as a blocker.
>
> Work list:
> 1. <item, specific enough to verify>
> 2. <item>
>
> Required tests:
> - <behaviour the test must assert>
>
> Node check: `<command(s)>`. Run it against your saved files before reporting.
>
> Save as you go: write files early, save code with its test after each item. Do not weaken, skip or delete any existing test.
>
> Report: Outputs, Verdict (pass | fail), Evidence (command + last lines), Notes (at most 5 lines).
