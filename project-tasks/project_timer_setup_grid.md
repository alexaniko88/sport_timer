# Timer setup grid

Branch: `improve/timer-setup-grid`. Base: `master` at `2d2ae67`.
Task: [UI 1.1](ui-refactor/stories/01-timer-setup-refactor/done/01-build-timer-setup-grid.md).

## Request and approach

Replace Setup's four full-width options with reusable centered cards in reading order: preparation, work, rest, rounds. Normal portrait uses two equal square columns; narrow screens and large text permit taller cards or one column, retaining scrolling and clearance above Start/navigation.

Dependencies verified in this checkout: TemplateTile normal treatment and current localized settings/picker flow exist. Reuse surfaceContainer, outlineVariant, AppRadius.r12 and a 1px border directly. Only icons use phase colors. Material/InkWell provides interaction and keyboard activation, with one accessible button per card exposing localized label, value and selector hint.

Decided, change if you disagree: use existing theme tokens directly rather than extract shared styling for a small decoration; keep card independent of settings/picker logic; use content-aware adaptation rather than fixed square cells that clip text. Preserve existing EN/ES localization, overriding the skill's stale no-localization assumption. No new dependencies or platform changes.

## Steps

- [x] Add reusable centered TimerSettingCard with accessible activation and existing tile treatment.
- [x] Add adaptive grid with equal square minimums, natural growth and single-column fallback.
- [x] Integrate four existing selectors in Setup and home library imports, preserving limits, immediate updates, flush, selected-template shortcut, scrolling and shared Start.
- [x] Add focused card/grid tests and adapt existing Setup/Templates integration coverage; run touched-file format/analyze and relevant tests.
- [x] Obtain combined implementation/tests approval before independent review.
- [x] Review, validate, and propose commit for approval.

## Validation and risks

Cover all four actions and live values, picker limits and dismissal persistence, both themes, phase icon colors, EN/ES labels, single accessible action, keyboard activation, square portrait geometry, narrow/large-text reachability and Start receiving latest settings from both tabs. Reuse existing handwritten fakes and GoRouter harness; no new test framework. Run fvm commands and only relevant literal test paths. No tests of unrelated code.

Main risk: large text and long Spanish labels overflowing or settings obscured by the floating Start button. Manual validation remains needed for visual fit in both themes/languages, selectors and Start on both tabs.

## Workflow

Implementation committed as `f5e6830` after commit and PR approval. UI 1.1 archived under its story’s `done/`; unfinished tasks keep the story and epic active. Archive links validated before the approved initial push and PR creation. Full review/checks passed; no merge authorized.

User approved the proposed commit and opening the PR with "ok, and opne pr". Commit all 13 approved files, then archive only UI 1.1 in a docs commit before pushing. Story 1 and the epic stay active because pending/provisional tasks remain. PR source `improve/timer-setup-grid`, target `master`; title `improve: show timer setup settings in equal grid cards`. Description covers equal adaptive cards, shorter EN/ES labels, unused localization cleanup, preserved picker/save/Start flow, 46 passing focused tests, full analysis/format and independent review. No merge authorized.

Follow-up independent review of all six unused localization key removals: PASS, no findings; EN/ES ARBs and generated classes consistent, no production references. Final branch verification repeated after cleanup and passed. Commit approval is the next pending checkpoint.

User explicitly expanded cleanup to remove loginTitle, statisticsDefaultUserName and statisticsGreeting as well. Removed these from both ARBs including metadata, regenerated localization files, and verified no references remain. Formatting/analysis passed; all 46 relevant widget/localization tests passed. No TODO/FIXME added. Same pending commit message and 13-file list; user has not yet approved commit.

User requested removal of the old unused setting labels before commit. Removed commonPreparationTime, commonRoundTime and commonRestTime from EN/ES ARBs and regenerated localizations. No references remain; generated-file formatting/analysis and all 46 relevant widget/localization tests passed. A subsequent user-requested audit of all 67 remaining keys across 75 non-generated Dart files found three further keys with no app/test references: loginTitle, statisticsDefaultUserName and statisticsGreeting. These are outside this grid replacement and are reported without removal. Commit approval remains pending; same 13-file list applies.

