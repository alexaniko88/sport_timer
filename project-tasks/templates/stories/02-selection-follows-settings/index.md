# STORY 2: Selection follows real settings

Epic: [Templates](../../index.md)

Status: Ready for planning where completed [Story 1](../01-template-set-and-tiles/index.md) is available (`improve/templates-page`, not yet committed or merged).

## User outcome

As a user, I want the Templates tab to tell me truthfully what is set, so that I know when I am on a template and when I am on my own values.

## Scope

- Work out which template matches the current saved settings, or none.
- Highlight the matching row with the theme color and a check icon.
- When nothing matches, remove every highlight and show a "Custom" card as the first item.
- The Custom card uses the same row layout, a clear "custom" icon and a slightly different "provisional" color, so it reads as temporary. It shows the current values and the phase bar.
- The Custom card is visual only: it cannot be tapped and it has no save action.

Out of scope: saving the Custom card as a template ([Story 3](../03-create-own-templates/index.md)).

## Acceptance criteria

- On a fresh install with the default settings, the Default row is highlighted and there is no Custom card.
- Tapping a template highlights that row. Changing any one wheel value on the Setup tab and coming back removes the highlight and shows the Custom card with the new values.
- Setting the wheels back to exactly a template's values highlights that template again and removes the Custom card.
- The highlight is correct after an app restart.
- The Custom card is clearly different from the 5 rows, in light and dark theme, and is announced as custom by a screen reader.
- Tapping the Custom card does nothing, and no save option is offered.

## Tasks

1. [Add a templates view model](01-add-templates-view-model.md).
2. [Show the selection and the Custom card](02-show-selection-and-custom-card.md).

## Dependencies and open decisions

Needs the template data and the tile from [Story 1](../01-template-set-and-tiles/index.md). The exact "provisional" color is decided while planning Task 2.2, within the existing timer colors.
