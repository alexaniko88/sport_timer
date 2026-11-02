# TASK 1.2: Document and protect layer boundaries

Story: [Refactor the application into layers](index.md)

Epic: [Layered application architecture](../../index.md)

Status: Ready for planning; coordinate with the migration.

## Goal

Make the agreed architecture understandable and prevent practical dependency regressions after the coordinated refactor.

## Scope

Update applicable project architecture guidance to reflect the final structure, dependency directions, shared code, composition, and when use cases are appropriate. Add the smallest practical automated checks for forbidden dependencies, including platform-specific imports in domain code. Avoid duplicating global rules or adding an unnecessary package.

## Dependencies

Coordinate with [the application migration](01-migrate-application.md); choose and validate checks against its final structure and deliver together.

## Acceptance criteria

- Project guidance describes the actual layered layout and dependency rules without contradicting the implementation.
- Automated checks detect representative forbidden dependencies and pass for the migrated code; their scope and any limitations are documented.
- The check is runnable in the project's normal validation workflow without requiring unavailable infrastructure.

## Validation

Run the new checks against the migrated code and verify that representative forbidden imports are detected. Run applicable analysis and tests; explain any gap that cannot be automatically enforced.

## Implementation context

Review `CLAUDE.md`, applicable project rules, CI configuration, and existing lint setup before selecting the implementation. Follow the applicable orchestration workflow.
