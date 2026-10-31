# Sport Timer commit messages

Rules for this project only.

- The first line is `<type>: <description>`. The type says what the commit does, in lowercase: `feat` (new behavior), `fix` (bug fix), `refactor` (code change with no behavior change), `chore` (dependencies, tooling, config, rules), `docs` (documentation only), `style` (formatting only), `perf`, `test`, `build`.
- The description is short, in the imperative, starts in lowercase and has no final period. Example: `refactor: migrate login to a LoginViewModel`.
- Add a body after a blank line only when the reason is not obvious from the first line.
- End with the `Co-Authored-By` trailer from the session instructions.
- Existing commits keep their old messages. The format applies to new commits.

## Branch names

- A new branch starts with `feat/`, `fix/` or `improve/`: `feat/` for new behavior (or planning of it), `fix/` for a bug, `improve/` for a change to something that already works. Never `chore/`, `docs/` or `refactor/`, even when the commit type is `chore` or `docs`.
- After the prefix, use a short lowercase, hyphen-separated summary, for example `feat/workout-templates`.
- Existing branches keep their names.
