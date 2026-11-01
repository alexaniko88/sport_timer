# TASK UI 1.3: Replace the Home tab icon and label

Story: [Timer setup refactor](index.md).

Epic: [UI refactor](../../index.md).

Status: Blocked by [UI 3.1](../03-start-button-refactor/01-refactor-timer-setup-start-button.md).

## Goal

Make the bottom-bar destination describe Timer Setup with a timer icon and a matching localized name.

## Scope and exclusions

- Replace the house with an outlined timer icon when unselected and its filled counterpart when selected, following the existing Material icon convention.
- Rename this tab's label and tooltip to “Timer” in English and “Temporizador” in Spanish; align its accessibility text with the new name.
- Preserve the current theme colors, sizing, selected-state behavior, destination, tab order and timer behavior.
- Exclude Start changes, other navigation labels, drawer changes and additional UI redesign.

## Dependencies

Deliver after [UI 3.1](../03-start-button-refactor/01-refactor-timer-setup-start-button.md) changes Timer Setup's Start icon to play, so the destination and its Start action use distinct symbols. UI 1.1, provisional wheel styling and the Templates drawer move are not prerequisites. Preserve the navigation available in the implementation checkout.

## Acceptance criteria

- Timer Setup's bottom-bar tab uses an outlined timer when inactive and a filled timer when selected; no house icon remains on that tab.
- The visible label, tooltip and accessible destination name use “Timer” / “Temporizador” in the appropriate language.
- Timer Setup's Start action uses play when this change is delivered.
- Selecting the tab still opens Timer Setup and preserves settings and existing navigation behavior.
- The icon and label remain readable in light/dark themes and with large text, with no clipped label or reduced tap target.

## Validation

Verify both selected states, English/Spanish labels, tooltip and semantics, both themes and large-text fit. Reuse relevant existing navigation checks where available; run applicable formatting, localization generation and analysis checks during implementation. User manual validation covers visual distinction between the timer tab and play Start action.

## Implementation context

- `lib/presentation/home/home_page.dart`: first bottom-bar destination currently uses `Icons.home_outlined` / `Icons.home` and opens `TimerSetupPage`.
- `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`: current `homeTabHome` and `homeTabHomeTooltip` strings are Home / Inicio. Review key naming and generated localization references during planning.

Read the parent story and follow the applicable orchestration workflow. Backlog agreement does not approve application code changes.
