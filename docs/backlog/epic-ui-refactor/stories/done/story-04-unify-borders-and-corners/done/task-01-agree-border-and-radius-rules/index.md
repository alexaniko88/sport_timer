---
id: UI-04-01
status: done
type: feat
depends-on: []
---

# TASK UI 4.1: Audit and agree shared border and radius rules

Story: [Unify borders and corner radii](../../index.md).

Epic: [UI refactor](../../../../../index.md).

## Completion evidence

IMP-01 delivered the shared values, state rules and exceptions, merged as `17115f2` in PR #42. The [story inventory](../../index.md#component-inventory-and-shared-rules) maps those rules to the current app and identifies the drawer treatment completed by UI 4.2. The user approved the completed implementation and tests, and review passed cleanly on `improve/unify-borders-corners`; its PR is pending.

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

Inspect `lib/shared/presentation/` and `lib/features/*/presentation/`, including shared widgets and page-specific styling. These directories exist; exact values and APIs have not been audited for this story.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [templates_selected](../../../../../../../../test/snapshots/goldens/templates_selected.png), [setup_custom](../../../../../../../../test/snapshots/goldens/setup_custom.png), [setup_time_picker](../../../../../../../../test/snapshots/goldens/setup_time_picker.png), [home_drawer](../../../../../../../../test/snapshots/goldens/home_drawer.png), [account_sheet](../../../../../../../../test/snapshots/goldens/account_sheet.png), [account_sign_out_dialog](../../../../../../../../test/snapshots/goldens/account_sign_out_dialog.png), [statistics](../../../../../../../../test/snapshots/goldens/statistics.png), [timer_styles](../../../../../../../../test/snapshots/goldens/timer_styles.png), [login](../../../../../../../../test/snapshots/goldens/login.png), [timer_ring_round](../../../../../../../../test/snapshots/goldens/timer_ring_round.png), [timer_full_color_round](../../../../../../../../test/snapshots/goldens/timer_full_color_round.png), [timer_rounds_strip_round](../../../../../../../../test/snapshots/goldens/timer_rounds_strip_round.png). See the [snapshot index](../../../../../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. Use the reference to inform the outstanding decisions without approving a layout or values in advance.
