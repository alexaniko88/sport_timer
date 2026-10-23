---
paths:
  - "**/*.dart"
---

# Sport Timer Dart style

Rules for this project only. They add to the shared Dart rules in `~/.claude/rules/flutter/dart-core.md`. Where they differ, these win. They apply to all the code in this app, new and existing, not only to code you touch.

- Never write a function type inline in a parameter, field or return type (like `Future<Result<void>> Function() action`). Name it with a `typedef` and use the name. Use an existing Flutter typedef (`VoidCallback`, `ValueChanged<T>`) when one fits. Put the typedef at the top of the file that uses it. Move it to `lib/core/typedefs.dart` only when it is generic and several features share it.
- A function, method, constructor or call with 3 or more parameters or arguments gets a trailing comma, one per line, for readability. This is stricter than the shared rule (more than 3).
- An enum with 3 or more values gets one value per line with a trailing comma. A list, set or map with 3 or more entries does the same when it does not fit on one line.
- In every class, put the fields first, then the constructor, then the methods.
- Use pattern matching wherever it makes the code easier to read, not only in a `switch`: switch expressions, `if-case`, object and record patterns with destructuring (`case Failure(:final error)`), `when` guards, and `||` patterns to share a body between cases. Fall back to a plain `switch`, `if` or manual checks only when the pattern version becomes hard to read. With only two outcomes (including a sealed class with two cases like `Result`), use `if`, `if-case` or a ternary instead of a `switch`. Use a `switch` from three outcomes up.
- Log with `debugPrint`, never `print`. For a long message (a stack trace, a full error or a big object) use `log` from `dart:developer`, because the platform log can cut a very long line.
