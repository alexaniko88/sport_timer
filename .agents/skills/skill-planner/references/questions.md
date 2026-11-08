# Questions

Use this process for the interview and its UI follow-ups. The aim is complete relevant coverage with small questions, not a low question count.

## Keep one working record

Use the location and lifecycle in [the task format rule](../../../rules/project-tasks-format.md#interview-record). Create the record after workspace preparation, before the first interview question. Do not create backlog indexes before the split is agreed.

Keep these short sections:

- **Original request:** preserve the user's request and later scope changes without silently rewriting their meaning.
- **Evidence:** relevant repository-relative paths, observed behavior and official documentation links. Distinguish current behavior from intended behavior.
- **Coverage:** one row per meaningful area or scenario: reference, requirement, resolved/partial/missing/not applicable, and supporting evidence or decision. State a brief reason for non-obvious exclusions. This is a coverage view, not a score or proof of completeness.
- **Decisions:** stable references such as D1, the question, accepted answer, reason when known, and whether user-chosen or an accepted recommendation. Link changed decisions to what replaces them; do not leave two current answers.
- **Open questions:** the exact gap, why it matters and what it depends on. Distinguish user decisions, factual investigations and external blockers. Keep unaccepted proposals here.
- **Review:** completeness findings and their resolution, including any later invalidation.

Save after each accepted answer and before pausing. Update only affected entries. On resume, read the record and check relevant evidence for changes before asking the next question. An ambiguous reply stays open; silence is never agreement. If the user supplies several decisions at once, capture all of them without making them repeat their answers.

## Generate gaps from the actual change

Start with the desired outcome, success checks, scope and exclusions, actors, normal flow, data lifecycle, errors, boundaries and relevant constraints or integrations. Use the original request as a coverage source throughout the interview.

Activate extra checks only when the change involves them, for example:

- Timer/background/audio: timing, pause/resume, screen locking, interruption and recovery.
- Persistence/accounts: restart, failed writes, deletion, sign-out, ownership and account switching.
- Statistics: date boundaries, time zones, partial sessions and aggregation.
- UI: the areas in [ui-questions.md](ui-questions.md), including themes, languages and accessibility.

These examples are not exhaustive or mandatory questionnaires. Verify applicable behavior in the repository. Existing behavior can answer a question only when it also applies to the requested change; it does not automatically establish the user's intended outcome.

Walk the normal flow, then relevant states, events, failures and recovery. Check what must always hold, what happens on a trigger, what applies while a state lasts, and what happens under unwanted conditions. Use a targeted failure walkthrough or assumption challenge when uncertainty warrants it. Do not invent remote risks or add future features to achieve checklist coverage.

## Filter and choose the next question

Ask only when all three are true:

1. The runner would otherwise have to guess a consequential behavior or constraint.
2. Repository evidence, explicit earlier answers and agreed rules cannot settle it.
3. The answer changes scope, observable behavior, a meaningful technical constraint or how success is checked.

Investigate discoverable facts yourself. Leave routine implementation choices to verified project patterns and record the pattern when relevant. Never replace an unresolved product choice with an assumed default. Put later ideas outside current scope, preserving their provisional status.

Prioritize contradictions, decisions that block other decisions, high-impact unknowns, then remaining relevant gaps. Recompute after each answer rather than following a fixed questionnaire. Each question addresses one decision, even if several alternatives are offered. Use the skill's communication rules; never compress multiple decisions into a large question to save turns.

After the answer, save it and update affected coverage. Check for contradictions, new scenarios and reopened decisions. Ask for clarification if the reply is ambiguous. Do not manufacture a reason the user did not give. Existing facts, recommendations and confirmed decisions remain distinct.

## Stop and check completeness

There is no question cap. Stop only when every relevant area is supported by applicable evidence, explicitly decided, or explicitly excluded, and each requirement has a feasible way to verify it. A blocked decision is unresolved, not covered. Record it and leave affected work draft; continue independent areas where useful.

Repeated low-value questions signal a need to reassess the gaps, not proof that the interview is complete. At natural boundaries, use a short checkpoint as allowed by the skill. Pausing never authorizes unconfirmed defaults.

Run the independent interview completeness review in step 5a before splitting. Resolve factual findings through research and ask material user decisions individually. Preserve all confirmed requirements when transferring the record into backlog files. The acceptance review and per-task cold reads remain required.
