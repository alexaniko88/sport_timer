# View questions

Check these areas for every task with a view, before the mockup when one is needed. Apply the question filter in [questions.md](questions.md): evidence can settle an area without a question. Record irrelevant states as not applicable. The settled behavior becomes the task's `## View spec`; unresolved product behavior prevents readiness.

## Look first, ask second

Before you ask anything, read what exists and use it as the starting point:

- The snapshot images of the screens the task changes or sits next to, in the config's `goldens_dir` (skip when it is unset), and the flow index the planner notes' `## UI sources` names.
- The page, components and state code the project rules point to for this feature.
- The theme files, tokens and shared components named in `## UI sources`.
- The styling rules in the config's `rules` files.

Do not ask the user for a design. Propose the layout from the existing screens and ask only what you cannot see, in the question format of "Talking to the user" in the skill.

## What to settle

1. **Place and layout.** Where the view lives (new page, tab, sheet, dialog, part of an existing screen), what is on it, the order and grouping, and what scrolls.
2. **Every state.** Default, empty, loading, error, partial data, and long or wrapped text. For each: what the user sees and what they can do.
3. **Interaction.** What each tap, long press or swipe does, what happens while something is saving, and what feedback the user gets (snackbar, dialog, haptic).
4. **Navigation.** How the user gets in and out, what the back button does, and which route or `extra` carries data.
5. **Reuse.** Which shared pieces and tokens it uses. A new shared component or token needs the number of real users the project rules ask for; until then it stays local.
6. **Themes.** It must look right in light and dark. Say if anything uses a phase color or a custom color.
7. **Texts.** Every string, in every language the project rules require (English only when they name none), with a key name that follows the existing keys.
8. **Accessibility.** Labels for icon-only buttons, the tap target size (at least 48 by 48), text scaling, and the reading order.
9. **Snapshots.** When `goldens_dir` is unset, skip this item. Otherwise: which existing snapshot images change and which new states need one, by file name, and which flow index links change.

Write the answers into `## View spec` in the order above, in short bullets. Put the exact snapshot files in `touches` and the localization keys in `## Files and tests`.
