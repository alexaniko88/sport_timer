---
id: IMP-05
status: ready
type: improve
complexity: 6
depends-on: [IMP-04]
touches:
  - lib/shared/presentation/widgets/app_tag.dart
  - lib/features/templates/presentation/extensions/template_icon_extension.dart
  - lib/features/templates/presentation/templates_page.dart
  - lib/features/settings/presentation/timer_setup_page.dart
  - test/shared/presentation/widgets/app_tag_test.dart
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/README.md
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

Add a small shared `AppTag` widget (a bordered label with a leading icon and one line of text) and use it on `TimerSetupPage` instead of today's `"Template: Hyrox"` shortcut. The tag always shows which template the setup uses (its icon and name, or `Custom`), and tapping it opens Templates.

## Context

- Current behavior, in `lib/features/settings/presentation/timer_setup_page.dart`: when `state.selectedTemplateId` is not null, the first children of the `ListView` above `TimerSettingGrid` are an `Align(centerLeft)` with a `Semantics(button: true)` around an `AppSurface(onTap: onTemplatesPressed, padding: 16)` that holds `Text(l10n.setupTemplateLabel(l10n.templateName(id)))` in `labelLarge` primary (`"Template: Hyrox"` / `"Plantilla: Hyrox"`), then `Gap(AppSpacing.s8)`. With custom settings nothing is shown. The shortcut has no icon and looks like a tile, not a tag.
- Desired change and benefit: one reusable tag for template indicators, so the setup page always says what it runs, and the later statistics redesign, Rethink statistics cards and details ([UI-05-02](../../epic-ui-refactor/stories/story-05-statistics-ui-refactor/task-02-rethink-statistics-cards-and-details/index.md)), can reuse it.
- Template icons today are a local `switch` inside the `Builder` of `lib/features/templates/presentation/templates_page.dart`: `standard` → `Icons.assignment`, `fullAbs` → `Icons.sports_gymnastics`, `hyrox` → `Icons.directions_run`, `stretching` → `Icons.self_improvement`, `strength` → `Icons.fitness_center`. The Custom tile there uses `Icons.tune` and `l10n.templateCustomName`. `TemplateId` is in `lib/features/templates/domain/workout_template.dart`.
- Names: `l10n.templateName(id)` from `lib/features/templates/presentation/extensions/template_names_extension.dart`. `TimerSetupPage` already imports it, so settings presentation already uses templates presentation.
- Loading check to copy: `TemplatesPage` treats `SettingsStatus.initial` and `SettingsStatus.loading` as loading (`isLoading`), so it never shows `Custom` before the saved selection arrives.
- Editing any setting already clears `selectedTemplateId` (settings view model, unchanged and tested in `test/features/settings/presentation/settings_view_model_test.dart`). The tag reads `selectedTemplateId`, so it switches to `Custom` at once.
- Tokens: `AppRadius.r8`, `AppBorderWidth.thin`, `AppSpacing.s8` in `lib/shared/presentation/theme/app_spacing.dart`. `AppSurface`'s default fill is `colorScheme.surfaceContainer`. Shared widgets live in `lib/shared/presentation/widgets/` next to `app_surface.dart` and `app_button.dart`; the new test copies the setup of `test/shared/presentation/widgets/app_button_test.dart`.
- Runs after Align timer setup summary and Start styling ([IMP-04](../done/task-04-align-timer-setup-summary-and-start/index.md), done), which restyled `_SessionOverview` in the same file. This task does not change `_SessionOverview`.
- Goldens: [setup_custom.png](../../../../test/snapshots/goldens/setup_custom.png) and [setup_template_selected.png](../../../../test/snapshots/goldens/setup_template_selected.png). `setup_time_picker.png` and `setup_rounds_picker.png` show `TimerSetupPage` under a picker sheet, and `home_drawer.png`, `account_sheet.png` and `account_sign_out_dialog.png` show it behind a scrim, so the tag shows there too. `templates_custom.png` and `templates_selected.png` must not change. Flow index: [test/snapshots/README.md](../../../../test/snapshots/README.md).
- Tests in `test/features/templates/presentation/templates_page_test.dart` look for the old `"Template: ..."` text: `localized shortcut navigates in $locale, dark: $dark` (the `textContaining('Template:')` / `findsNothing` check for Custom, the `find.text(label)` shortcut with `getSemantics`, and the final `Template: Hyrox` check), `selected setup scrolls at compact size with text scale $scale` (`Template: Default`) and `reopening Templates preserves selected template and settings` (two `Template: Hyrox` checks). The file's fake settings repository has `Completer<void>? readGate`, which holds the settings load.

