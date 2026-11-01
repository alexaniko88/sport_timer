# Templates ViewModel approved plan

Task: [Templates 2.1](templates/stories/02-selection-follows-settings/done/01-add-templates-view-model.md).
Branch: `feat/templates-view-model`, from `master` at `8c751c7`.
Approved: 2026-11-01.

## Scope and decisions

Observe the existing shared `SettingsViewModel`, matching all four `TimerSettings` values against the built-in templates. Use current settings, including edits awaiting persistence, to match Setup and Start. Apply templates through the existing save flow. No repository API, dependency, navigation or visual changes. Page changes are limited to lifecycle and existing tap wiring. Never dispose the shared settings ViewModel.

## Steps

- [x] 1. Add immutable `TemplatesState` with current settings and nullable selected template id, equality, hashCode and copyWith supporting clearing selection.
- [x] 2. Add `TemplatesViewModel`: initial/live matching, delegated apply and listener cleanup.
- [x] 3. Wire page ownership and taps, including replacement settings ViewModels, preserving appearance.
- [x] 4. Add focused unit tests: all templates, single-field mismatches, returning to a match, loaded/live settings, persistence and disposal including pending operations. Run relevant checks and independent review.

Implementation steps 1–3 and completed implementation/tests approved by the user. All steps complete. Tests use hand-written fakes; shared settings ownership and page appearance are preserved. No device/app control performed.

## Handoff

Completed on `feat/templates-view-model`. Fifteen focused unit tests pass in `test/features/templates/templates_view_model_test.dart`. `verify-branch.sh master` passed full analysis, changed-file formatting, tests and generated/marker checks; diff whitespace clean. Independent production review: no findings or suggestions. No added code TODO/FIXME, dependency or platform changes. Commit message and file list approved. The separate `.agents/skills/skill-orchestrator/SKILL.md` update is excluded from the task commit. Task 2.2 is ready where these outputs are available and has not been started.

Runtime follow-up: user reports template taps leave Home unchanged. Read-only trace confirms a shared settings ViewModel. All six existing `test/presentation/home/templates_page_test.dart` integration tests pass on this code, including each template applying, saving and updating Home/Start. User confirmed it works; concern resolved without code changes. Implementation commit approved.

PR handoff: implementation `511ce33`, skill update `eb3aad5`; user approved push and PR. Task 2.1 archived before the initial push; Story 2 and Templates epic remain active.
