# TASK 1.4: Connect recording to timer progress

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](03-add-activity-repository.md).

## Goal

Connect recording to timer progress. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Allocate a new run identifier for each fresh start. Pause/resume retains it.
- Reconcile all newly completed scheduled phases on progress updates and relevant lifecycle transitions, including pause, stop/leave, and natural completion.
- Handle several crossed boundaries in a delayed callback without losing or duplicating phases.
- Preserve logical completion dates across midnight, pauses, and delayed callbacks. Validate the approach to timezone/clock changes while a run is active.
- Exclude preparation, zero-duration omitted phases, pauses, and unfinished work/rest from statistics.
- Keep persistence work independent of the timer page's lifetime so leaving the page does not cancel already-required writes. Do not rely on asynchronous disposal alone to flush data.
- Use the existing background execution mechanism; the database itself does not keep the app alive. Reconcile elapsed completions when execution resumes.
- Record known run termination and pause metadata without marking an unfinished phase complete.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
