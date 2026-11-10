# Notes

## Summary

- `home_page.dart`: replaced `NavigationDrawer` with a `Drawer` that has a branded header (`Icons.timer_outlined` badge, `Sport Timer` title) and a `Divider`.
- Below the header are two single-line `_DrawerTile` tiles built on `AppSurface`.
  - They are `Templates` (subtitle: the selected template name or `Custom`) and `Styles` (subtitle: the active timer style).
  - A `ValueListenableBuilder<SettingsState>` keeps both subtitles live. Each tile has a trailing chevron and closes the drawer before pushing its route.
- Added the `TimerStyleNames` extension on `AppLocalizations` (`timer_style_names_extension.dart`) and used it in `HomePage` and `TimerStylesPage`.
- `homeDrawerTimerStyles` is now `Styles` in `app_en.arb` and `Estilos` in `app_es.arb`. `fvm flutter gen-l10n` regenerated the localization files. `timerStylesTitle` is unchanged.
- Analyze: `fvm flutter analyze --no-pub` on the three touched Dart files reports no issues, and `fvm dart format` changed nothing.
- I did not write tests, the golden refresh, the `test/snapshots/README.md` update or the `templates_page_test.dart` finder changes. The role file says the tests stage does those. Until they are done, `templates_page_test.dart` still references the old `NavigationDrawer` and `Timer styles` text, and the `home_drawer.png` golden is stale.

## Evidence

- Drawer renders header, two `AppSurface` tiles, icons, chevrons, single-line text: `fvm flutter test test/features/home/presentation/home_page_test.dart` and `home_drawer.png` golden — passed
- Equal tile heights in English, Spanish and at 2x text scale, no overflow: `home_page_test.dart` (group `equal tile heights`) — passed
- Templates subtitle is `Custom` or `Hyrox`: `home_page_test.dart` — passed. The Spanish `Personalizado` check is also in `home_page_test.dart` — passed.
- Styles subtitle for ring, full color and rounds strip: `home_page_test.dart` — passed
- Tapping a tile closes the drawer and navigates: `home_page_test.dart` — passed. The route stubs there receive no `SettingsViewModel`, so passing it through `extra` is not asserted there; `templates_page_test.dart` uses the real `TemplatesPage` route and that path — passed.
- Tap target and contrast guidelines in light and dark: `home_page_test.dart` — passed
- `home_drawer.png` matches in light and dark: `fvm flutter test test/snapshots/ui_snapshots_test.dart` — passed
- Full suite and agent check: `fvm flutter test` (565 passed) and `fvm dart tool/agent_check.dart --skip-build` (all checks passed) — passed. The debug builds were skipped, as `--skip-build` skips them.

## Review notes

- lib/features/home/presentation/home_page.dart:150: The Templates subtitle uses a `switch` with only two outcomes (`final id?` / `null`). dart-style.md asks for `if-case` or a ternary for a two-way choice, and the task gives the `if (state.selectedTemplateId case final id?)` form.
- test/features/templates/presentation/templates_page_test.dart:827: The test name still says 'Timer styles', but the drawer label is now 'Styles'.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5

## Commands denied

- `cat >> lib/features/home/presentation/home_page.dart <<'EOF'

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      button: true,
      child: AppSurface(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const Gap(AppSpacing.s12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.tileTitle,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.tileSecondary.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.s12),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
EOF
fvm flutter gen-l10n 2>&1 | tail -3
F="lib/features/home/presentation/home_page.dart lib/features/settings/presentation/extensions/timer_style_names_extension.dart lib/features/settings/presentation/timer_styles/timer_styles_page.dart"
fvm dart format $F; fvm flutter analyze --no-pub $F 2>&1 | tail -15`
- `cd /private/var/folders/9n/5cxxgsts4057yjbxmgxth3vr0000gn/T/sport-timer-runs/IMP-02/repo; python3 - <<'E'
p='test/features/templates/presentation/templates_page_test.dart'
s=open(p).read()
s=s.replace("""    final destinations = find.byType(NavigationDrawerDestination);
    expect(destinations, findsNWidgets(2));
    final templatesDest = find.widgetWithText(NavigationDrawerDestination, 'Templates');
    final timerStylesDest = find.widgetWithText(NavigationDrawerDestination, 'Timer styles');
""","""    expect(find.byType(Drawer), findsOneWidget);
    final templatesDest = find.ancestor(of: find.text('Templates'), matching: find.byType(AppSurface));
    final timerStylesDest = find.ancestor(of: find.text('Styles'), matching: find.byType(AppSurface));
""")
s=s.replace("expect(find.byType(NavigationDrawer), findsNothing);","expect(find.byType(Drawer), findsNothing);")
s=s.replace("find.widgetWithText(NavigationDrawerDestination, 'Templates')","find.ancestor(of: find.text('Templates'), matching: find.byType(AppSurface))")
s=s.replace("import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';\n","import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';\nimport 'package:sport_timer/shared/presentation/widgets/app_surface.dart';\n")
open(p,'w').write(s)
E
grep -n "NavigationDrawer" test/features/templates/presentation/templates_page_test.dart; grep -n "enum TimerStyle" -A5 -r lib/features/settings/domain; grep -n "TemplateId" -A8 lib/features/templates/domain/workout_template.dart | head -20; grep -n "extra\|timerStyles" lib/navigation.dart`
