---
id: IMP-02
status: ready
type: improve
complexity: medium
depends-on: []
touches:
  - lib/features/home/presentation/home_page.dart
  - lib/features/settings/presentation/extensions/timer_style_names_extension.dart
  - lib/features/settings/presentation/timer_styles/timer_styles_page.dart
  - lib/l10n/**
  - test/features/home/**
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/goldens/home_drawer.png
skills: []
---

# Rethink the navigation drawer

Improvements: [Improvements](../index.md)

## Goal

Replace the bare `NavigationDrawer` on `HomePage` with a styled `Drawer` that has a branded header (`Icons.timer_outlined` badge + `Sport Timer` title + `Divider`) and two equal-height `AppSurface` action tiles (`Templates` and `Styles`), each showing its currently active setting as a single-line subtitle with a trailing chevron and no false "selected tab" pill highlight.

## Context

- Improvements index: [Improvements](../index.md). Related completed story: [UI refactor Story 2](../../ui-refactor/stories/02-templates-in-drawer/index.md) (moved `Templates` into the drawer). Related downstream task: [DEV-01-02](../../developer-tools/stories/01-purge-local-activity/02-add-developer-page/index.md) (adds a debug-only `Developer tools` footer tile to this drawer).
- Current behavior and limitation: `lib/features/home/presentation/home_page.dart` builds a Material `NavigationDrawer` with a plain text title and two `NavigationDrawerDestination` rows (`Templates` and `Timer styles`). Because `NavigationDrawer.selectedIndex` defaults to `0`, `Templates` always renders with a selected pill highlight even though the user is on Home (`Timer` or `Statistics`) and both drawer items push separate routes. In addition, the Spanish label `"Estilos del temporizador"` wraps onto two lines, making the two items uneven, and the drawer hides the currently active template and timer style until the user opens each page.
- Desired change and benefit: replace `NavigationDrawer` with a `Drawer` (which keeps the 20px trailing-edge radius from `SportTheme.drawerTheme`) containing a header row (`Icons.timer_outlined` badge + `Sport Timer` title), a `Divider`, and a `ValueListenableBuilder<SettingsState>` over `_viewModel.state` that renders two equal-height `AppSurface` tiles with single-line titles (`"Templates"` / `"Plantillas"`, `"Styles"` / `"Estilos"`), single-line subtitles showing the active template (`"Custom"` or the selected template name) and active timer style (`"Ring"`, `"Full color"`, or `"Rounds strip"`), and a trailing `Icons.chevron_right`.
- Existing code to reuse:
  - `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`), `AppSpacing` and `AppRadius` (`lib/shared/presentation/theme/app_spacing.dart`), and text roles `tileTitle` and `tileSecondary` (`lib/shared/presentation/extensions/text_theme_extension.dart`).
  - `TemplateNames` extension on `AppLocalizations` (`lib/features/templates/presentation/extensions/template_names_extension.dart`) maps `TemplateId` to its localized name (`l10n.templateName(id)`), and `l10n.templateCustomName` provides `"Custom"` / `"Personalizado"`.
  - Add a matching `TimerStyleNames` extension on `AppLocalizations` in `lib/features/settings/presentation/extensions/timer_style_names_extension.dart` (`String timerStyleName(TimerStyle style)`) and reuse it in both `HomePage` and `lib/features/settings/presentation/timer_styles/timer_styles_page.dart`.
- Goldens: [home_drawer.png](../../../test/snapshots/goldens/home_drawer.png) (current drawer snapshot), [setup_custom.png](../../../test/snapshots/goldens/setup_custom.png), [timer_styles.png](../../../test/snapshots/goldens/timer_styles.png), and the flow catalog in [test/snapshots/README.md](../../../test/snapshots/README.md).

## Behavior

- **Drawer container:** in `lib/features/home/presentation/home_page.dart`, replace `NavigationDrawer` with `Drawer(child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...]))))`. `SportTheme.drawerTheme` already sets the `AppRadius.r20` horizontal end border radius and `colorScheme.surfaceContainerLow` background.
- **Header:** a `Padding(padding: EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s20, AppSpacing.s16, AppSpacing.s16))` containing a `Row`:
  - A 40×40 icon badge: `ExcludeSemantics` wrapping a `SizedBox(width: AppSpacing.s40, height: AppSpacing.s40, child: DecoratedBox(decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.r12)), child: Icon(Icons.timer_outlined, color: colorScheme.onPrimaryContainer)))`.
  - `const Gap(AppSpacing.s12)`.
  - `Expanded(child: Text(l10n.appTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)))`.
  - Below the header `Padding`: `const Divider(height: 1, indent: AppSpacing.s16, endIndent: AppSpacing.s16)`.
- **Scrollable destinations list:** an `Expanded` wrapping `ValueListenableBuilder<SettingsState>(valueListenable: _viewModel.state, builder: (context, state, _) { ... })` that returns a `ListView(padding: const EdgeInsets.all(AppSpacing.s16), children: [...])` with two tiles separated by `const Gap(AppSpacing.s12)`:
  1. **Templates tile:**
     - Leading icon: `Icons.assignment_outlined` in `colorScheme.primary`.
     - Title: `l10n.homeDrawerTemplates` (`"Templates"` / `"Plantillas"`).
     - Subtitle: `if (state.selectedTemplateId case final id?) l10n.templateName(id) else l10n.templateCustomName`.
     - On tap: closes the drawer (`_scaffoldKey.currentState?.closeDrawer()`) and calls `context.pushNamed(RoutePath.templates.value, extra: _viewModel)`.
  2. **Styles tile:**
     - Leading icon: `Icons.style_outlined` in `colorScheme.primary`.
     - Title: `l10n.homeDrawerTimerStyles` (`"Styles"` / `"Estilos"`).
     - Subtitle: `l10n.timerStyleName(state.timerStyle)` (`"Ring"` / `"Anillo"`, `"Full color"` / `"Color completo"`, or `"Rounds strip"` / `"Barra de rondas"`).
     - On tap: closes the drawer (`_scaffoldKey.currentState?.closeDrawer()`) and calls `context.pushNamed(RoutePath.timerStyles.value, extra: _viewModel)`.
- **Tile widget structure:** extract a private widget `_DrawerTile` in `home_page.dart` with `{required IconData icon, required String title, required String subtitle, required VoidCallback onTap}`:
  - Wraps `AppSurface(onTap: onTap, child: ...)` in `Semantics(button: true, child: ...)`.
  - Inside `AppSurface` (which uses its default `AppSpacing.s12` padding, `AppRadius.r12` radius, `AppBorderWidth.thin` `outlineVariant` border, and `colorScheme.surfaceContainer` fill): a `Row` with:
    - `Icon(icon, color: colorScheme.primary)`
    - `const Gap(AppSpacing.s12)`
    - `Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.tileTitle), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.tileSecondary.copyWith(color: colorScheme.onSurfaceVariant))]))`
    - `const Gap(AppSpacing.s12)`
    - `Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)`
- **Equal tile height:** because every title and subtitle has `maxLines: 1, overflow: TextOverflow.ellipsis` and both tiles share the exact same `_DrawerTile` layout (`tileTitle` + `tileSecondary`), both tiles always render with the exact same height in English, Spanish, and at `TextScaler.linear(2)`.
- **Live updates:** because the list listens to `_viewModel.state`, selecting a template on `TemplatesPage`, editing a duration on `TimerSetupPage` (which clears `selectedTemplateId` to `null`), or changing the style on `TimerStylesPage` automatically updates the subtitles the next time the drawer is viewed.

## View spec

- **Place and layout:** `HomePage.drawer` (`Drawer` with `SafeArea`). Top header (`Padding` `fromLTRB(s16, s20, s16, s16)`) with 40×40 `primaryContainer` `r12` badge (`Icons.timer_outlined`) + `s12` gap + `Sport Timer` title (`titleLarge`, `w600`, single-line ellipsis), followed by `Divider(height: 1, indent: s16, endIndent: s16)`, followed by an `Expanded` `ListView` (`padding: EdgeInsets.all(s16)`) with two `_DrawerTile`s spaced by `s12`.
- **States:**
  - Custom settings (`selectedTemplateId == null`, default `TimerStyle.ring`): `Templates` subtitle is `"Custom"` (`"Personalizado"`), `Styles` subtitle is `"Ring"` (`"Anillo"`).
  - Built-in template selected (`selectedTemplateId == TemplateId.hyrox`, `TimerStyle.roundsStrip`): `Templates` subtitle is `"Hyrox"`, `Styles` subtitle is `"Rounds strip"` (`"Barra de rondas"`).
  - Long text / `TextScaler.linear(2)`: header title, tile titles, and tile subtitles stay on 1 line (`maxLines: 1, overflow: TextOverflow.ellipsis`), keeping both tiles the exact same height without overflow.
  - There is no empty, loading, or error state: `SettingsState` always holds a valid `TimerSettings` and `TimerStyle` synchronously from initialization.
- **Interaction:** tapping either `AppSurface` tile shows the `InkWell` ripple, closes the drawer, and pushes `/templates` or `/timer-styles` with `extra: _viewModel`. Tapping the scrim or system back closes the drawer.
- **Navigation:** opened from the `Icons.menu` `IconButton` on `TimerSetupPage` (Tab 0) or `StatisticPage` (Tab 1). Pushing `/templates` or `/timer-styles` and pressing Back returns to the active Home tab with the drawer closed.
- **Reuse:** `AppSurface`, `AppSpacing`, `AppRadius`, `tileTitle`, `tileSecondary`, `TemplateNames`, and the new `TimerStyleNames` extension (`lib/features/settings/presentation/extensions/timer_style_names_extension.dart`, used in `HomePage` and `TimerStylesPage`).
- **Themes:** light and dark come from `SportTheme` (`surfaceContainerLow` drawer background, `primaryContainer` / `onPrimaryContainer` header badge, `surfaceContainer` tile fill, `outlineVariant` tile border and divider, `primary` leading icons, `onSurface` titles, `onSurfaceVariant` subtitles and chevrons). No custom or phase colors.
- **Texts:**
  - `appTitle`: `"Sport Timer"` (EN & ES, existing).
  - `homeDrawerTemplates`: `"Templates"` (EN) / `"Plantillas"` (ES, existing).
  - `homeDrawerTimerStyles`: change from `"Timer styles"` to `"Styles"` in `lib/l10n/app_en.arb` and from `"Estilos del temporizador"` to `"Estilos"` in `lib/l10n/app_es.arb`, then regenerate `lib/l10n/app_localizations*.dart` with `fvm flutter gen-l10n`. Keep `timerStylesTitle` (`"Timer styles"` / `"Estilos del temporizador"`) unchanged for the `TimerStylesPage` app bar.
  - Subtitles reuse existing keys: `templateCustomName`, `templateDefaultName`, `templateAbsName`, `templateHyroxName`, `templateStretchingName`, `templateStrengthName`, `timerStyleRing`, `timerStyleFullColor`, `timerStyleRoundsStrip`.
- **Accessibility:**
  - Each `_DrawerTile` is wrapped in `Semantics(button: true, child: ...)` and is at least 64px tall (exceeding the 48×48 minimum tap target).
  - The header badge icon is wrapped in `ExcludeSemantics` so screen readers announce `"Sport Timer"` once.
  - Meets `androidTapTargetGuideline`, `iOSTapTargetGuideline`, and `textContrastGuideline` in both light and dark themes.
- **Snapshots:**
  - Refresh `test/snapshots/goldens/home_drawer.png` via `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`.
  - Update `test/snapshots/README.md`:
    - In the ASCII diagram under `## App Navigation Flow`, update `("Timer styles")` to `("Styles")`.
    - In section `### 3. Navigation Drawer & Account Overlays`, update the `goldens/home_drawer.png` row description to describe the `Sport Timer` header badge, divider, and `AppSurface` tiles for `"Templates"` (`"Custom"`) and `"Styles"` (`"Ring"`), and update `Tap "Timer styles"` to `Tap "Styles"`.

## Mockup

[mockup.html](mockup.html), approved by the user. It shows the redesigned drawer in `Custom + Ring`, `Hyrox + Rounds strip`, `With Debug Footer (DEV-01-02)`, and `Large Text (Single-line Ellipsis)` states, in Light and Dark themes and in English and Spanish.

## Decisions

- **Keep the navigation drawer on `HomePage` as the home for secondary screens:** chosen by the user so `Templates`, `Styles`, the debug `Developer tools` entry, and future secondary options have a dedicated place without crowding `TimerSetupPage` or the bottom navigation bar.
- **Replace `NavigationDrawerDestination` pills with `AppSurface` tiles showing active values:** chosen by the user so the drawer matches the rest of the app, eliminates the false "selected tab" highlight on `Templates`, and shows the active template and timer style at a glance.
- **Branded header with timer icon badge, `"Sport Timer"` title, and divider:** chosen by the user.
- **Shorten `homeDrawerTimerStyles` to `"Styles"` (EN) and `"Estilos"` (ES) and enforce single-line ellipsis (`maxLines: 1, overflow: TextOverflow.ellipsis`) on all drawer titles and subtitles:** chosen by the user so both drawer tiles always fit on one line per text role and have the exact same height in both languages and at large text scales.
- **Order before `DEV-01-02`:** chosen by the user. `IMP-02` builds the redesigned drawer first, and `DEV-01-02` depends on `IMP-02` and adds its debug footer using the same `_DrawerTile` / `AppSurface` style.

## Out of scope

- Adding new settings pages (theme switcher, language switcher, about page).
- Changing how `TemplatesPage` or `TimerStylesPage` work internally (beyond reusing the `TimerStyleNames` extension in `TimerStylesPage`).
- The debug-only `Developer tools` footer and page (owned by [DEV-01-02](../../developer-tools/stories/01-purge-local-activity/02-add-developer-page/index.md)).

## Files and tests

Created:

- `lib/features/settings/presentation/extensions/timer_style_names_extension.dart`: `TimerStyleNames` extension on `AppLocalizations` with `String timerStyleName(TimerStyle style)`.
- `test/features/home/presentation/home_page_test.dart`: widget tests for the redesigned drawer:
  - Header (`Icons.timer_outlined` badge, `"Sport Timer"` title, `Divider`) and two `AppSurface` tiles (`"Templates"` with subtitle `"Custom"`, `"Styles"` with subtitle `"Ring"`), with no `NavigationDrawer` or selected pill highlight.
  - Subtitles update when `SettingsRepository` loads a selected template (`TemplateId.hyrox` → `"Hyrox"`) and another style (`TimerStyle.roundsStrip` → `"Rounds strip"`).
  - Equal tile heights (`tester.getSize` on the two `AppSurface` widgets inside the drawer) in English (`Locale('en')`), Spanish (`Locale('es')`, showing `"Plantillas"` and `"Estilos"`), and at `TextScaler.linear(2)` without overflow.
  - Tapping `"Templates"` closes the drawer and navigates to `TemplatesPage`; tapping `"Styles"` closes the drawer and navigates to `TimerStylesPage` (tested with `Routes.router` or a `GoRouter` matching the `/home`, `/templates`, and `/timer-styles` routes).
  - Accessibility guidelines (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `textContrastGuideline`) in light and dark themes.
  - Registers private hand-written fakes for `SettingsRepository`, `UserRepository`, and `ActivityRepository` in `getIt` in `setUp` and calls `getIt.reset()` in `tearDown` (copying the fake structure in `test/snapshots/ui_snapshots_test.dart`).

Changed:

- `lib/l10n/app_en.arb`: change `"homeDrawerTimerStyles"` value from `"Timer styles"` to `"Styles"`.
- `lib/l10n/app_es.arb`: change `"homeDrawerTimerStyles"` value from `"Estilos del temporizador"` to `"Estilos"`.
- `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_es.dart`: regenerated via `fvm flutter gen-l10n`.
- `lib/features/settings/presentation/timer_styles/timer_styles_page.dart`: use `l10n.timerStyleName(style)` from `TimerStyleNames`.
- `lib/features/home/presentation/home_page.dart`: replace `NavigationDrawer` and `_onDrawerDestinationSelected` with the `Drawer` header, `Divider`, `ValueListenableBuilder<SettingsState>`, and `_DrawerTile` widgets.
- `test/features/templates/presentation/templates_page_test.dart`: in the three drawer navigation tests at the bottom of the file, replace `NavigationDrawerDestination` / `NavigationDrawer` / `'Timer styles'` finders with `Drawer` and `find.ancestor(of: find.text('Templates'), matching: find.byType(AppSurface))` and `find.ancestor(of: find.text('Styles'), matching: find.byType(AppSurface))`.
- `test/snapshots/goldens/home_drawer.png` and `test/snapshots/README.md`: refresh golden snapshot and update flow description.

## Acceptance

- [ ] When the drawer is opened on `HomePage`, then it renders a `Drawer` with the header (`Icons.timer_outlined` badge, `"Sport Timer"` title, and `Divider`) and two `AppSurface` tiles (`"Templates"` and `"Styles"`), each with a leading icon, single-line title (`maxLines: 1, overflow: TextOverflow.ellipsis`), single-line active value subtitle (`maxLines: 1, overflow: TextOverflow.ellipsis`), and trailing `Icons.chevron_right`. Check: `test/features/home/presentation/home_page_test.dart` and `test/snapshots/goldens/home_drawer.png`.
- [ ] When the drawer is rendered in English (`"Templates"` / `"Styles"`), in Spanish (`"Plantillas"` / `"Estilos"`), or at `TextScaler.linear(2)`, then both drawer tiles have the exact same height and render without overflow. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When `SettingsState.selectedTemplateId` is `null`, then the `Templates` drawer tile subtitle shows `"Custom"` (`"Personalizado"` in Spanish); when `selectedTemplateId` is `TemplateId.hyrox`, then the subtitle shows `"Hyrox"`. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When `SettingsState.timerStyle` is `TimerStyle.ring`, `TimerStyle.fullColor`, or `TimerStyle.roundsStrip`, then the `Styles` drawer tile subtitle shows the corresponding localized style name. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When the user taps the `Templates` or `Styles` tile in the drawer, then the drawer closes and the app navigates to `TemplatesPage` (`/templates`) or `TimerStylesPage` (`/timer-styles`) with the shared `SettingsViewModel`. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When the open drawer is checked in light and dark themes, then it meets `androidTapTargetGuideline`, `iOSTapTargetGuideline`, and `textContrastGuideline`. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When the snapshot test runs, then `test/snapshots/goldens/home_drawer.png` matches in light and dark. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart`.
- [ ] When the full test suite and agent check run, then all tests and layer boundary checks pass. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
