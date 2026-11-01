# Templates 2.2: Selection and Custom card

Branch: `feat/template-selection-card`. Base: `master` at `726bbb1`.
Task: [Templates 2.2](templates/stories/02-selection-follows-settings/02-show-selection-and-custom-card.md).
Plan and completed implementation/tests approved by user on 2026-11-01.

## Scope and decisions

Show live computed selection with a theme highlight and check icon. When no built-in matches, show an inert Custom card first with current preparation, round, rest, rounds, total duration and phase bar. Use English/Spanish localization and accessible selected/custom announcements. Keep existing navigation, persistence and ViewModel ownership.

Custom uses Icons.tune and a subtle tint/outline from timerColors.roundCounterBorder. Preserve readable theme text, stable built-in keys and smooth entry/exit without reserved blank space. Suppress initial selection until settings load. Respect reduced motion. No dependencies, platform changes or new state management. Setup shortcut and drawer navigation remain separate work.

## Completed steps

- [x] Connect page to live state and initial-loading status.
- [x] Add selected check and distinct Custom styling.
- [x] Add localized Custom labels, complete values and semantics.
- [x] Add focused widget tests for selection, delayed load, live changes/restoration, preparation-only edits, inert taps, semantics, themes/languages and transitions.
- [x] Apply requested Gap spacing and save project preference in `.claude/rules/dart-style.md`.
- [x] Complete implementation/tests approval and independent review.

## Validation and review

All 30 focused widget tests pass in `test/presentation/home/templates_page_test.dart` and `test/presentation/widgets/template_tile_test.dart`. `verify-branch.sh master` passes full analysis, changed-file formatting, both changed test files, generated-file checks and added-marker checks. Whitespace clean; no added code TODO/FIXME, personal absolute paths or employer data.

Round 1 review found two General issues: preparation was absent from the Custom summary/announcement, and outgoing Custom disappeared before collapse ended. Both fixed with localized full summaries and an AnimatedSwitcher size transition retaining the last unmatched values. Round 2 passes with no findings or suggestions.

User owns device/manual checks; no app launch or device control performed. User approved completed delivery. Commit approval pending; no commit or push yet.

## Requested workflow changes

Orchestrator now proceeds with clear plans without approval and no longer maintains traffic-light statuses or repeated task/index progress summaries. Redundant status edits from this session removed. Keep implementation evidence here. Skill validator unavailable because PyYAML is missing; diff checks pass.
