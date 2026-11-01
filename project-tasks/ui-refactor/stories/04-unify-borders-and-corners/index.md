# STORY 4: Unify borders and corner radii across the app

Epic: [UI refactor](../../index.md).

Status: Ready for planning; shared values and exceptions must be agreed before implementation.

## User outcome

As a user, I want consistent corner shapes and border thickness across the app so that screens and controls feel like one product.

## Scope

- Cover corner radii and border widths throughout the app, including cards, buttons, inputs, dialogs, sheets, pickers, navigation surfaces and active-timer UI wherever these treatments exist.
- Establish shared rules by component role and state, then replace one-off values with the agreed shared treatment. Consistency does not require every component to have the same shape or an outline.
- Use the current Templates treatment and existing theme building blocks as the starting reference. Exact values, state differences and justified exceptions remain decisions for Task UI 4.1.
- Preserve light/dark support, visible selection and focus, clipping, hit areas and existing behavior.
- Exclude changes to colors, typography, spacing, navigation and features. Other UI stories retain ownership of their layouts and behavior; this story owns the shared radius and border-width rules.

## Acceptance criteria

- An agreed inventory maps existing component roles and states to shared radius and border-width rules, with any exceptions explained.
- All existing app screens and overlays follow those rules; equivalent components do not retain conflicting local values.
- Default, selected, focused, disabled and error states use the agreed rules wherever applicable, without layout jumps or lost state visibility.
- Light and dark themes remain usable, with no new clipping, overflow or behavior changes.

## Tasks

1. [Audit and agree shared border and radius rules](01-agree-border-and-radius-rules.md) — Ready for planning.
2. [Apply shared border and radius rules app-wide](02-apply-border-and-radius-rules.md) — Blocked by UI 4.1.

## Dependencies and open decisions

No pending UI story is a prerequisite for the audit. Verify the implementation checkout and coordinate with Stories 1–3 and provisional picker styling; do not implement their unrelated layout work. Record how any existing explicit border requirements map to the shared rules, and resolve conflicts before migration. The broader [styling improvement](../../../improvements/01-unify-styles-app-wide.md) excludes this story's scope.

Task UI 4.1 must settle the radius scale, border widths by role/state, circular or pill-shaped exceptions, and where shared definitions belong. No numeric values or new shared API are approved by this backlog. Backlog agreement does not approve application code changes.