## Contract

- `AppTag` in `lib/shared/presentation/widgets/app_tag.dart` — new here. `StatelessWidget` with fields `final IconData icon;`, `final String label;`, `final Color? color;`, `final VoidCallback? onTap;`, `final String? semanticLabel;` and a `const` constructor (`required this.icon`, `required this.label`, `this.color`, `this.onTap`, `this.semanticLabel`). Private constants `static const double _verticalPadding = 4;` and `static const double _iconSize = 16;`. It never stretches: the caller places it. Consumers: `TimerSetupPage` (here) and UI-05-02 (session rows, without `onTap` and without `color`).
- `TemplateIcon` in `lib/features/templates/presentation/extensions/template_icon_extension.dart` — new here. `extension TemplateIcon on TemplateId { IconData get icon => switch (this) { ... }; }` with the five mappings in Context, one case per value. Consumers: `TemplatesPage`, `TimerSetupPage` (here) and UI-05-02.

## View spec

- **`AppTag`, visible box:** a `DecoratedBox` (or a `Container` with only a decoration) with `BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.r8), border: Border.all(color: colorScheme.outlineVariant, width: AppBorderWidth.thin))` and padding `EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: _verticalPadding)`. When `color` is null the box has no fill (do not write `Colors.transparent`), so it shows whatever it sits on.
- **`AppTag`, content:** `Row(mainAxisSize: MainAxisSize.min)` with `Icon(icon, size: _iconSize, color: colorScheme.primary)`, `Gap(AppSpacing.s8)` and `Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface)))`. The colors never change with the template.
- **`AppTag` without `onTap`:** the visible box as it is (no ink, no button semantics, no minimum height), so its text reads as plain text. When `semanticLabel` is given, wrap it in `Semantics(label: semanticLabel, excludeSemantics: true)`.
- **`AppTag` with `onTap`:** `Semantics(button: true, label: semanticLabel ?? label, onTap: onTap, excludeSemantics: true)` → `ConstrainedBox(constraints: const BoxConstraints(minHeight: kMinInteractiveDimension))` → `Material(type: MaterialType.transparency)` → `InkWell(borderRadius: BorderRadius.circular(AppRadius.r8), onTap: onTap)` → `Center(widthFactor: 1, child: <visible box>)`. The border stays compact while the tap area is at least 48 dp high.
- **Timer Setup place:** replace the old `Align` + `Semantics` + `AppSurface` + `Text(l10n.setupTemplateLabel(...))` block. Once settings have loaded, the first children of the `ListView` are `Align(alignment: Alignment.centerLeft, child: AppTag(...))` and `Gap(AppSpacing.s8)`, above `TimerSettingGrid`. `_SessionOverview` stays fixed at the bottom.
- **Timer Setup states:**
  - Loading settings (`SettingsStatus.initial` or `loading`): no tag.
  - Built-in template (`state.selectedTemplateId case final id?`): `icon: id.icon`, `label: l10n.templateName(id)` (for example `Hyrox`, no `Template:` prefix).
  - Custom (`selectedTemplateId == null`): `icon: Icons.tune`, `label: l10n.templateCustomName` (`Custom` / `Personalizado`).
  - In both: `color: colorScheme.surfaceContainer`, `onTap: onTemplatesPressed`, `semanticLabel: l10n.setupTemplateLabel(label)`.
  - Long text (Spanish `Abdominales completos`, 1.5x text, 320 × 568): the tag grows with the text and shrinks to the available width; the label stays on one line with an ellipsis.
- **Themes:** light and dark from `SportTheme`. Border `outlineVariant`, icon `primary`, text `onSurface`. No phase or template colors.
- **Strings:** none new. Reuses `templateName(id)`, `templateCustomName` and `setupTemplateLabel`; `setupTemplateLabel` is now only used for semantics.
- **Accessibility:** one button node labelled `setupTemplateLabel(<name>)` (`"Template: Hyrox"`, `"Plantilla: Personalizado"`) with a tap action; the icon is not read separately.
- **Navigation:** tapping the tag calls `onTemplatesPressed`, which pushes `/templates` (unchanged). Back returns to Timer Setup, and the tag shows the new selection.

