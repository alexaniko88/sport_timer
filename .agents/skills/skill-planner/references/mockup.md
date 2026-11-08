# Mockup

A mockup is one self-contained HTML file, `mockup.html`. Before task splitting, keep it beside the planning record. Once the split is agreed, move it to the owning story (or standalone visual task) and update links. Visual block and assembly tasks link to its relevant states; do not make copies. ViewModel/state-only tasks need no mockup. The user approves the view before implementation, and goldens verify appearance afterward.

## How to build it

- **One file.** Inline CSS and JavaScript. No external requests, fonts or libraries, so it opens offline and keeps working years later.
- **Match the app.** Read the real tokens and copy their values: colors from `lib/shared/presentation/theme/app_palette.dart`, `timer_colors.dart` and `sport_theme.dart`, spacing from `app_spacing.dart`, radius and border width from `AppRadius` (8, 12, 20) and `AppBorderWidth` (1, 2), and the text sizes and weights of the text roles. Look at the matching golden image and make the mockup look like it. Name each CSS variable after the token it copies (`--primary`, `--outline-variant`).
- **Phone size.** A frame of 390 by 844 pixels, the size of the goldens, centered on the page. The page itself works at any width.
- **Show every state.** A control at the top switches between all the states of the view spec: default, empty, loading, error, partial data and long text. A state that is not in the mockup is not approved.
- **Both themes.** A light and dark switch that changes every color.
- **Both languages.** An English and Spanish switch with the real strings of the view spec.
- **Behave like the app.** Taps change what they change in the real flow, for example selecting a tile shows its selected state (thicker border, same size). Fake only what is needed to show the states.
- **Accessible.** Tap targets of at least 48 by 48, readable contrast in both themes, and a label on every icon-only button.
- **Comment the source.** Start the file with a short HTML comment: the planning topic (later its owning story/task), and the golden images it was based on.

## Showing it

Show it to the user so they can click through the states and the two switches. With the Artifact tool, publish it as a private Artifact and share the link. Without it, open the local file in the browser. Ask for "ok" or "no", and change it until the answer is "ok".

The file is committed with its owner; a story's reference stays with that story, and a standalone task's moves to `done/` with it. It is an approved historical reference, not a live design to maintain after implementation. The goldens record how the app looks.
