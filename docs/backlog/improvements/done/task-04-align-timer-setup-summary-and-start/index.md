---
id: IMP-04
status: done
type: improve
complexity: 3
depends-on: []
touches:
  - lib/features/settings/presentation/timer_setup_page.dart
  - lib/shared/presentation/widgets/app_button.dart
  - test/features/templates/presentation/templates_page_test.dart
  - test/shared/presentation/widgets/app_button_test.dart
  - test/snapshots/goldens/account_sheet.png
  - test/snapshots/goldens/account_sign_out_dialog.png
  - test/snapshots/goldens/home_drawer.png
  - test/snapshots/goldens/setup_custom.png
  - test/snapshots/goldens/setup_template_selected.png
skills: []
---

# Align timer setup summary and Start styling

Improvements: [Improvements](../../index.md)

## Goal

Align the session length summary row and the `Start` button inside `_SessionOverview` on `TimerSetupPage` with the `TimerSettingCard` grid styling: use `emphasizedLabel` with `onSurfaceVariant` for the session length label, `tileValue` for the session length duration and `Start` button label, `AppSpacing.s40` (`40.0`) for the `Start` play icon, single-line ellipsis on the labels, and `AppSpacing.s8` vertical button padding so the button grows to fit without changing other `AppButton` callers.

## Context

- Improvements index: [Improvements](../../index.md). Related completed tasks: [UI-03-01](../../../epic-ui-refactor/stories/done/story-03-start-button-refactor/done/task-01-refactor-timer-setup-start-button/index.md) (moved `Start` into the fixed `_SessionOverview` surface at the bottom of `TimerSetupPage`) and [IMP-01](../task-01-unify-styles-app-wide/index.md) (introduced `AppSurface` and `AppTextThemeExtension`).
- Current behavior and limitation: in `lib/features/settings/presentation/timer_setup_page.dart`, `_SessionOverview` renders `Text(l10n.setupSessionLength)` and `Text(formattedDuration)` with the default `bodyMedium` text style (14px regular, no `maxLines` or `overflow`), while `AppButton.primary` renders the `Start` label with the default `FilledButton` `labelLarge` text style (14px w500) and a default 18–24px `Icons.play_arrow` icon inside a fixed 48px-minimum button. By contrast, each `TimerSettingCard` in `lib/features/settings/presentation/widgets/timer_setting_card.dart` renders a `40.0` (`AppSpacing.s40`) icon, a single-line `emphasizedLabel` (`titleMedium`, w500) label in `colorScheme.onSurfaceVariant`, and a single-line `tileValue` (`headlineSmall`, w700) value in `colorScheme.onSurface`. As a result, the session summary and `Start` action look visually smaller and less prominent than the setting cards above them.
- Desired change and benefit: match the session length label to the grid card labels (`emphasizedLabel` in `onSurfaceVariant`, single-line with ellipsis), match the session length duration to the grid card values (`tileValue`, single-line with ellipsis), and match the `Start` button to the grid card values and icons (`tileValue` text style, `AppSpacing.s40` icon size, single-line label with ellipsis, and `EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8)` padding in `_SessionOverview`'s local `FilledButtonTheme`), giving `TimerSetupPage` a unified visual hierarchy while keeping `SportTheme.filledButtonTheme` and other `AppButton` uses unchanged.
- Existing code to reuse:
  - `AppTextThemeExtension` (`lib/shared/presentation/extensions/text_theme_extension.dart`): `textTheme.emphasizedLabel` (`titleMedium` with `FontWeight.w500`) and `textTheme.tileValue` (`headlineSmall` with `FontWeight.w700`).
  - `AppSpacing` (`lib/shared/presentation/theme/app_spacing.dart`): `AppSpacing.s8` (`8.0`), `AppSpacing.s16` (`16.0`), `AppSpacing.s24` (`24.0`), and `AppSpacing.s40` (`40.0`).
  - `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`) and `AppButton.primary` (`lib/shared/presentation/widgets/app_button.dart`).
- Goldens: [setup_custom.png](../../../../../test/snapshots/goldens/setup_custom.png), [setup_template_selected.png](../../../../../test/snapshots/goldens/setup_template_selected.png), and the flow catalog in [test/snapshots/README.md](../../../../../test/snapshots/README.md).

