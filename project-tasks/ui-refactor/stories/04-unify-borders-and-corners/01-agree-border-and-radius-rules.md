# TASK UI 4.1: Audit and agree shared border and radius rules

Story: [Unify borders and corner radii](index.md).

Epic: [UI refactor](../../index.md).

Status: Ready for planning.

## Goal

Produce an agreed, app-wide rule set for corner radii and border widths that the migration can apply without inventing design choices.

## Scope and exclusions

- Inventory current radii, border widths, outlined component states and implicit theme defaults across screens, shared widgets and overlays.
- Propose a small shared scale and component/state mapping, starting from current Templates styling and existing theme building blocks.
- Identify justified exceptions and any conflicts with pending UI requirements. Confirm the proposed values and exceptions with the user.
- Record repository entry points and the location of shared definitions for UI 4.2. Do not change application code in this task or expand into other styling decisions.

## Dependencies

None. Inspect the actual checkout rather than assuming pending UI work is available.

## Acceptance criteria

- A repository-relative inventory covers all existing screens and overlays with borders or rounded shapes, including theme-provided defaults.
- The user has agreed the proposed values, role/state mapping and documented exceptions.
- The decision records how to handle pending UI stories' radius and border requirements and gives UI 4.2 a clear migration checklist.

## Validation

Cross-check the inventory against theme configuration and widget usage. Review the mapping for normal and interactive states in both themes. Record the approved decision location in this story; an unapproved proposal does not unblock UI 4.2.

## Planning entry points

Inspect `lib/theme/` and `lib/presentation/`, including shared widgets and page-specific styling. These directories exist; exact values and APIs have not been audited for this story.