## Mockup

[mockup.html](mockup.html), approved by the user: the tag on Timer Setup for a built-in template and for Custom, in light and dark, English and Spanish, and at 320 × 568 with 1.5x text. The same tag without a tap action appears in the statistics day of the [statistics redesign mockup](../../epic-ui-refactor/stories/story-05-statistics-ui-refactor/mockup.html); that use belongs to UI-05-02.

## Decisions

- **A separate shared widget, in its own task:** the user wants one reusable tag for template indicators, delivered before the statistics redesign uses it.
- **Same look everywhere:** one border color (`outlineVariant`, as the template tiles use) and the same colors for every template. The user rejected per-template colors.
- **Fill is set by the caller:** on Timer Setup the tag uses `colorScheme.surfaceContainer`, because a transparent tag looked empty on the page background. With no `color` it has no fill, so inside a card it takes the card's color.
- **Always visible on Timer Setup, including Custom:** the setup page always says what it runs, and the layout height stays the same.
- **Icon and name only on screen, no `Template:` prefix:** decided by the user. The prefix stays in the screen reader label.
- **Tap opens Templates for built-in and Custom:** decided by the user, as today's shortcut.
- **One source for template icons:** `TemplatesPage` drops its local `switch` and uses `template.id.icon`. Keep its `Builder` with `key: ValueKey(template.id)`, because tests find rows by that key.

## Out of scope

- Using `AppTag` anywhere else (the statistics use is in UI-05-02).
- Changing `TimerSettingGrid`, `TimerSettingCard`, `_SessionOverview`, `TemplateTile`, or how templates are selected and saved.
- New strings or ARB changes.

## Files and tests

