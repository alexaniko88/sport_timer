# View questions

Ask these for every task with a view, before the mockup. The answers become the task's `## View spec`. A view that cannot answer one of them is not ready.

## Look first, ask second

Before you ask anything, read what exists and use it as the starting point:

- The goldens of the screens the task changes or sits next to, in `test/snapshots/goldens/`, and the flow index `test/snapshots/README.md`.
- The page, widgets and view model in `lib/features/<name>/presentation/`.
- The shared pieces in `lib/shared/presentation/`: `AppSurface` (tiles and cards), `AppButton`, the theme (`theme/sport_theme.dart`, `app_palette.dart`, `timer_colors.dart`), the spacing and radius tokens (`app_spacing.dart`, `AppRadius`, `AppBorderWidth`), and the text roles (`extensions/text_theme_extension.dart`, `theme/app_text_styles.dart`).
- `CLAUDE.md` ("Styling and theme").

Do not ask the user for a design. Propose the layout from the existing screens and ask only what you cannot see. One question at a time, each with your recommended answer.

## What to settle

1. **Place and layout.** Where the view lives (new page, tab, sheet, dialog, part of an existing screen), what is on it, the order and grouping, and what scrolls.
2. **Every state.** Default, empty, loading, error, partial data, and long or wrapped text. For each: what the user sees and what they can do.
3. **Interaction.** What each tap, long press or swipe does, what happens while something is saving, and what feedback the user gets (snackbar, dialog, haptic).
4. **Navigation.** How the user gets in and out, what the back button does, and which route or `extra` carries data.
5. **Reuse.** Which shared pieces and tokens it uses. A new shared widget or token needs two or more users; if only one needs it, it stays local.
6. **Themes.** It must look right in light and dark. Say if anything uses a phase color or a custom color.
7. **Texts.** Every string, in English and in Spanish, with a key name that follows the existing keys.
8. **Accessibility.** Labels for icon-only buttons, the tap target size (at least 48 by 48), text scaling, and the reading order.
9. **Snapshots.** Which existing goldens change and which new states need one, by file name, and which flow links in `test/snapshots/README.md` change.

Write the answers into `## View spec` in the order above, in short bullets. Put the exact golden files in `touches` and the string keys in `## Files and tests`.