Independent review round 1: PASS, no Critical, General or Minor findings; no review fixes required. Final `verify-branch.sh master` passed full analysis, format check and all three changed widget test files. Initial sandbox run could not write Flutter SDK cache; rerunning the same checks with required cache access succeeded. Separate full `fvm flutter analyze` also passed. Whitespace check passed; diff/new files inspected for personal paths/employer data with none found; no code TODO/FIXME added. No platform/dependency changes, so platform builds do not apply. User performed visual validation and approved implementation. Proposed commit: `refactor: render timer setup settings as equal grid cards` with `Co-Authored-By: Codex <noreply@openai.com>`, all 13 changed/new files. Await commit approval; no commit or push. Repo-local author email verified as personal noreply address.

User approved completed implementation and tests with "ok, lgtm" after the uniform grid/ellipsis/short-label revision. Independent review started; commit and push remain unapproved.

User-requested layout revision: all four cards must have identical dimensions, rendered by a real grid; both labels and values are single-line with ellipsis. Setup labels become Preparation, Work (recommended one-word replacement), Rest and Rounds, with Preparación, Trabajo, Descanso and Rondas in Spanish. Add Setup-specific keys to avoid altering other screens. This supersedes the original per-row intrinsic sizing and wrapping decision. Keep existing adaptive one/two columns, outer scroll and bottom clearance. Use a non-scrolling shrink-wrapped GridView with one shared mainAxisExtent: max(cell width, tallest single-line content height measured with actual styles/text scaler/locale/direction plus icon, gaps and padding). Cards remain square normally and equally taller at extreme text sizes; full semantics remain untruncated. Regenerate existing l10n and update focused geometry/ellipsis/translation tests, plus existing selector/Start finder expectations. Validation and implementation approval pending for this revision.

Layout revision completed: GridView and shared height applied, both text fields ellipsize at one line, new Setup labels localized and generated files refreshed. Extreme 240px/5x test caught 2px vertical overflow; corrected measurement to account for existing border on both sides. All 46 tests passed across the three focused widget files plus `test/l10n/app_localizations_test.dart`; literal-path formatting and analysis passed. Coverage now includes equal dimensions at normal/large scales, extreme scale without overflow, ellipsis and full semantics. No TODO/FIXME added. Awaiting user visual check/combined approval before independent review; no commit/push.

User selected Icons.self_improvement for the Rest card; replaced the pause icon while retaining its theme phase color and 40px size. Literal-path formatting/analysis and all 38 focused widget tests passed. This explicitly requested visual refinement supersedes the original keep-existing-icons decision for Rest only.

User-requested icon refinement: increased card icons from 32 to 40 using AppSpacing.s40. Formatting and literal-path analysis passed; all 38 tests in the three focused widget files passed again. Visual approval remains pending.

User-requested typography refinement: keep existing sizes; values use w700, labels use w500 and onSurfaceVariant, icons unchanged. Applied in TimerSettingCard, with the existing style test updated for both themes. Literal-path formatting and analysis passed; focused card tests passed (3). User will visually check the result; combined implementation approval remains pending before review.

Stage 2: production implementation complete. Touched `timer_setting_card.dart`, `home.dart` and `timer_setup_page.dart`; literal-path formatting and analysis passed. No TODO/FIXME added. Stage 3 widget validation pending.

Stage 3: added `test/presentation/widgets/timer_setting_card_test.dart`, extended `test/presentation/home/templates_page_test.dart` and `test/presentation/home/timer_settings_persistence_test.dart`. Covers whole-card and keyboard activation, single accessible action, light/dark surfaces and icon colors, EN/ES labels, equal square ordering, narrow large-text Spanish scrolling/selector reachability, all four picker arguments/live values/dismissal saves, latest settings launched from both tabs, and existing shortcut behavior. All 38 tests passed; conductor reran the same three test files successfully. Formatting passed and conductor analysis of all six changed Dart files reported no issues. `git diff --check` passed. No TODO/FIXME added. Manual device visual checks not run. Awaiting combined implementation/tests approval before independent review. No commit or push.

Clear plan proceeds without a plan approval checkpoint under the explicitly invoked skill. Ask once for completed implementation/tests approval before review, then once for commit approval, then offer PR. Never push without explicit approval. Archive only after PR approval.
