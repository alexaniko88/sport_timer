# EPIC: Templates

Status: Story 1 merged into `master` at `8c751c7`. Story 2 Task 2.1 Done, on `feat/templates-view-model`; Task 2.2 Ready where that output is available. Story 3 is provisional. Story 4 is agreed and Ready for planning where Task 2.1 is available.

Progress and reusable outputs: [Project task status](../status.md).

## Goal

Give the user a few quick, pre-configured workouts. One tap fills in preparation, round, rest and rounds, so the user never has to touch the wheels. The Templates tab also gets a new design that matches the rest of the app.

## Agreed behavior and boundaries

- Tapping a template applies its values to the saved timer settings and stays on the page. The existing Start button (FAB) starts the timer. A template never starts the timer by itself.
- A template overwrites the saved timer settings, so the Setup tab always shows what will run.
- There are 5 fixed, built-in templates: Default, Full Abs, Hyrox, Stretching and Strength. CrossFit is removed. Values are listed below.
- Each template is a compact row: icon, name, one summary line (for example `1:00 work · 0:30 rest · 5 rounds`), the total time on the right, and a thin phase bar at the bottom. The bar uses the app's own preparation, round and rest colors, sized by the real durations.
- Rows use the shared app tokens (spacing, radius, timer colors, shared widgets). The per-template accent colors, gradients, descriptions, "Total Workout Time" box, "Use Template" button and the subtitle line are removed. The app bar title "Choose your template" stays.
- Icons: Default `assignment`, Full Abs `sports_gymnastics`, Hyrox `directions_run`, Stretching `self_improvement`, Strength `fitness_center`.
- The selected row is computed by comparing the saved settings with each template. It is not remembered from the last tap.
- Separately, Timer Setup shows a tappable template name only after explicit selection and while all four settings still match. A divergent edit clears that selection until another explicit selection; valid selection survives restart. No label is inferred from existing settings. Tapping it opens Templates; choosing a template stays there. Full behavior: [Story 4](stories/done/04-selected-template-in-setup/index.md).
- If the settings match no template, no row is selected and a highlighted "Custom" card appears first in the list. It has its own icon and a slightly different "provisional" color. It shows the current values and the phase bar. It cannot be tapped or saved.
- Creating your own templates is provisional (Story 3). A "+" icon in the Templates app bar will be its entry point, and it stays hidden until that story is built.
- Names, summaries and texts are localized in English and Spanish, with the existing `gen-l10n` setup.

### Template values

| Template | Preparation | Round | Rest | Rounds | Total |
| --- | --- | --- | --- | --- | --- |
| Default | 0:20 | 1:00 | 0:30 | 5 | 7:20 |
| Full Abs | 0:20 | 0:30 | 0:10 | 20 | 13:30 |
| Hyrox | 0:20 | 4:00 | 0:30 | 8 | 35:50 |
| Stretching | 0:10 | 0:45 | 0:15 | 10 | 9:55 |
| Strength | 0:10 | 0:40 | 1:30 | 6 | 11:40 |

Default and Full Abs keep their current values. The other three are starting numbers and can be tuned later, because they are only data. The total is preparation plus (round + rest) × rounds, minus the last rest.

## Decisions and current constraints

Observed in the current code:

- The 3 templates live inside `lib/presentation/home/templates_page.dart`, with a heavy gradient card per template and its own accent colors.
- The "APPLIED" badge follows the last tap, so it goes stale after changing a wheel value or restarting the app.
- The Start FAB in `lib/presentation/home/home_page.dart` is shared by the Setup and Templates tabs and starts the timer from the saved settings.
- The navigation drawer holds one item (Timer styles) and is not part of this epic.

Decisions:

- The "Custom" card is a visual indicator only. Saving it as a template belongs to Story 3.
- Style unification is limited to the Templates page; Story 4 adds only the agreed Setup label and shortcut. The app-wide pass and the drawer rethink are separate provisional improvements: [IMP-01](../improvements/01-unify-styles-app-wide.md) and [IMP-02](../improvements/02-rethink-navigation-drawer.md).

## Stories

1. [New template set and tile redesign](stories/done/01-template-set-and-tiles/index.md) — complete on `improve/templates-page`: 5 templates, compact tiles and rebuilt page.
2. [Selection follows real settings](stories/done/02-selection-follows-settings/index.md) — computed highlight and the Custom card. Depends on Story 1.
3. [Create your own templates](stories/03-create-own-templates/index.md) — provisional; confirm before implementation.
4. [Show the selected template in Timer Setup](stories/done/04-selected-template-in-setup/index.md) — persistent explicit selection, a named Setup label and shortcut to Templates.

## Delivery order

Story 1, then Story 2. Together they are the first usable release. Story 3 is not needed for it and depends on both.

Story 4 depends on Task 2.1 and existing Story 1 output, independently of Task 2.2 and provisional Story 3. Its story number preserves existing paths and does not require waiting for Story 3. Its shortcut follows the navigation decision below rather than reintroducing a Templates tab after the drawer move.

## Navigation decision update — 2026-11-01

[UI refactor Story 2](../ui-refactor/stories/02-templates-in-drawer/index.md) supersedes the original tab/shared-Start navigation assumptions above: Templates moves to a separate drawer page, applies settings and stays open, and has no Start button. Back simply pops to the originating Home tab and preserves saved settings/selection. Start exists only on Timer Setup. Selection highlighting and Custom remain owned by this epic; navigation must not reset them. Historical implementation notes above describe the earlier delivery.
