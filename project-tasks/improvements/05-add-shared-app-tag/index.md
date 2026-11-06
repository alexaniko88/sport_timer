---
id: IMP-05
status: ready
type: improve
complexity: medium
depends-on: [IMP-04]
touches:
  - lib/shared/presentation/widgets/app_tag.dart
  - lib/features/templates/presentation/extensions/template_icon_extension.dart
  - lib/features/templates/presentation/templates_page.dart
  - lib/features/settings/presentation/timer_setup_page.dart
  - test/shared/presentation/widgets/app_tag_test.dart
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/goldens/setup_custom.png
  - test/snapshots/goldens/setup_template_selected.png
  - test/snapshots/goldens/setup_time_picker.png
  - test/snapshots/goldens/setup_rounds_picker.png
  - test/snapshots/goldens/home_drawer.png
  - test/snapshots/goldens/account_sheet.png
  - test/snapshots/goldens/account_sign_out_dialog.png
skills: []
---

# Add a shared AppTag widget and use it on Timer Setup

Improvements: [Improvements](../index.md)

## Goal

Add a small shared `AppTag` widget (a bordered label with a leading icon and one line of text) and use it on `TimerSetupPage` instead of the current `"Template: Hyrox"` shortcut. The tag always shows which template the setup uses, with its icon and name, or `Custom` when no built-in template matches, and tapping it opens Templates. The statistics redesign [UI-05-01](../../ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/index.md) reuses the same widget without a tap action.

## Context

- Improvements index: [Improvements](../index.md). Follow-up user: [UI-05-01](../../ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/index.md), which depends on this task.
- Runs after [IMP-04](../04-align-timer-setup-summary-and-start/index.md), which restyles `_SessionOverview` in the same file and refreshes the same goldens. Work on top of its result; this task does not change `_SessionOverview`.
- Current behavior, in `lib/features/settings/presentation/timer_setup_page.dart`: when `state.selectedTemplateId` is not null, the `ListView` above `TimerSettingGrid` shows an `Align(centerLeft)` with a `Semantics(button: true)` wrapping an `AppSurface(onTap: onTemplatesPressed, padding: 16)` that holds `Text(l10n.setupTemplateLabel(l10n.templateName(id)))` in `labelLarge` primary (`"Template: Hyrox"` / `"Plantilla: Hyrox"`), followed by `Gap(AppSpacing.s8)`. With custom settings nothing is shown. The shortcut has no icon and looks like a tile, not a tag.
- Template icons today are a local `switch` inside `lib/features/templates/presentation/templates_page.dart` (`standard` → `Icons.assignment`, `fullAbs` → `Icons.sports_gymnastics`, `hyrox` → `Icons.directions_run`, `stretching` → `Icons.self_improvement`, `strength` → `Icons.fitness_center`). The Custom tile there uses `Icons.tune` and `l10n.templateCustomName`.
- Names: `l10n.templateName(id)` from `lib/features/templates/presentation/extensions/template_names_extension.dart`. `TimerSetupPage` already imports it, so settings presentation already uses templates presentation.
- Tokens: `AppRadius.r8`, `AppBorderWidth.thin`, `AppSpacing.s8` in `lib/shared/presentation/theme/app_spacing.dart`. Shared widgets live in `lib/shared/presentation/widgets/` next to `app_surface.dart` and `app_button.dart`.
- Loading check to copy: `TemplatesPage` treats `SettingsStatus.initial` and `SettingsStatus.loading` as loading (`isLoading`) so it never shows `Custom` before the saved selection arrives.
- Goldens: [setup_custom.png](../../../test/snapshots/goldens/setup_custom.png), [setup_template_selected.png](../../../test/snapshots/goldens/setup_template_selected.png). `setup_time_picker.png` and `setup_rounds_picker.png` show `TimerSetupPage` under a picker sheet, and `home_drawer.png`, `account_sheet.png` and `account_sign_out_dialog.png` show it behind a scrim, so the tag shows there too. Flow index: [test/snapshots/README.md](../../../test/snapshots/README.md).
- Existing setup tests in `test/features/templates/presentation/templates_page_test.dart` look for the old `"Template: ..."` text and must move to the new tag. Search the file for `Template:` and `Plantilla:`; today they are in `localized shortcut navigates in $locale, dark: $dark` (the `textContaining('Template:')` / `findsNothing` check for Custom, the `find.text(label)` shortcut with `getSemantics`, and the final `Template: Hyrox` check), `selected setup scrolls at compact size with text scale $scale` (`Template: Default`), and `reopening Templates preserves selected template and settings` (two `Template: Hyrox` checks). The file's fake settings repository has `Completer<void>? readGate`, which holds the settings load; use it for the loading test.
- Runner order: this task starts only after IMP-04 is done (the dispatcher enforces `depends-on`).

