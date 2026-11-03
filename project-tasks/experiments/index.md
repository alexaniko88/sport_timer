# EPIC: Experiments

Status: Agreed scope; Story 1 ready for planning, Stories 2 to 4 depend on earlier stories.

## Goal

A home for experiments on the AI workflow of this repo: try an idea on a small, safe piece first, measure it, and only then decide to keep it. The first experiment is to run some orchestrator roles on a local model, to spend less Claude usage and keep code on the machine.

## Agreed behavior and boundaries

- First experiment: the local model is `qwen3.8:27b` through Ollama, for every local role. No other model is tested.
- Roles move one at a time, in this order: plan reader, small implementer steps, test and analyze summaries. A stage moves only after the previous one looks good.
- Planning, grilling, bug investigation, estimates and PR review stay on Claude. A local implementer step is always followed by Claude's `agent-pr-review`.
- A local role never touches the working tree directly: read-only roles only read, and edit roles work in a throwaway copy and return a patch.
- If Ollama or the runner script is missing, the role runs on Claude as it does today. Nothing breaks without the local setup.
- Out of scope: other local models, MLX or LM Studio runners, and moving review or planning to a local model.

## Decisions and current constraints

- **Model:** `qwen3.8:27b` only (user decision).
- **Runner (user decision):** everything lives in this repo, under `.agents/skills/skill-orchestrator/`. Nothing outside the repo is changed or depended on, so the repo works on its own. The runner is a small script written in this repo that runs `claude -p` against Ollama (read-only, with a timeout) and falls back to Claude when Ollama or the script is missing.
- **Why a script:** the Agent tool only accepts Claude models, so a local model is called through a Bash script, not through the Agent tool.
- **Context size:** the `multi-qwen-dense` Ollama alias uses the same weights with a 64k context, and Claude Code assumes 200k. Briefs must stay short. Whether to use the alias or `qwen3.8:27b` directly is decided in Story 1.
- **Savings are unmeasured.** Story 2 is the evidence gate.
- **Commit trailer:** this repo requires a `Co-Authored-By` trailer naming the real author. A local model must never sign as Claude, so commit messages stay on Claude.

## Stories

1. [Plan reader runs on the local model](stories/01-local-plan-reader/index.md) — ready for planning.
2. [Compare local and Claude on a real plan](stories/02-compare-local-vs-claude/index.md) — depends on Story 1.
3. [Small implementer steps on the local model](stories/03-local-implementer-steps/index.md) — provisional, depends on Story 2.
4. [Test, analyze and summary helpers](stories/04-local-helpers/index.md) — provisional, depends on Story 2.

## Delivery order

Story 1, then Story 2. Stories 3 and 4 start only if Story 2 records a go decision, and they are independent of each other.
