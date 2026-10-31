# Templates page approved plan

Task: [Templates 1.3](templates/stories/01-template-set-and-tiles/03-rebuild-templates-page.md).
Branch: `improve/templates-page`; base: `master` at `de93de8`.
Approved in the orchestration conversation on 2026-10-31.

Replace the large cards with the five existing compact tiles in their existing order. Reuse the shared settings save method, preserve title/menu/avatar and bottom clearance, remove the subtitle and last-tap selection. Retain English and Spanish localization. Selection and Custom belong to Story 2. No dependency or HomePage behavior changes.

- [x] 1. Replace the page and add its tile import; format and analyze touched files. Both checks passed; awaiting user validation before step 2.
- [x] 2. Remove seven unused localization keys from both ARBs and regenerate localization files. Generation, formatting and generated-file analysis passed; no references remain. Awaiting user validation before step 3.
- [x] 3. Add focused widget tests using handwritten fake repositories: tile order and settings saves, no automatic navigation/snackbar, Setup and Start integration. Six tests pass in `test/presentation/home/templates_page_test.dart`; formatting and test-file analysis clean. Awaiting user validation before step 4. Tests use a large surface; normal-phone layout and actual timer run remain manual checks.
- [x] 4. Full analysis and independent code/accessibility review passed; user confirmed all manual checks passed on 2026-10-31. Commit approval and PR approval remain separate.

Step 4 complete: `verify-branch.sh master` passed full analysis, changed-file formatting and all six widget tests. Independent code and accessibility reviews found no blocking findings. User confirmed all manual checks passed. User owns manual testing; do not use ADB, launch the app or control a device for testing unless explicitly requested.

Decisions: reuse existing tiles, localized names and save method; retain scrolling and existing bottom inset; no highlighted rows. Main risk: Spanish summaries and five-row fit above Start. Check a normal phone (390×844) and a narrower screen. Follow the user's one-step-per-validation-turn rule.
