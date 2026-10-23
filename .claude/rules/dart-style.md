---
paths:
  - "**/*.dart"
---

# Sport Timer Dart style

Rules for this project only. They add to the shared Dart rules in `~/.claude/rules/flutter/dart-core.md`. Where they differ, these win. They apply to all the code in this app, new and existing, not only to code you touch.

- Never write a function type inline in a parameter, field or return type (like `Future<Result<void>> Function() action`). Name it with a `typedef` and use the name. Use an existing Flutter typedef (`VoidCallback`, `ValueChanged<T>`) when one fits.
- A function, method, constructor or call with 3 or more parameters or arguments gets a trailing comma, one per line, for readability. This is stricter than the shared rule (more than 3).
- In every class, put the fields first, then the constructor, then the methods.