## Behavior

- **Session length row in `_SessionOverview` (`lib/features/settings/presentation/timer_setup_page.dart`):**
  - Import `package:sport_timer/shared/presentation/extensions/text_theme_extension.dart`.
  - Read `final theme = Theme.of(context);`, `final textTheme = theme.textTheme;`, and `final colorScheme = theme.colorScheme;`.
  - Render the session length label inside `Expanded` as:
    ```dart
    Expanded(
      child: Text(
        l10n.setupSessionLength,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.emphasizedLabel.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    ```
  - Keep `const SizedBox(width: AppSpacing.s8)` between the label and duration.
  - Render the formatted duration (`formattedDuration`, `MM:SS` when `< 1` hour or `H:MM:SS` when `>= 1` hour) as:
    ```dart
    Text(
      formattedDuration,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.tileValue,
    ),
    ```
- **`Start` button theme in `_SessionOverview` (`lib/features/settings/presentation/timer_setup_page.dart`):**
  - Keep `ExcludeFocus` and `IgnorePointer` wrapping the `FilledButtonTheme` inside the `ExcludeSemantics` `Column`, because the outer `Semantics` + `AppSurface(onTap: onStartPressed, excludeFromSemantics: true)` owns pointer, focus, and semantics activation for the whole summary card.
  - Update the local `FilledButtonThemeData` so it preserves the `SportTheme.filledButtonTheme` shape (`AppRadius.r12`) and sets `minimumSize`, `padding`, `textStyle`, and `iconSize`:
    ```dart
    FilledButtonTheme(
      // A local button theme replaces the app one, so keep its shape and only change the size, padding, text, and icon.
      data: FilledButtonThemeData(
        style: (theme.filledButtonTheme.style ?? FilledButton.styleFrom()).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.s24,
              vertical: AppSpacing.s8,
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.tileValue),
          iconSize: const WidgetStatePropertyAll(AppSpacing.s40),
        ),
      ),
      child: AppButton.primary(
        label: l10n.homeStartButton,
        icon: const Icon(Icons.play_arrow),
        onPressed: onStartPressed,
        isExpanded: true,
      ),
    ),
    ```
- **Single-line ellipsis on `AppButton` labels (`lib/shared/presentation/widgets/app_button.dart`):**
  - In `_AppButtonContent.build`, configure the `Text(label)` widget with `maxLines: 1` and `overflow: TextOverflow.ellipsis` in both the icon and non-icon branches:
    ```dart
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: AppSpacing.s8),
        Flexible(child: text),
      ],
    );
    ```
  - Do not change `AppButton`'s constructor parameters, default button height (`40` dp when no local `FilledButtonTheme` overrides it), or `SportTheme.filledButtonTheme`.
- **Preserved behavior:**
  - Total duration calculation (`TimerSchedule.fromParams(...).totalDuration`) and formatting (`$hours:$minutes:$seconds` when `hours > 0`, otherwise `$minutes:$seconds`) remain unchanged.
  - Tapping anywhere on `_SessionOverview` (either the session length row or the `Start` button) or activating its single merged semantics node (`button: true`, `label: l10n.homeStartButton`, `value: '${l10n.setupSessionLength}: $formattedDuration'`) triggers `onStartPressed`.

## View spec

