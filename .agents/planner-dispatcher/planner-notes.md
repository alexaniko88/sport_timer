# Planner notes

Project facts the planner reads besides `planner_dispatcher.yaml` and its `rules` files.

## Branches and pull requests

- Branches start with `feat/`, `fix/` or `improve/` (never `chore/`, `docs/` or `refactor/`), then a short lowercase hyphenated summary. Planning branches use `feat/`.
- The PR title starts with the same prefix as its branch: `feat: ...`, `fix: ...`, `improve: ...`.
- Commit subjects are `<type>: <description>` with the types of `commit_types`, short, imperative, lowercase, no final period. Planning commits use `docs`.
- Every AI commit ends with `Co-Authored-By: <tool> <model>` (for example `Co-Authored-By: Claude Opus 5.5`), with no email. No attribution line in a PR description. The full rule is in `.agents/rules/git-commits.md`.

## UI sources

- Theme and tokens in `lib/shared/presentation/theme/`: colors in `app_palette.dart`, `timer_colors.dart` and `sport_theme.dart`, spacing in `app_spacing.dart`, radius and border width in `AppRadius` (8, 12, 20) and `AppBorderWidth` (1, 2), text roles in `app_text_styles.dart` and `../extensions/text_theme_extension.dart`.
- Shared widgets in `lib/shared/presentation/widgets/`: `AppSurface` (tiles and cards) and `AppButton`.
- A feature's page, widgets and ViewModel in `lib/features/<name>/presentation/`.
- Goldens in `test/snapshots/goldens/` (390 by 844, which is also the mockup frame size) and the flow index `test/snapshots/README.md`.
- `CLAUDE.md` ("Styling and theme").

## Project skills

- `skill-fl-chart`: for tasks that build or change an `fl_chart` chart.
- `skill-integration-tests` is never listed on a dispatcher task: integration tests are planned and run separately.

## Checks

`fvm dart tool/agent_check.dart --skip-build` compares the task branch with `master` and runs only what the changed files need: `dart format` (check only), `flutter analyze` on those files, the mirrored tests plus the layer boundary test, the golden snapshots when a presentation file, `navigation.dart` or an ARB file changed, `gen-l10n` when an ARB file changed, `test/architecture/ai_setup_test.dart` when `CLAUDE.md`, `.agents/` or `.claude/` changed, and a scan of added lines for local absolute paths. It skips the Android and iOS debug builds, and it is not the full `fvm flutter test` run (CI runs that). A change to domain, data or built-in template code can still alter a screen, so such a task names the snapshot test in its own checks. Update goldens with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`.

## Coverage checks

Ask these only when the change involves them:

- Timer, background and audio: timing, pause and resume, screen locking, interruption and recovery.
- Persistence and accounts: restart, failed writes, deletion, sign-out, ownership and account switching.
- Statistics: date boundaries, time zones, partial sessions and aggregation.
- UI: themes, both languages (English and Spanish) and accessibility.
