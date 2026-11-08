# Sport Timer commit messages

Rules for this project only.

- The first line is `<type>: <description>`. The type says what the commit does, in lowercase: `feat` (new behavior), `fix` (bug fix), `refactor` (code change with no behavior change), `chore` (dependencies, tooling, config, rules), `docs` (documentation only), `style` (formatting only), `perf`, `test`, `build`.
- The description is short, in the imperative, starts in lowercase and has no final period. Example: `refactor: migrate login to a LoginViewModel`.
- Add a body after a blank line only when the reason is not obvious from the first line.
- End every commit made by an AI tool with a `Co-Authored-By: <tool> <model>` line, after a blank line, for example `Co-Authored-By: Claude Opus 5.5`, `Co-Authored-By: Codex` or `Co-Authored-By: Antigravity`. Use the model that really did the work; if it is unknown, write only the tool. Never add an email address. Do not add any attribution line to a PR description.
- Always show the full commit message when you show it to the user.
- Existing commits keep their old messages. The format applies to new commits.

## Branch names

- A new branch starts with `feat/`, `fix/` or `improve/`: `feat/` for new behavior (or planning of it), `fix/` for a bug, `improve/` for a change to something that already works. Never `chore/`, `docs/` or `refactor/`, even when the commit type is `chore` or `docs`.
- After the prefix, use a short lowercase, hyphen-separated summary, for example `feat/workout-templates`.
- The PR title starts with the same prefix as its branch: `feat: ...` for `feat/...`, `fix: ...` for `fix/...`, `improve: ...` for `improve/...`. This is separate from commit messages, which keep the types above.
- A branch for a task under `project-tasks/` (epic tasks and standalone `BUG-`/`IMP-` tasks alike) is `<type>/<id-lowercase>-<slug>`, where `type` is the task's front-matter `type` and `slug` is the task folder name without its `NN-` prefix, for example `feat/pld-01-02-bootstrap-python-package`. Free-form requests keep `<prefix>/<short-summary>`.
- Existing branches keep their names.
