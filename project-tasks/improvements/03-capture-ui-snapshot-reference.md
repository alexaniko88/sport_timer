# IMP-03: Capture a UI snapshot reference

Improvements: [Improvements](index.md)


Status: Ready for planning.

## Current behavior and limitation

The repository has widget tests for selected screens and flows, but no maintained visual snapshot set or index that lets an agent inspect the app's appearance and navigate its flow without launching it.

## Desired change

Create repeatable Flutter captures using Alchemist platform goldens, keep the resulting readable PNGs in the repository, and document the screen flow and meaningful captured states in a Markdown index. Refresh affected snapshots and the index when a UI change alters a captured screen, state, or route.

## Benefit

Agents can quickly understand the current UI and how screens connect from repository artifacts, while contributors can review intentional visual changes alongside UI work.

## Scope and exclusions

- Cover the implemented app at one phone size, in English, in light and dark themes.
- Capture the existing login and home destinations (Setup, Templates, Statistics, Timer Styles, and Timer), plus meaningful states such as the drawer, account sheet and confirmation, settings pickers, template selection, and timer phases/styles/paused state where deterministic capture is practical.
- Include deterministic sample data and avoid network-dependent account imagery or personal data.
- Describe route transitions in the Markdown index; this task does not require automated end-to-end navigation.
- Use Alchemist platform goldens for readable text. Automatic pixel comparison policy, CI golden baselines, additional device sizes, and additional locales are future decisions.

## Dependencies

None.

## Acceptance criteria

- A documented command generates the committed PNG snapshots repeatably from real Flutter widgets without requiring a user account, network access, or launching the app manually.
- The Markdown index links every snapshot, names its screen/state and theme, and explains the app flow with links to relevant next screens.
- The index and snapshot set cover the agreed implemented screens and meaningful states; known impractical or nondeterministic states are listed with a reason.
- The repository explains that UI changes must refresh affected snapshots and update flow links when screens, states, or routes change.
- Snapshot generation completes successfully and the generated images are reviewable as ordinary PNG files.

## Validation

Run the documented snapshot generation command and verify its outputs and Markdown links. Confirm captures use fixed fixture data and are stable across repeated generation in the supported local environment.

## Implementation context

The current app flow is Login → Home (Setup, Templates, Statistics); the drawer opens Timer Styles; Start opens Timer. Useful entry points include `lib/navigation.dart`, `lib/presentation/home/home_page.dart`, `lib/presentation/timer/timer_page.dart`, and `lib/presentation/timer/widgets/`. Existing widget-test setup is in `test/presentation/home/templates_page_test.dart`. No Alchemist, golden configuration, or integration-test setup was found in the inspected checkout. Statistics is currently a placeholder. Check the current branch before planning because screen availability may differ.
