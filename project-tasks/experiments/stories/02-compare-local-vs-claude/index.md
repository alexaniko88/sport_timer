# STORY 2: Compare local and Claude on a real plan

Epic: [Experiments](../../index.md)

Status: Depends on Story 1.

## User outcome

As the repo owner, I want evidence of how the local model compares with Claude so that I decide to keep, widen or drop the experiment with facts.

## Scope

- One real, finished plan from this repo, read by the plan reader on both the local model and Claude.
- A short recorded result and a go or no-go decision.
- Excludes: benchmarks outside this repo.

## Acceptance criteria

- The record lists, for each run: the guesses and unclear steps found, anything invented, the final `clear` or `needs changes`, and the time taken.
- The decision is written down with the reason, and the epic status is updated from it.

## Tasks

1. [Run the comparison on a real plan](01-run-comparison.md).
2. [Record the result and the decision](02-record-decision.md).

## Dependencies and open decisions

- Depends on [Story 1](../01-local-plan-reader/index.md).
- Open: which finished plan to use. It should have 4 or more steps, so the cold read applies.
