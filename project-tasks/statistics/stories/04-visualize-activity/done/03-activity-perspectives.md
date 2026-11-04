# TASK 4.3: Show activity perspectives

Story: [Visualize activity](../index.md)

Epic: [Statistics](../../../index.md)

Status: Done on `feat/activity-perspectives`; merge pending.

## Goal and scope

Add Rounds, Work vs rest, and Total time to the Work time chart experience, following the shared [story decisions](../index.md). Consistency is covered separately.

## Dependencies

[Task 4.1](01-prepare-chart-data.md) and [Task 4.2](02-chart-view-and-controls.md).

## Acceptance criteria

- Each perspective shows correct daily or monthly values, totals, units and selectable exact values for each period.
- Work vs rest uses stacked bars and reveals both values on selection; its components are distinguishable without color alone. Total time equals work plus rest.
- Zero, future, empty and error states follow the story; the experience remains readable and accessible on supported devices.

## Validation and context

Test conversions, selection, totals, accessibility and both themes. Follow `skill-fl-chart` for applicable chart work, adapting its tooltip pattern to the agreed shared summary. Refresh affected UI snapshots and update their index; see [visual context](../index.md#dependencies-and-visual-context).

## Completion evidence

Rounds, work vs rest, and total time are available alongside work time, with period and selected values, accessible controls, and a labelled stacked chart.

Validation: full Flutter suite passed (431); focused tests and light/dark snapshots passed; formatting and analysis passed. Review passed after correcting the zero-rest segment outline.
