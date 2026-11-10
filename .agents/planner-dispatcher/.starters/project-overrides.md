# Project overrides for the runners

The rules of this project, by stage. Each role reads "Common" and its own section, after the generic `.agents/skills/skill-dispatcher/references/runner-rules.md` and the rules of the stacks listed in `planner_dispatcher.yaml`. Where they differ, this file wins.

Replace each `<...>` with the project's choice, and remove a line that does not apply. The stack rules leave these choices to the project, so a line left as `<...>` makes the runners guess.

## Common

Facts every stage needs.

- **Per-file commands.** Format with `<format command> <path>`, analyze with `<analyze command> <path>` and test with `<test command> <path>`, always with a literal path.
- **Layers.** <The folders and what each may import, for example feature folders with domain, data and presentation, or "no fixed layers".>
- **State management.** <The one approach the project uses, for example a package or plain notifiers, and how state classes are written.>
- **Strings.** <How user-facing strings are added: the localization files and the command that generates the code, or how hardcoded text is marked.>
- **Generated code.** <The generators the project uses and the command for each, or "none".>

## Implementation

Where new code goes and how it is written in this project.

- **New code.** <Where each kind of file goes: pages, components, state, repositories, models, extensions.>
- **Shared UI.** <The theme, tokens and shared components to use instead of raw values, or "no UI".>
- **Dependencies.** <Whether a task may add a package, and how versions are pinned.>

## Tests

Where tests go, how they are named and which fakes to use.

- **Location.** <Where each test kind lives, for example tests mirror the source folders.>
- **Test doubles.** <Hand-written fakes or the mocking package, and where the shared ones are.>
- **Visual snapshots.** <The snapshot tool, the test file and the per-file update command, or "none".>

## Review checks

What the reviewer flags in this project, each with a severity.

- <A rule of this project that review must check, with critical, general or minor.>
