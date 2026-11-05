---
id: IMP-04
status: draft
type: improve
depends-on: []
---

# Align timer setup summary and Start styling

Improvements: [Improvements](../index.md)

## Current behavior and benefit

The session length label and duration use the default text style, and the Start button's text and icon are smaller than the setting cards' content. Aligning them with the grid gives the setup screen a consistent visual hierarchy and makes the Start action easier to see.

## Scope and decisions

- Match the session length label to the grid card labels and its duration to the grid card values, including text size and weight.
- Match the Start label to the grid card value text size and weight, and match its play icon size to the grid card icons. Let the button grow to fit.
- Keep the visual treatment consistent with the shared theme in light and dark modes. Check whether theme styles need updating so the relevant styles stay in sync, without changing unrelated controls unnecessarily.
- Preserve the current session length calculation, Start action, navigation and accessibility behavior. This is not a redesign of the grid cards.

## Dependencies

None. Check the implementation checkout and current theme before planning.

## Acceptance criteria

- The session length label and duration visually match the corresponding grid labels and values in size and weight.
- The Start label matches the grid values in size and weight; its play icon matches the grid icon size. The button accommodates its content without clipping.
- Both themes remain legible and consistent. The summary and action remain usable with narrow layouts, larger text and English and Spanish labels.
- Starting a session and its accessible activation continue to work as before.

## Validation

Use focused widget checks where needed for styling, layout and activation; verify both themes, localized labels, narrow layouts and large text. Refresh affected UI snapshots and maintain the snapshot index if its descriptions or flow links change, following repository instructions. Run the applicable project checks.

## Implementation context and visual references

The summary and Start action are in `lib/features/settings/presentation/timer_setup_page.dart`; grid styling is in `lib/features/settings/presentation/widgets/timer_setting_card.dart`. Inspect the shared text and button themes during planning.

The current [custom setup](../../../test/snapshots/goldens/setup_custom.png) and [template-selected setup](../../../test/snapshots/goldens/setup_template_selected.png) snapshots show both themes. The [snapshot index](../../../test/snapshots/README.md) describes the states and navigation; these images do not establish coverage for narrow layouts or larger text. Check the implementation checkout for newer behavior before starting.
