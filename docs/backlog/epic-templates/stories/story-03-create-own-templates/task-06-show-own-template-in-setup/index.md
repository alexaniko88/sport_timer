---
id: TPL-03-06
status: ready
type: feat
complexity: 2
depends-on: [TPL-03-05, IMP-05]
touches:
  - lib/features/settings/presentation/timer_setup_page.dart
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/setup_own_template_selected.png
skills: []
---

# Show the own template in Timer Setup

Story: [Create your own templates](../index.md)

Epic: [Templates](../../../index.md)

## Goal

When an own template is selected, the template tag on Timer Setup shows its icon and name instead of "Custom". Serves R8.

## Context

- After Add a shared AppTag widget and use it on Timer Setup (IMP-05), `lib/features/settings/presentation/timer_setup_page.dart` shows an `AppTag` above `TimerSettingGrid` once settings have loaded: built-in (`state.selectedTemplateId case final id?`) → `icon: id.icon`, `label: l10n.templateName(id)`; otherwise Custom → `icon: Icons.tune`, `label: l10n.templateCustomName`; both with `color: colorScheme.surfaceContainer`, `onTap: onTemplatesPressed`, `semanticLabel: l10n.setupTemplateLabel(label)`.
- Reference golden: `test/snapshots/goldens/setup_template_selected.png` (after IMP-05) and its scenario in `test/snapshots/ui_snapshots_test.dart`.

## Contract

- `SettingsState.selectedCustomTemplate` — provided by TPL-03-04.
- `CustomTemplateIconData.iconData` and the harness parameter `configureFakeDependencies(customTemplates:)` — provided by TPL-03-05.
- `AppTag` — provided by IMP-05.

## View spec

- New middle case between built-in and Custom: `state.selectedCustomTemplate case final custom?` → `icon: custom.icon.iconData`, `label: custom.name`, same `color`, `onTap` and `semanticLabel: l10n.setupTemplateLabel(custom.name)`. Built-in and Custom cases are unchanged. A long name follows the existing `AppTag` ellipsis.
- No new strings, both themes.

## Out of scope

- Any change to `AppTag`, the list or the form.

## Files and tests

- Golden scenario `setup own template selected` (`setup_own_template_selected`), built like the `setup_template_selected` scenario, with `configureFakeDependencies(settings: <Tabata settings>, selectedTemplateId: 'custom-1', customTemplates: [CustomTemplate(id: 'custom-1', name: 'Tabata', icon: CustomTemplateIcon.timer, settings: 0:10 / 0:20 / 0:10 / 8 rounds)])`. Add its row to `test/snapshots/README.md` under Timer Setup.
- Widget: one case in `templates_page_test.dart` (reason: the tag's screen reader label is not visible in a golden). Copy the structure of `localized shortcut navigates in $locale, dark: $dark` as IMP-05 leaves it (it builds `HomePage`, finds the tag with `find.byType(AppTag)` and its label with `find.bySemanticsLabel`), with the own template stored in the registered `FakeCustomTemplateRepository` before the page is built.

## Acceptance

- [ ] Given the own template "Tabata" is selected, when Timer Setup shows, then the tag has the timer icon and "Tabata", in both themes. Check: `test/snapshots/goldens/setup_own_template_selected.png`.
- [ ] Given the own template "Tabata" is selected, when the tag is read by a screen reader, then its label is "Template: Tabata" and tapping it opens Templates. Check: `test/features/templates/presentation/templates_page_test.dart` "own template tag is labelled and opens Templates".
- [ ] When the checks run, then everything passes and the existing setup goldens are unchanged. Check: `fvm dart tool/agent_check.dart --skip-build`.
