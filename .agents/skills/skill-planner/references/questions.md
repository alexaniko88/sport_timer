# Questions

Use this for the interview and its UI follow-ups. The question format is in "Talking to the user" in the skill. The aim is to settle every high-impact gap with as few questions as possible.

## The planning record

Its location and lifecycle are in [the planning record rule](../../../rules/backlog-format.md#planning-record). Create it before the first question. Keep four short sections:

- **Request:** the user's request as given, plus later scope changes, without rewriting their meaning.
- **Evidence:** relevant repository-relative paths, observed behavior and official documentation links. Keep current behavior apart from intended behavior.
- **Decisions:** one line each with a stable reference (D1, D2…), the decision and its source: `user`, `accepted recommendation` or `assumption` (not yet confirmed by the user). Exclusions are decisions too ("D5: out of scope: …"). A changed decision replaces the old one; never keep two current answers.
- **Open:** each gap still unsettled, why it matters, and whether it is a user decision, a fact to investigate or an external blocker.

Every relevant area of the change appears under Decisions or Open, or is covered by Evidence. Save about every three answers, at each checkpoint, before the split and before pausing. On resume, read the record and check the evidence for changes before the next question. An ambiguous reply stays open; silence is never agreement. If the user gives several decisions at once, record them all.

## Find the gaps

Start from the change itself: outcome, success checks, scope and exclusions, who uses it, the normal flow, data lifecycle, errors and limits. Add extra checks only when the change involves them:

- Persistence or accounts: restart, failed writes, deletion, sign-out, ownership and account switching.
- UI: the areas in [ui-questions.md](ui-questions.md).
- Anything under `## Coverage checks` in `.agents/planner-dispatcher/planner-notes.md`.

These are prompts, not questionnaires. Existing behavior answers a gap only when it also applies to the requested change. Do not invent remote risks or add future features to fill a list.

## Ask, assume or look up

For each gap, in this order:

1. **Look it up** when the repository, the rules or official documentation can settle it. Record the evidence.
2. **Follow the pattern** for a routine implementation choice the codebase already settles. Record the pattern when it matters.
3. **Assume** a low-impact product choice (a label, an order, a default that is easy to change later): record your recommended answer as an `assumption`. The user confirms all assumptions with the split in step 6; a rejected one becomes a normal question.
4. **Ask** only a high-impact decision: one that changes scope, visible behavior, data that is kept or lost, a meaningful technical constraint, or how success is checked. Never assume one of these.

Ask contradictions first, then decisions that block other decisions, then the rest by impact. Choose the next question again after each answer. After an answer, update the affected entries and check for new contradictions or reopened decisions. Do not invent a reason the user did not give.

## Stop

Stop asking when every remaining gap is low-impact (record it as an assumption), or when you reach the question budget of step 2 (checkpoint). A blocked decision stays under Open and keeps affected work `draft`; continue with independent areas. Each requirement must have a feasible way to check it before the split.