- **Place and layout:** `_SessionOverview` at the bottom of `TimerSetupPage` (`Scaffold.body` `Column`, below the `Expanded` `ListView` that holds the optional template chip and `TimerSettingGrid`, and above `HomePage`'s `BottomNavigationBar`). Outer `Padding` is `EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16)`. Inside `AppSurface(padding: const EdgeInsets.all(AppSpacing.s16))`, a vertical `Column` contains:
  1. Session length `Row`: `Expanded` label (`emphasizedLabel`, `onSurfaceVariant`, single-line ellipsis) + `SizedBox(width: AppSpacing.s8)` + duration text (`tileValue`, `onSurface`, single-line ellipsis).
  2. `const SizedBox(height: AppSpacing.s8)`.
  3. Expanded `AppButton.primary` (`isExpanded: true`) with `Icons.play_arrow` (`size: AppSpacing.s40` via `FilledButtonTheme`) and `l10n.homeStartButton` (`tileValue` via `FilledButtonTheme`, single-line ellipsis), `minimumSize: Size(0, 48)`, and `padding: EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8)`.
- **States:**
  - Custom settings (`selectedTemplateId == null`, e.g. `05:10` session length): no template chip above the grid; `_SessionOverview` shows `"Session length"` / `"Duración de la sesión"` and `"05:10"`.
  - Built-in template selected (`selectedTemplateId == TemplateId.hyrox`, `47:20` session length): `"Template: Hyrox"` chip shown above the grid; `_SessionOverview` shows `"Session length"` and `"47:20"`.
  - Multi-hour duration (`hours > 0`, e.g. `2:00:31`): duration formats as `H:MM:SS` in `tileValue` on a single line while the `Expanded` label takes the remaining width.
  - Narrow screen and large text (`320 × 568` at `TextScaler.linear(1.5)` in English and Spanish): the session length label truncates to 1 line with ellipsis (`maxLines: 1, overflow: TextOverflow.ellipsis`) so the full duration (`05:10`) stays visible without wrapping or horizontal overflow; the `Start` button grows vertically with `AppSpacing.s8` vertical padding around the `40.0` icon and `1.5x`-scaled `tileValue` label without clipping; the grid switches to 1 column and scrolls independently above `_SessionOverview`.
  - There is no empty, loading, or error state on `TimerSetupPage`: `SettingsState` always provides a valid `TimerSettings` synchronously from initialization.
- **Interaction:** tapping anywhere on the `_SessionOverview` `AppSurface` shows the `InkWell` ripple and invokes `onStartPressed`, which flushes settings if needed and pushes `/timer` with the current `TimerParams`.
- **Navigation:** lives on `HomePage` Tab 0 (`TimerSetupPage`). Activating `_SessionOverview` pushes `RoutePath.timer` (`/timer`) with `extra: TimerParams(...)`.
- **Reuse:** `AppSurface`, `AppButton.primary`, `AppSpacing`, `AppRadius`, and `AppTextThemeExtension` (`emphasizedLabel`, `tileValue`). No new shared tokens or widgets are added.
- **Themes:** light and dark themes from `SportTheme`:
  - `_SessionOverview` card uses `AppSurface` defaults (`colorScheme.surfaceContainer` fill, `AppRadius.r12` radius, `AppBorderWidth.thin` `colorScheme.outlineVariant` border).
  - Session length label uses `colorScheme.onSurfaceVariant`; duration uses `colorScheme.onSurface`.
  - `Start` button uses `FilledButton` defaults (`colorScheme.primary` fill, `colorScheme.onPrimary` icon and label, `AppRadius.r12` shape from `SportTheme.filledButtonTheme`).
- **Texts:** reuses existing localization keys in `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` (no ARB changes needed):
  - `setupSessionLength`: `"Session length"` (EN) / `"Duración de la sesión"` (ES).
  - `homeStartButton`: `"Start"` (EN) / `"Iniciar"` (ES).
- **Accessibility:**
  - `_SessionOverview` exposes a single merged button semantics node (`Semantics(button: true, label: l10n.homeStartButton, value: '${l10n.setupSessionLength}: $formattedDuration', onTap: onStartPressed)`) with inner `AppSurface(excludeFromSemantics: true)` and `ExcludeSemantics` around the `Column`.
  - Even when the visual label truncates with ellipsis at large text scales, the outer `Semantics` node retains the full `l10n.homeStartButton` label and `'${l10n.setupSessionLength}: $formattedDuration'` value.
  - The interactive surface is `254`+ px wide and well above the `48 × 48` minimum tap target in all layouts.
- **Snapshots:**
  - Refresh `test/snapshots/goldens/setup_custom.png`, `test/snapshots/goldens/setup_template_selected.png`, `test/snapshots/goldens/home_drawer.png`, `test/snapshots/goldens/account_sheet.png`, and `test/snapshots/goldens/account_sign_out_dialog.png` (the last three render `HomePage` on Tab 0 behind the drawer or account sheet scrim, where `_SessionOverview` is partially visible) via `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`.
  - `test/snapshots/README.md` needs no flow link or table text changes because the screen states, values, and transitions remain identical.

## Mockup

[mockup.html](mockup.html), approved by the user. It shows `TimerSetupPage` and `_SessionOverview` in `Custom (05:10)`, `Template Hyrox (47:20)`, `Multi-hour (2:00:31)`, and `Narrow + 1.5x Text` states, in Light and Dark themes and in English and Spanish.

## Decisions

- **Use `onSurfaceVariant` for the session length label color:** chosen by the user so the session length label matches the `TimerSettingCard` labels in color (`theme.colorScheme.onSurfaceVariant`) as well as size and weight (`theme.textTheme.emphasizedLabel`).
- **Enforce single-line ellipsis (`maxLines: 1, overflow: TextOverflow.ellipsis`) on the session length label, duration, and `AppButton` label:** chosen by the user so the summary card matches the grid cards, keeps the full duration visible on narrow screens or in Spanish (`"Duración de la sesión"`), and prevents multi-line wrapping from shrinking the scrollable grid viewport.
- **Scope the larger `Start` button typography, icon size, and vertical padding to `_SessionOverview`'s local `FilledButtonTheme`:** chosen by the user because `AppButton.primary` is also used for standard 40dp `"Retry"` buttons on `StatisticPage` and `DayDetailsPage`, which must keep standard button sizing.

## Out of scope

- Changing `TimerSettingCard` or `TimerSettingGrid` layout or styling.
- Changing `SportTheme.filledButtonTheme` or the size/typography of `AppButton` outside `_SessionOverview`.
- Changing session length calculation, duration formatting rules, or timer launch navigation.

## Files and tests

Changed:

- `lib/features/settings/presentation/timer_setup_page.dart`:
  - Import `package:sport_timer/shared/presentation/extensions/text_theme_extension.dart`.
  - In `_SessionOverview.build`, style `Text(l10n.setupSessionLength)` with `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and `style: textTheme.emphasizedLabel.copyWith(color: colorScheme.onSurfaceVariant)`.
  - Style `Text(formattedDuration)` with `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and `style: textTheme.tileValue`.
  - In `_SessionOverview`'s `FilledButtonThemeData`, copy from `theme.filledButtonTheme.style ?? FilledButton.styleFrom()` with `minimumSize: const WidgetStatePropertyAll(Size(0, 48))`, `padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8))`, `textStyle: WidgetStatePropertyAll(textTheme.tileValue)`, and `iconSize: const WidgetStatePropertyAll(AppSpacing.s40)`.
- `lib/shared/presentation/widgets/app_button.dart`:
  - In `_AppButtonContent.build`, add `maxLines: 1` and `overflow: TextOverflow.ellipsis` to `Text(label)`.
- `test/shared/presentation/widgets/app_button_test.dart`:
  - In the `does not overflow with a long label in a narrow expanded button` test (or a companion check in `AppButton`), assert that the `Text` widget inside `AppButton` has `maxLines: 1` and `overflow: TextOverflow.ellipsis`.
- `test/features/templates/presentation/templates_page_test.dart`:
  - In `Setup Start is fixed and accessible in ${locale.languageCode} ${theme.brightness.name}`:
    - Assert that the session length label `Text` widget has `maxLines: 1`, `overflow: TextOverflow.ellipsis`, `style?.fontSize == theme.textTheme.titleMedium?.fontSize`, `style?.fontWeight == FontWeight.w500`, and `style?.color == theme.colorScheme.onSurfaceVariant` (matching `TimerSettingCard` labels).
    - Assert that the session duration `Text('05:10')` widget has `maxLines: 1`, `overflow: TextOverflow.ellipsis`, `style?.fontSize == theme.textTheme.headlineSmall?.fontSize`, and `style?.fontWeight == FontWeight.w700` (matching `TimerSettingCard` values).
    - Assert that `FilledButtonTheme.of(buttonContext).style` resolves `textStyle` with `fontSize == theme.textTheme.headlineSmall?.fontSize` and `fontWeight == FontWeight.w700`, `iconSize == AppSpacing.s40`, `minimumSize == const Size(0, 48)`, and `padding == const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8)`, and that the rendered `Icons.play_arrow` `RichText` / `Icon` inside `button` is `40.0` px (`tester.getSize(find.descendant(of: button, matching: find.byIcon(Icons.play_arrow))) == const Size(40, 40)` at `1.0` scale, or `IconTheme.of(tester.element(find.descendant(of: button, matching: find.byIcon(Icons.play_arrow)))).size == AppSpacing.s40`).
    - When scrolling to the last card (`Rounds` / `Rondas`) on the `320 × 568` screen at `1.5x` text scale, scroll `find.byType(TimerSettingCard).last` into view (e.g. `await tester.ensureVisible(find.byType(TimerSettingCard).last); await tester.pumpAndSettle();` after `scrollUntilVisible`) so the full bottom of the last card is scrolled above `labelRect.top` despite the taller `_SessionOverview` footer.
- `test/snapshots/goldens/setup_custom.png`, `test/snapshots/goldens/setup_template_selected.png`, `test/snapshots/goldens/home_drawer.png`, `test/snapshots/goldens/account_sheet.png`, and `test/snapshots/goldens/account_sign_out_dialog.png`:
  - Refresh the affected golden snapshots via `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`.

## Acceptance

- [x] When `TimerSetupPage` is rendered in light or dark theme, then the session length label (`l10n.setupSessionLength`) uses `theme.textTheme.emphasizedLabel.copyWith(color: theme.colorScheme.onSurfaceVariant)` with `maxLines: 1` and `overflow: TextOverflow.ellipsis`, matching the grid card labels in font size, font weight (`FontWeight.w500`), and color (`colorScheme.onSurfaceVariant`). Check: `test/features/templates/presentation/templates_page_test.dart` and `test/snapshots/goldens/setup_custom.png`.
- [x] When `TimerSetupPage` is rendered in light or dark theme, then the formatted session length duration uses `theme.textTheme.tileValue` with `maxLines: 1` and `overflow: TextOverflow.ellipsis`, matching the grid card values in font size (`headlineSmall`) and font weight (`FontWeight.w700`). Check: `test/features/templates/presentation/templates_page_test.dart` and `test/snapshots/goldens/setup_custom.png`.
- [x] When `TimerSetupPage` is rendered in light or dark theme, then the `Start` button inside `_SessionOverview` uses `theme.textTheme.tileValue` for its label (with `maxLines: 1` and `overflow: TextOverflow.ellipsis`), `AppSpacing.s40` (`40.0`) for its `Icons.play_arrow` icon size, `EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s8)` padding, and `Size(0, 48)` minimum size while preserving `AppRadius.r12` corners from `SportTheme.filledButtonTheme`. Check: `test/features/templates/presentation/templates_page_test.dart` and `test/snapshots/goldens/setup_custom.png`.
- [x] When `AppButton.primary` or `AppButton.secondary` renders elsewhere in the app (without `_SessionOverview`'s local `FilledButtonTheme`), then its label has `maxLines: 1` and `overflow: TextOverflow.ellipsis` and its default button height (`40` dp) and styling remain unchanged. Check: `test/shared/presentation/widgets/app_button_test.dart`.
- [x] When `TimerSetupPage` is rendered on a narrow screen (`320 × 568`) with `TextScaler.linear(1.5)` in English and Spanish (light and dark), or with a long multi-hour duration (`2:00:31`), then the session summary and `Start` button render without overflow or clipping, the session length label truncates to one line with ellipsis when needed while the full duration remains visible, and the settings grid scrolls independently above the fixed summary card. Check: `test/features/templates/presentation/templates_page_test.dart`.
- [x] When the user taps the `Start` button, taps the session summary surface, or activates the single merged semantics button (`label: l10n.homeStartButton`, `value: '${l10n.setupSessionLength}: $formattedDuration'`), then the timer starts with the current `TimerParams`. Check: `test/features/templates/presentation/templates_page_test.dart`.
- [x] When the UI snapshot test runs, then `test/snapshots/goldens/setup_custom.png`, `test/snapshots/goldens/setup_template_selected.png`, `test/snapshots/goldens/home_drawer.png`, `test/snapshots/goldens/account_sheet.png`, and `test/snapshots/goldens/account_sign_out_dialog.png` match in light and dark themes. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart`.
- [x] When the full test suite and agent check run, then all tests and layer boundary checks pass. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
