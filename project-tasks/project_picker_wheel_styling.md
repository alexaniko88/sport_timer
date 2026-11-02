# Picker wheel styling plan

Branch: `improve/picker-wheel-styling`

Starting commit: `aab8441` (merged timer setup grid).

## Request and decisions

Keep the existing wheel interaction. After trying both appearances, the user chose a neutral theme surface for the sheet. Keep the existing selected fill, fading, phase colors and corner radii; use a uniform 1px border for selected and unselected values in both picker types. Alternative neutral surfaces and solid selection fills were rejected.

The user expanded the scope: match Minutes, Seconds and Rounds labels to the setup card label style, and wheel numbers to the setup card value style. Keep phase colors, selection tint and fading; use the neutral Templates surface for the sheet.

## Steps

- [x] Replace the selected and unselected border widths with one 1px width for minutes, seconds and rounds.
- [x] Format and analyze the touched file and run existing picker interaction tests.
- [x] Align wheel label and number typography with setup cards; validate picker tests and analysis.
- [x] User approved the neutral sheet appearance and asked to proceed. Visual validation across all phase colors and both themes remains a manual check.
- [x] Review the change: no findings. Full project analysis passed; all 10 picker tests passed.
- [ ] Commit and hand off the change.

No new logic tests are needed for the border-only change. Existing picker tests cover interaction; visual validation checks the appearance. Risk is low and limited to selection visibility.
