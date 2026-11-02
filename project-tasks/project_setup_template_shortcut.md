# Templates 4.1: Explicit selection and Setup shortcut

Branch: `feat/setup-template-shortcut`. Base: `master` at `fee67c3e5b20bcbbc2cb155f299eac227387e5a3`.
Task: [Templates 4.1](templates/stories/done/04-selected-template-in-setup/done/01-track-selection-and-show-setup-shortcut.md).

## Request and approach

Show a localized tappable template name below the Setup title only after explicit selection. Preserve valid selection across restarts; clear it permanently on a divergent timer edit. Keep Templates computed matching and Start independent.

Shared SettingsViewModel owns explicit selection; TemplatesViewModel remains responsible for computed matching. Persist settings and selection as one snapshot to avoid inconsistent multi-key selection writes. Read legacy settings when no new snapshot exists, without inferring selection. Validate restored IDs against built-in data and all four settings. Unknown/mismatched selection stays hidden.

Decided: use one snapshot instead of independently writing selection and settings; retain existing Templates tab navigation rather than implement the separate drawer refactor. Use existing English/Spanish gen-l10n, overriding the stale workflow statement that localization does not exist. No dependencies or platform changes.

## Steps

- [x] Extend settings state/repository and queued lifecycle for explicit selection, migration, validation and failure handling.
- [x] Connect explicit template application while retaining computed matching.
- [x] Add localized accessible Setup action and Home navigation callback.
- [x] Add and run focused repository, ViewModel and widget tests.
- [x] Obtain combined implementation/tests approval, then independent review.
- [x] Run hand-off checks and request commit approval.

## Validation and risks

Test explicit versus automatic match, same-value taps, each divergent field, restoration before flush, unchanged/style preservation, valid restart, absent/unknown/mismatched data, pending load/write races and failed saves. Widget checks cover English/Spanish, both themes, action semantics, existing Templates entry and navigation that stays on Templates after selection. Use handwritten fakes and fvm commands. Format/analyze literal touched paths and run touched tests; full analysis at hand-off.

Main risk: asynchronous settings persistence must not resurrect cleared selection or overwrite edits. Manual device checks (themes, placement, restart) remain distinct from automated tests.

Durability clarification: invalidation is immediate in memory; only completed writes survive restart. A failed or interrupted write may leave the last successfully saved configuration (including its valid selection). Atomic persistence must prevent mixed settings/selection snapshots, not promise durability for unwritten edits. Keep synchronous editing and existing failure/retry behavior rather than block edits on a durable invalidation.

Implementation and tests merged from the worker. Worker ran localization generation, touched-file formatting and analysis. Parent ran full `fvm flutter analyze` (no issues), `git diff --check` (clean), and `fvm flutter test test/features/settings/settings_repository_test.dart test/features/settings/settings_view_model_test.dart test/features/templates/templates_view_model_test.dart test/presentation/home/templates_page_test.dart test/presentation/home/timer_settings_persistence_test.dart` (77 passed). Full test suite and manual device checks not run. Awaiting combined implementation/tests approval before independent review. No commit or push.

User approved completed implementation and tests after confirming the changes are visible in Delta. Continue in Delta's attached checkout. Independent review started; commit and push remain unapproved.

Review round 1: two General findings, no Critical or Minor findings. Failed SharedPreferences writes leave unconfirmed data in the process cache that a new ViewModel can read; regression must cover a same-process reread without resetting preferences. Selected label also causes Setup overflow at 320×568; make layout scrollable/responsive with bottom controls clearance and test compact screens/enlarged text. Worker assigned both fixes and validation before round 2. Do not treat review as passed yet.

Both round-1 fixes merged: reload platform preferences before snapshot reads/save comparisons; use a scrolling Setup list with bottom control clearance. Same-process failed-write reread/retry regressions and 320×568 layout tests at 1.0/1.5 text scale added. Parent reran full analysis (clean), all five touched test files (79 passed), whitespace check (clean), diff absolute-path scan (none), added TODO/FIXME scan (none). No platform/dependency changes, so platform builds do not apply. Round 2 independent review underway.

Round 2 independent review: PASS, no Critical, General or Minor findings. Parent validation above passed after both fixes. Diff inspected for personal paths/employer data: none. Full suite/manual device checks not run. Commit proposal: `feat: show explicitly selected template in setup`, trailer `Co-Authored-By: Codex <noreply@openai.com>`, all 19 changed/new files comprising implementation, five tests and two plan/memory files. Await commit approval. Configure the checkout-local personal noreply author email before committing; inherited identity is not suitable for this personal repository. No commit/push yet.

## Workflow

Plan proceeds without approval. Ask once for completed implementation/tests approval before review, once for commit approval after review, then offer PR. No stage/commit/push by subagents. No task archival until PR approval.

Implementation committed as `c094417` after user approval. User approved push and PR; archive Task 4.1 and its completed Story 4 before the initial push. Templates epic remains active because provisional Story 3 remains. Commit archival as documentation on the same branch, then open PR against `master`; no merge authorized. Completion evidence is recorded above; full suite and manual device checks remain unrun.
