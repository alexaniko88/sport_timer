# Suggested Flutter lines for the project overrides

Optional style lines that many projects use but that are a choice, not a rule for every Flutter project. No role reads this file. To use a line, copy it into the named section of `.agents/planner-dispatcher/project-overrides.md`, where it then wins over the stack rules.

## Common

- **Class layout.** Fields first, then the constructors, then the methods. Apply it to new classes and to classes you rewrite; do not reorder untouched ones. (This is the opposite of the `sort_constructors_first` lint; do not use both.)
- **Two-case result types.** A sealed type with only 2 cases (a `Result` or an `Either`) is a 2-way choice: use `if-case` or its `fold`, never a `switch`.

## Implementation

- **Named parameters.** A new or changed function with 2 or more parameters takes named parameters (`{required ...}`), except where a fixed API signature or a callback type decides.
- **Bool flags.** A new `bool` parameter is named, never positional (the `avoid_positional_boolean_parameters` lint checks it), and defaults to `false`. When the behavior is on by default, name the flag for the opt-out (`skipSync`, not `shouldSync = true`).
- **Pass the object.** When several calls pass values read from one object, pass the object and read the fields inside.
- **Function types.** Never write a function type inline in a parameter, field or return type. Use an existing typedef (`VoidCallback`, `ValueChanged<T>`) or declare a named `typedef`.
- **Extensions.** A helper that works on one type (its first argument is the thing it works on, or it maps one type to another) is an extension on that type, one per file in an `extensions/` folder, not a top-level function.
- **Read once.** When one scope reads the same value from `context` (localizations, theme) more than once, read it once into a local `final` at the top.
- **Names.** Never name a variable or parameter `async`. New boolean names start with `is`, `has`, `should`, `can` or `will`.
- **Throw.** Never write `throw switch (...)`: use an `if-case` and a plain `throw`.
- **Shared values.** A new shared token or widget needs 2 or more users; until then it stays local.

## Tests

- **FakeAsync name.** Name the `FakeAsync` argument `fake`, not `async`.
- **Semantics files.** Semantics checks go in their own test file next to the widget test, never inside the widget test.

## Review checks

- A new function with 2 or more positional parameters, an inline function type, or a top-level helper that should be an extension (minor).
- A new shared token or widget with only one user (general).