## Behavior

- **`AppTag`** (`lib/shared/presentation/widgets/app_tag.dart`), a `StatelessWidget` with fields `final IconData icon;`, `final String label;`, `final Color? color;`, `final VoidCallback? onTap;`, `final String? semanticLabel;` and a `const` constructor (`required this.icon`, `required this.label`, `this.color`, `this.onTap`, `this.semanticLabel`).
  - The visible tag is a `DecoratedBox` (or `Container` with only a decoration) with `BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.r8), border: Border.all(color: colorScheme.outlineVariant, width: AppBorderWidth.thin))`, with padding `EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: _verticalPadding)`, where `static const double _verticalPadding = 4;` is a private constant in `AppTag`. The caller sets the fill with `color`. When `color` is null the box has no fill, so the tag shows the color of whatever it sits on. Do not write `Colors.transparent`.
  - Content: `Row(mainAxisSize: MainAxisSize.min)` with `Icon(icon, size: _iconSize, color: colorScheme.primary)` (`static const double _iconSize = 16;`), `Gap(AppSpacing.s8)`, and `Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface)))`.
  - The colors are always the same. They do not change with the template.
  - Without `onTap`: return the visible tag as it is (no ink, no button semantics, no minimum height), so its text is read as plain text. When `semanticLabel` is given, wrap it in `Semantics(label: semanticLabel, excludeSemantics: true)`.
  - `AppTag` never stretches: the caller places it (Timer Setup uses `Align(alignment: Alignment.centerLeft)`).
  - With `onTap`: wrap the visible tag as `Semantics(button: true, label: semanticLabel ?? label, onTap: onTap, excludeSemantics: true)` → `ConstrainedBox(constraints: const BoxConstraints(minHeight: kMinInteractiveDimension))` → `Material(type: MaterialType.transparency)` → `InkWell(borderRadius: BorderRadius.circular(AppRadius.r8), onTap: onTap)` → `Center(widthFactor: 1, child: <visible tag>)`. The visible border stays compact while the tap area is at least 48 dp high (`kMinInteractiveDimension`).
