# STORY 4: Test, analyze and summary helpers

Epic: [Experiments](../../index.md)

Status: Provisional. Starts only after a go decision in [Story 2](../02-compare-local-vs-claude/index.md).

## User outcome

As the repo owner, I want the local model to summarize format, analyze and test output so that these simple reads cost no Claude usage.

## Scope

- Run the commands and give a short plain-English result.
- Excludes: writing commit messages (the required `Co-Authored-By` trailer must name the real author, so they stay on Claude), and writing or changing tests.

## Acceptance criteria

- The summary names every failing test or analyze issue with `file:line`, and matches the raw output.
- A failing command is never reported as passing.

## Tasks

1. [Summarize format, analyze and test output locally](01-summarize-command-output.md).

## Dependencies and open decisions

- Provisional: confirm after Story 2. Speed may matter more here, so the faster `qwen3.6:35b-a3b` could be reconsidered, but only by a new user decision.
