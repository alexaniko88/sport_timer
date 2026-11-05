---
id: ARCH-01-02
status: done
type: feat
depends-on: [ARCH-01-01]
---

# Document and protect layer boundaries

Story: [Refactor the application into layers](../../index.md)

Epic: [Layered application architecture](../../../../index.md)

## Goal

Make the agreed architecture understandable and prevent practical dependency regressions after the coordinated refactor.

## Scope

Update applicable project architecture guidance to reflect the final structure, dependency directions, shared code, composition, and when use cases are appropriate. Add the smallest practical automated checks for forbidden dependencies, including platform-specific imports in domain code. Avoid duplicating global rules or adding an unnecessary package.

## Dependencies

Coordinate with [the application migration](../01-migrate-application/index.md); choose and validate checks against its final structure and deliver together.

## Acceptance criteria

- Project guidance describes the actual layered layout and dependency rules without contradicting the implementation.
- Automated checks detect representative forbidden dependencies and pass for the migrated code; their scope and any limitations are documented.
- The check is runnable in the project's normal validation workflow without requiring unavailable infrastructure.

## Validation

Run the new checks against the migrated code and verify that representative forbidden imports are detected. Run applicable analysis and tests; explain any gap that cannot be automatically enforced.

## Implementation context

Review `CLAUDE.md`, applicable project rules, CI configuration, and existing lint setup before selecting the implementation. Follow the applicable orchestration workflow.

## Completion evidence

- `test/architecture/layer_boundaries_test.dart` reads the imports of every file under `lib/` and enforces the layer rules, with tests that feed it forbidden imports. It runs with `fvm flutter test`, so CI covers it. Its scope and limits are documented in the file and in `CLAUDE.md` ("Boundary check").
- `CLAUDE.md` describes the real layout, dependency rules, extensions and when to add a use case; `AGENTS.md` and `GEMINI.md` link to it. The orchestrator skill, the style rule and the Codex agents carry the same rules.
- `fvm flutter analyze` reports no issues and the full suite passes (275 tests).
