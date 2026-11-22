# Case study: The Matchmaker

The first real run of this kit built [The Matchmaker](https://playthematchmaker.com), a daily matchmaking logic puzzle for Jane Austen readers. It's a mobile web app built with Vite, React and TypeScript. Every date produces a unique, deterministic puzzle that a person can solve without guessing, with clues and letters written in a period voice.

It's a good test because "correct" has two halves. Some of it a machine can check: unique solutions, determinism, types, the build. Some of it only an expert can judge: is the puzzle fair and satisfying, does the prose sound like 1813, is the design legible on a phone.

## The team

| Agent | Role | Can edit |
|---|---|---|
| Lead (the main session) | Plans the graph, routes work, merges, records decisions | `graph/**`, and commits |
| `graph-implementer` | Builds one node | That node's allowed paths only |
| `graph-verifier` | Re-runs the node's check and inspects the diff | Nothing |
| `puzzle-master` | Veteran puzzle setter. Reviews the engine design before it's built and play-tests samples after | Its review file |
| `austen-expert` | Regency-period scholar. Writes the voice guide and reviews names, clues, letters and interface copy | Its review file |
| `ui-designer` | Writes the design spec and tokens, then reviews the built screens | Spec and tokens |
| `game-designer` (added later) | Gamification and player motivation: reviews features for whether they make the game worth coming back to | Its review file |
| The owner (human) | Approves the plan, makes product calls, plays the build | Anything |

## By the numbers

- 18 planned nodes (the limit started at 11 and was raised three times as the owner added reviewers and scope)
- About 4 days of active work for the main run; 507 tests, clean typecheck and build at the end
- Stop gate: **81 passes, 40 blocks** (51 logged failures; on 11 of them, the fourth attempt, the gate let the agent stop and report instead of looping)
- 16 decisions logged as the owner's; the rest logged as the lead's, so the owner could overturn them
- Reviewer rounds: engine design (1), play-tests (3, plus a levels play-test), content (4), design (2), final copy (2)

## Six things that happened

**1. A reviewer changed the design before any code existed.** The puzzle master was placed *before* the engine build. It prototyped the lead's design and showed that greedy clue selection always produced a disguised direct clue, a giveaway. It returned `revise` with 12 must-fix items. All were accepted, and the engine was respecified before a line was written. The cheapest bug is the one caught in the design.

**2. The verifier caught the builder making a test circular.** During the difficulty-levels change, a 1,000-date test that checked each puzzle's weekday quietly started asserting something the code under test itself decided. The suite was green. The verifier read the test diff, called it a lost check, and failed the node. It went back to the builder as attempt 2.

**3. Two experts found the same rule independently.** The puzzle master and the Austen expert, reviewing different things, both concluded that a clue must state an outcome, not a sentiment. In Austen, quarrelling couples marry and admirers are refused. That became a learned rule for the content.

**4. The lead's own mistake became a rule.** One commit, meant to hold only the plan file, also carried a staged deletion of the 1,000-date test, so main briefly lacked it. The fix wasn't a lecture. It was a learned rule: `git status --short`, `git add` explicit paths including new files, `git diff --cached --stat`, then commit.

**5. Hitting the usage limit lost nothing.** Three agents working in parallel were all stopped by the account's usage limit part way through. Because every agent saves as it goes, they were resumed from their files after the reset, and nothing was lost. One step that didn't save section by section lost its work twice (once to a pause, once to the limit), so the step prompts were changed to require it.

**6. Security earned its own gate.** The first run had no security reviewer, so the owner asked for one-off reviews as the game grew. The first added a few missing security headers. The second came after a feedback form and play statistics were added, and found something no single file showed: each table was anonymous on its own, but joined on the device id, a player's feedback email linked to their play history. The owner chose to keep that link on purpose and document it. Both reviews worked, but only because the owner thought to ask. The kit now asks for them: a security reviewer runs when a node adds attack surface, and again before release.

## Where the human was needed

The owner didn't watch the agents work. The owner showed up at the gates:

- **Approved the plan** before any source file existed, and raised the node limit when adding scope.
- **Spotted the judgment nobody was gating.** The Austen expert was added at the owner's request before the build, because no test can tell whether prose sounds like 1813. After a playtester's feedback, the owner added a game designer, because the puzzle master judged whether each puzzle was fair, and nobody judged why a player would want to come back. Both gaps were the owner's to see. The kit now proposes specialists at plan approval so that question gets asked up front.
- **Made product calls the agents raised:**
  - clue count per puzzle
  - what a wrong answer reveals (a count and the contradicted clue, never which couple)
  - whether weekend puzzles may run longer
  - three difficulty levels in place of difficulty by weekday
- **Played the build** and gave feedback ("it was hard to track guesses", "nothing happens on a correct solution"). That became a numbered feedback file. Each item went to the designer first, then a build node, then a reviewer.
- **Paused and resumed the run** across sessions, using the handoff file and one prompt per remaining step.
- **Kept the irreversible actions:** merges, pushes and deploys asked first.

## What it didn't do

- It didn't replace judgment. Every product decision was the owner's, and several expert rulings were left marked "check" for the owner rather than treated as settled.
- It wasn't cheap in tokens. Fresh-context subagents and multiple review rounds cost far more than one session would have. The trade is work you can trust and resume.
- Scrolling on the largest puzzles stayed a reported fail, left for the owner to judge on a phone, not hidden as a pass.
