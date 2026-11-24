# Notes

## Summary

- Added `AppTag` (`lib/shared/presentation/widgets/app_tag.dart`) to the task's view spec: an outlined box, a 16 px primary icon, and a one-line ellipsized `labelMedium` label. With `onTap` it is one button with a 48 dp tap area. Without `onTap` it is plain text, and `semanticLabel` is optional.
- Added the `TemplateIcon` extension on `TemplateId` (`lib/features/templates/presentation/extensions/template_icon_extension.dart`) with the five icon mappings. `TemplatesPage` uses it instead of its local `switch`.
- `TimerSetupPage` replaces the old "Template: X" shortcut with a left-aligned `AppTag` above the grid. It opens Templates on tap, shows the template icon and name (or `Icons.tune` and `Custom`), and is hidden while the status is `initial` or `loading`.
- Review fix: split the 3-argument calls in `app_tag.dart` onto separate lines (`style` commit `860321a`).

## Evidence

- Unfilled box, radius, border, padding: `test/shared/presentation/widgets/app_tag_test.dart` "draws an unfilled bordered box without color" (light and dark) — passed
- Fill with the given color: same file, "fills the box with the given color" — passed
- 16 px primary icon, one-line label, ellipsis: same file, "shows a primary icon and a one-line label" — passed
- No `onTap` means plain text with an optional semantic label: same file — passed
- With `onTap`: one button node, tap calls `onTap`: same file — passed
- 48 dp tap area: same file, "with onTap has a 48 dp tap area" — passed
- Ellipsis in a narrow parent: same file — passed
- Five built-in icons unchanged, Custom first: `test/features/templates/presentation/templates_page_test.dart` — passed
- Custom and built-in tags in English and Spanish, light and dark: same file — passed
- No tag while settings load, tag after load: same file — passed
- Compact setup at text scale 1.0 and 1.5, Spanish at 1.5: same file — passed
- Snapshot goldens (7 setup and account/drawer images) refreshed; the snapshot test passes
- `fvm dart tool/agent_check.dart --skip-build --base=origin/master` passed

## Points to review

- The 7 regenerated golden images (`test/snapshots/goldens/setup_custom.png`, `setup_template_selected.png`, `setup_time_picker.png`, `setup_rounds_picker.png`, `home_drawer.png`, `account_sheet.png`, `account_sign_out_dialog.png`) were not viewed by the agent. They should be checked visually before merge.
- `test/snapshots/README.md` was updated for the two setup rows and the flow tree line.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
