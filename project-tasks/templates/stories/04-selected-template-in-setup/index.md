# STORY 4: Show the selected template in Timer Setup

Epic: [Templates](../../index.md)

Status: Ready for planning where the completed Task 2.1 output is available. Application code changes are not approved by this backlog agreement.

## User outcome

As a user, I want Timer Setup to confirm which template I selected and let me open Templates from that label, so that I can recognise and change my choice.

## Agreed behavior and scope

- Show a small, tappable `Template: <localized name>` label below the `Timer setup` title and above the settings buttons, without replacing the page title.
- Show it only after the user explicitly selects a built-in template, while all four current timer settings still match that selected template. Selecting a template whose values already match also counts as explicit selection.
- Tapping the label opens the existing Templates page. Selecting a template stays on Templates, including when entered through this shortcut.
- An edit that makes preparation, round, rest or rounds differ from the selected template clears the explicit selection. Restoring matching values does not restore the label; another explicit selection is required.
- Remember the explicit selection across app restarts, provided the restored settings still match. Missing, unknown or mismatched selection data must not show a label.
- Fresh installs and existing installations without recorded explicit selection show no label, even if the settings match Default or another template. Do not infer past selection from settings alone.
- Hide the label entirely when there is no valid explicit selection. The existing Templates navigation entry remains available in that state.
- Timer style is outside the four-field match and does not clear selection.
- Keep the Templates page's matching-row and Custom-card behavior from Story 2: matching is based on current settings, independently of explicit selection. Manual matching can therefore highlight a row without showing a Setup label.
- Localize the label in English and Spanish and expose its name and navigation action to accessibility services.

Out of scope: custom-template creation, a permanent Setup shortcut when nothing is selected, automatic navigation back to Setup after choosing a template, and changes to the Start action or Templates-page matching rules.

## Acceptance criteria

- Selecting any built-in template and returning to Setup shows its localized name below the title; selecting a different template updates the name.
- Selecting a template whose values already match still makes the label appear.
- Tapping the label opens the existing Templates page without applying another template or changing settings. A subsequent selection keeps the user on Templates.
- Changing any of the four matching settings to a different value hides the label. Restoring those values or manually matching another template leaves it hidden until explicit selection.
- Changing timer style, or leaving the four settings unchanged, does not clear a valid selection.
- Restarting restores a valid explicit selection and its label. Missing, unknown or mismatched stored selection shows no label.
- Fresh installs and upgrades with only saved timer settings show no label until explicit selection, including when Default matches.
- Templates-page matching remains independent: a manual match can highlight a row while the Setup label remains hidden.
- The label is readable and tappable in light and dark themes, uses localized text, and is announced as an action with the template name.

## Tasks

1. [Track explicit selection and show the Setup shortcut](01-track-selection-and-show-setup-shortcut.md).

## Dependencies and open decisions

Depends on the shared matching and application flow delivered by [Task 2.1](../done/02-selection-follows-settings/done/01-add-templates-view-model.md), plus the existing built-in template data and page from [Story 1](../done/01-template-set-and-tiles/index.md). Does not depend on Task 2.2 or provisional Story 3; numbering preserves existing story paths rather than imposing delivery order.

No product decisions remain open. During implementation planning, settle ownership and lifecycle of explicit selection, how it is saved consistently with timer settings, and navigation wiring through the existing Home navigation. The current computed match alone cannot establish explicit selection, and reopening Templates must not recreate cleared selection. Detailed styling and storage mechanics follow existing project patterns.

## Navigation integration

At discussion time, Templates is a Home tab. The separately agreed [UI refactor Story 2](../../../ui-refactor/stories/02-templates-in-drawer/index.md) moves it to a drawer page. This shortcut must open the same Templates destination using the navigation available in the implementation checkout; after that refactor it opens the separate page and ordinary Back returns to Setup. Do not recreate a removed tab or add a second Templates page. The hidden-label state continues to rely on the existing entry point (tab today, drawer after the refactor). This is an integration constraint, not a prerequisite to implement the drawer move here.