- New: `lib/shared/presentation/widgets/app_tag.dart`, `lib/features/templates/presentation/extensions/template_icon_extension.dart`, `test/shared/presentation/widgets/app_tag_test.dart` (component test of `AppTag` in light and dark; it needs widget tests for the tap, semantics and tap-size checks, which goldens cannot see).
- `test/features/templates/presentation/templates_page_test.dart` (widget tests, existing): move every check listed in Context to the tag. Find it with `find.byType(AppTag)`, its text with `find.descendant(of: find.byType(AppTag), matching: find.text(name))`, its icon with `find.byIcon(...)`, and its screen reader label with `find.bySemanticsLabel(l10n.setupTemplateLabel(name))` plus `getSemantics` (button with a tap action). Tap it through `find.byType(AppTag)`. In `localized shortcut navigates in $locale, dark: $dark`, replace the `findsNothing` Custom check: the Custom tag shows and opens Templates, then Full Abs and Hyrox show their names and icons. Add the loading test and the Spanish compact test named in Acceptance.
- Goldens: refresh the seven setup goldens in `touches` with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`. No harness change.
- `test/snapshots/README.md`: update the two setup rows (Custom now shows the `Custom` tag that opens Templates; the selected row shows the `Hyrox` tag instead of `"Template: Hyrox"`) and the flow tree line `Tap "Template: <name>" chip` (now `Tap the template tag (<name> or Custom)`).

## Acceptance

- [ ] When `AppTag` is shown without `color` in light or dark theme, then it is a box with no fill, an `AppRadius.r8` radius, an `AppBorderWidth.thin` `outlineVariant` border and `EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 4)` padding. Check: `test/shared/presentation/widgets/app_tag_test.dart` "draws an unfilled bordered box without color".
- [ ] When `AppTag` is given a `color`, then the box is filled with it. Check: `test/shared/presentation/widgets/app_tag_test.dart` "fills the box with the given color".
- [ ] When `AppTag` is shown, then it holds a 16 px `primary` icon, `Gap(AppSpacing.s8)` and a `labelMedium` label in `onSurface` with `maxLines: 1` and an ellipsis. Check: `test/shared/presentation/widgets/app_tag_test.dart` "shows a primary icon and a one-line label".
- [ ] When `AppTag` has no `onTap`, then there is no `InkWell` and no button flag, and a given `semanticLabel` replaces the text for screen readers. Check: `test/shared/presentation/widgets/app_tag_test.dart` "without onTap is plain text with an optional semantic label".
- [ ] When `AppTag` has `onTap`, then it is one button node labelled `semanticLabel ?? label` and tapping it calls `onTap`. Check: `test/shared/presentation/widgets/app_tag_test.dart` "with onTap is one button that calls onTap".
- [ ] When `AppTag` has `onTap`, then its tap area is at least 48 dp high (`tester.getSize`) and `meetsGuideline(androidTapTargetGuideline)` passes. Check: `test/shared/presentation/widgets/app_tag_test.dart` "with onTap has a 48 dp tap area".
- [ ] When the label is longer than a narrow parent, then it ends with an ellipsis on one line and no exception is thrown. Check: `test/shared/presentation/widgets/app_tag_test.dart` "ellipsizes a long label in a narrow parent".
- [ ] When `TemplatesPage` builds its tiles, then the five built-in icons are unchanged. Check: `test/features/templates/presentation/templates_page_test.dart` "shows Custom first followed by the five templates in order".
- [ ] When the Templates snapshots are captured, then they do not change. Check: `test/snapshots/goldens/templates_custom.png`.
- [ ] Given loaded custom settings, when Timer Setup shows in English or Spanish, light or dark, then an `AppTag` with `Icons.tune` and `Custom` / `Personalizado` is left-aligned above the grid, reads `"Template: Custom"` / `"Plantilla: Personalizado"` as a button, and tapping it opens `TemplatesPage`. Check: `test/features/templates/presentation/templates_page_test.dart` "localized shortcut navigates in $locale, dark: $dark".
- [ ] Given a built-in template is selected (Full Abs, then Hyrox), when the user returns to Timer Setup, then the tag shows that template's `TemplateId.icon` and `l10n.templateName(id)` with no `Template:` prefix, reads `l10n.setupTemplateLabel(name)` as a button, and tapping it opens `TemplatesPage`, in English and Spanish, light and dark. Check: `test/features/templates/presentation/templates_page_test.dart` "localized shortcut navigates in $locale, dark: $dark".
- [ ] When settings are still loading (`SettingsStatus.initial` or `loading`, held with `readGate`), then no `AppTag` is shown, and it appears once the load completes. Check: `test/features/templates/presentation/templates_page_test.dart` "Timer Setup shows no template tag while settings load".
- [ ] When Timer Setup shows `Default` at 320 × 568 in English with text scale 1.0 or 1.5, then the tag shows, nothing overflows and the grid scrolls to `Rounds`. Check: `test/features/templates/presentation/templates_page_test.dart` "selected setup scrolls at compact size with text scale $scale".
- [ ] When Timer Setup shows at 320 × 568 in Spanish with `TextScaler.linear(1.5)`, once with Full Abs stored (`Abdominales completos`) and once with no stored template (`Personalizado`), then the tag shows, nothing overflows and the grid scrolls to `Rondas`. Check: `test/features/templates/presentation/templates_page_test.dart` "Spanish compact setup shows the $tag tag at text scale 1.5".
- [ ] When the user picks Hyrox, goes back, then reopens and leaves Templates without choosing, then the tag still shows `Hyrox`. Check: `test/features/templates/presentation/templates_page_test.dart` "reopening Templates preserves selected template and settings".
- [ ] When Timer Setup is captured with custom settings, then the `Custom` tag shows above the grid. Check: `test/snapshots/goldens/setup_custom.png`.
- [ ] When Timer Setup is captured with Hyrox selected, then the `Hyrox` tag replaces the old shortcut. Check: `test/snapshots/goldens/setup_template_selected.png`.
- [ ] When the time picker opens over Timer Setup, then the tag shows behind it. Check: `test/snapshots/goldens/setup_time_picker.png`.
- [ ] When the rounds picker opens over Timer Setup, then the tag shows behind it. Check: `test/snapshots/goldens/setup_rounds_picker.png`.
- [ ] When the drawer opens over Timer Setup, then the tag shows behind the scrim. Check: `test/snapshots/goldens/home_drawer.png`.
- [ ] When the account sheet opens over Timer Setup, then the tag shows behind it. Check: `test/snapshots/goldens/account_sheet.png`.
- [ ] When the sign-out dialog opens over Timer Setup, then the tag shows behind it. Check: `test/snapshots/goldens/account_sign_out_dialog.png`.
- [ ] When the change is checked, then format, analyze, the mirrored tests, the boundary test and the snapshots pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
