# Example specialists

Four reviewers from the [case study](../../../docs/case-study.md) run, lightly generalized. Each one shows a different kind of judgment that tests can't make:

| File | Judges | Reviews |
|---|---|---|
| [puzzle-master.md](puzzle-master.md) | Whether generated puzzles are fair, satisfying and honestly difficult | The design before the build, then real samples after |
| [period-expert.md](period-expert.md) | Voice, period accuracy and anachronism in written content | A voice guide before content is written, then the content |
| [ui-designer.md](ui-designer.md) | Taste, legibility and accessibility of the built screens | A spec before the build, then the built screens |
| [game-designer.md](game-designer.md) | Whether players have a reason to come back | Features and designs, against play statistics |

To use one, copy it to `.claude/agents/`, rename it, and replace the parts in angle brackets. Notice what they have in common: a specific expert with standards, an instruction to disagree, evidence over descriptions, must-fix separated from taste, and a fixed return format the lead can gate on.