- **`TemplateIcon` extension** (`lib/features/templates/presentation/extensions/template_icon_extension.dart`): `extension TemplateIcon on TemplateId { IconData get icon => switch (this) { ... }; }` with the five mappings listed in Context, one case per enum value. In `TemplatesPage`, delete the local `final icon = switch (...)` and pass `icon: template.id.icon` to `TemplateTile`. Keep the `Builder` and its `key: ValueKey(template.id)`, because tests find rows by that key. There is then one source for template icons.
- **`TimerSetupPage`**: replace the old `Align` + `Semantics` + `AppSurface` + `Text(l10n.setupTemplateLabel(...))` block with:
  - While `state.status` is `SettingsStatus.initial` or `SettingsStatus.loading`, show no tag (as `TemplatesPage` does).
  - Otherwise always show `Align(alignment: Alignment.centerLeft, child: AppTag(...))` followed by `Gap(AppSpacing.s8)`, above `TimerSettingGrid`:
    - Built-in template (`state.selectedTemplateId case final id?`): `icon: id.icon`, `label: l10n.templateName(id)` (for example `Hyrox`, without the `Template:` prefix).
    - Custom (`selectedTemplateId == null`): `icon: Icons.tune`, `label: l10n.templateCustomName` (`Custom` / `Personalizado`).
    - `color: colorScheme.surfaceContainer` in both cases, the same fill as the template tiles (`AppSurface`'s default fill).
    - `onTap: onTemplatesPressed` in both cases, so tapping opens `/templates`.
    - `semanticLabel: l10n.setupTemplateLabel(label)`, so a screen reader still says `"Template: Hyrox"` / `"Plantilla: Hyrox"` or `"Template: Custom"` / `"Plantilla: Personalizado"`. Keep the `setupTemplateLabel` key; it is now only used for semantics.
- Editing any setting still clears the selected template (unchanged view model behavior), and the tag then switches to `Custom` at once.

## View spec

- **Place:** `TimerSetupPage`, first child of the scrolling `ListView`, left-aligned above `TimerSettingGrid`, with `Gap(AppSpacing.s8)` below. `_SessionOverview` stays fixed at the bottom (as IMP-04 leaves it).
- **States:**
  - Loading settings (`initial` / `loading`): no tag.
  - Built-in template selected, for example Hyrox: tag with `Icons.directions_run` and `Hyrox`.
  - Custom settings: tag with `Icons.tune` and `Custom` / `Personalizado`.
  - Long text (Spanish `Abdominales completos`, 1.5x text scale, 320 × 568): the tag grows with the text and shrinks to the available width; the label stays on one line with an ellipsis, with no overflow.
- **Themes:** light and dark from `SportTheme`. Border `colorScheme.outlineVariant`, fill `colorScheme.surfaceContainer` on Timer Setup (transparent when a caller gives no `color`), icon `colorScheme.primary`, text `colorScheme.onSurface`. No phase or template colors.
- **Strings:** no new strings. Reuses `templateName(id)`, `templateCustomName` and `setupTemplateLabel` in English and Spanish.
- **Accessibility:** one button node with label `setupTemplateLabel(<name>)` and a tap action; the tap area is at least 48 dp high; the icon is not read separately.
- **Navigation:** tapping the tag calls `onTemplatesPressed`, which pushes `/templates` (unchanged). Back returns to Timer Setup, and the tag shows the new selection.

## Mockup

[mockup.html](mockup.html), approved by the user. It shows the tag on Timer Setup for a built-in template and for Custom, in light and dark, English and Spanish, and at 320 × 568 with 1.5x text. The same tag, without a tap action, is shown inside the statistics day details in the [UI-05-01 mockup](../../ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/mockup.html).

## Decisions

- **A separate shared widget, in its own task:** the user wants one reusable tag for template indicators across the app, delivered before the statistics redesign uses it, so the statistics task stays focused.
- **Same look everywhere:** one border color (`outlineVariant`, as the template tiles use) and the same colors for every template. The user rejected per-template colors.
- **Fill is set by the caller:** on Timer Setup the tag uses the template tiles' fill (`colorScheme.surfaceContainer`), because on the plain page background a transparent tag looked empty. When no `color` is given it is transparent, so inside a card (statistics) it takes the card's color.
- **Always visible on Timer Setup, including Custom:** the user wants the setup page to always say what it is running, and showing `Custom` keeps the layout height the same.
- **Icon and name only, no `Template:` prefix on screen:** decided by the user. The prefix stays in the screen reader label, so the purpose of the button is still clear.
- **Tap opens Templates for both built-in and Custom:** decided by the user; same behavior as today's shortcut.
- **Runs after IMP-04:** both tasks change `timer_setup_page.dart` and the same goldens, so this one goes second to avoid conflicting golden updates.

## Out of scope

- Using `AppTag` anywhere else (the statistics use is in UI-05-01).
- Changing `TimerSettingGrid`, `TimerSettingCard`, `_SessionOverview`, `TemplateTile` or how templates are selected and saved.
- New strings or ARB changes.

## Files and tests

Created:

- `lib/shared/presentation/widgets/app_tag.dart`: `AppTag` as described.
- `lib/features/templates/presentation/extensions/template_icon_extension.dart`: `TemplateIcon` extension.
- `test/shared/presentation/widgets/app_tag_test.dart`, copying the setup of `test/shared/presentation/widgets/app_button_test.dart`: in light and dark, check the decoration (radius `AppRadius.r8`, border width `AppBorderWidth.thin`, border color `outlineVariant`, transparent fill without `color`, and the given fill with `color`), icon size 16 and color `primary`, text style and `maxLines: 1` with ellipsis; without `onTap` there is no `InkWell` and no button flag; with `onTap` the node is a button with `semanticLabel ?? label`, a tap calls `onTap`, the height is at least 48 (`tester.getSize`) and `meetsGuideline(androidTapTargetGuideline)` passes; a long label in a narrow parent ellipsizes with no exception.

Changed:

- `lib/features/templates/presentation/templates_page.dart`: use `template.id.icon`.
- `lib/features/settings/presentation/timer_setup_page.dart`: tag as described; remove the old shortcut block and any import it no longer needs.
- `test/features/templates/presentation/templates_page_test.dart`: update every check listed in Context.
  - Find the tag with `find.byType(AppTag)` and check its visible text with `find.descendant(of: find.byType(AppTag), matching: find.text(name))` and its icon with `find.byIcon(...)`. Check the screen reader label with `find.bySemanticsLabel(l10n.setupTemplateLabel(name))` (for example `'Template: Full Abs'`, `'Plantilla: Personalizado'`) and `getSemantics` on it: it is a button with a tap action. Tap it through `find.byType(AppTag)`.
  - For EN and ES, light and dark: Custom shows `Custom` / `Personalizado` with `Icons.tune` (replacing the old `findsNothing` check), Full Abs and Hyrox show their names and icons, and tapping opens `TemplatesPage` from Custom and from a template.
  - Loading: hold the settings load with `readGate`, pump, check `find.byType(AppTag)` finds nothing, complete the gate, pump and settle, and check the tag shows.
  - Compact size: keep `selected setup scrolls at compact size with text scale $scale` (English, `Default`, 1.0 and 1.5) checking the `Default` tag, and add a Spanish test at 320 × 568 with `TextScaler.linear(1.5)`, run once with Full Abs stored (tag `Abdominales completos`) and once with no stored template (tag `Personalizado`); each run checks the tag, no exception, and that it can scroll to `Rondas`.
- Goldens: refresh `setup_custom.png`, `setup_template_selected.png`, `setup_time_picker.png`, `setup_rounds_picker.png`, `home_drawer.png`, `account_sheet.png` and `account_sign_out_dialog.png` with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`. In `test/snapshots/README.md`, update the two setup rows (Custom now shows the `Custom` tag that opens Templates; the selected row shows the `Hyrox` tag instead of `"Template: Hyrox"`) and the flow tree line `Tap "Template: <name>" chip` (now `Tap the template tag (<name> or Custom)`).

## Acceptance

- [ ] When `AppTag` is rendered in light or dark theme without `onTap`, then it shows a box filled with `color` (no fill when `color` is null) with an `AppRadius.r8`, `AppBorderWidth.thin` `colorScheme.outlineVariant` border and `EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 4)` padding, holding a 16 px `colorScheme.primary` icon, `Gap(AppSpacing.s8)` and a one-line ellipsized `labelMedium` label in `colorScheme.onSurface`, with no `InkWell` and no button semantics. Check: `test/shared/presentation/widgets/app_tag_test.dart`.
- [ ] When `AppTag` is rendered with `onTap`, then it is a single button semantics node labelled `semanticLabel ?? label`, tapping it calls `onTap`, and its tap area is at least 48 dp high and passes `androidTapTargetGuideline`. Check: `test/shared/presentation/widgets/app_tag_test.dart`.
- [ ] When `TemplatesPage` builds its tiles, then each built-in template icon comes from `TemplateId.icon`, and the icons are unchanged. Check: `test/features/templates/presentation/templates_page_test.dart` and `fvm flutter test test/snapshots/ui_snapshots_test.dart` (templates goldens unchanged).
- [ ] When `TimerSetupPage` has loaded settings with a built-in template selected (for example Hyrox), then an `AppTag` with `TemplateId.icon` and `l10n.templateName(id)` (no `Template:` prefix) is shown left-aligned above `TimerSettingGrid` with `color: colorScheme.surfaceContainer`, its semantics label is `l10n.setupTemplateLabel(name)`, and tapping it opens `/templates`, in English and Spanish, light and dark. Check: `test/features/templates/presentation/templates_page_test.dart` and `test/snapshots/goldens/setup_template_selected.png`.
- [ ] When `TimerSetupPage` has loaded custom settings (`selectedTemplateId == null`), then an `AppTag` with `Icons.tune` and `l10n.templateCustomName` (`Custom` / `Personalizado`) is shown in the same place and tapping it opens `/templates`. Check: `test/features/templates/presentation/templates_page_test.dart` and `test/snapshots/goldens/setup_custom.png`.
- [ ] When settings are still loading (`SettingsStatus.initial` or `loading`), then no tag is shown. Check: `test/features/templates/presentation/templates_page_test.dart`.
- [ ] When `TimerSetupPage` is shown at 320 × 568 with `TextScaler.linear(1.5)` in English (`Default`) and Spanish (`Abdominales completos` and `Personalizado`), then the tag and the grid render with no overflow and the grid can still be scrolled to `Rounds` / `Rondas`. Check: `test/features/templates/presentation/templates_page_test.dart`.
- [ ] When the UI snapshot test runs, then the refreshed `setup_custom.png`, `setup_template_selected.png`, `setup_time_picker.png`, `setup_rounds_picker.png`, `home_drawer.png`, `account_sheet.png` and `account_sign_out_dialog.png` match in light and dark. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart`.
- [ ] When the full suite and agent check run, then everything passes. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
