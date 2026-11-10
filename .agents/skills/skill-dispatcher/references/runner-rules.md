# Runner rules

The generic rules of the runners, by stage. Each role reads "Common" and its own section, then the same sections of the stack rules (`.agents/rules/stacks/<name>/rules.md`, one per name in the `stacks` list of `planner_dispatcher.yaml`), then the same sections of `.agents/planner-dispatcher/project-overrides.md`, which holds the facts of this project (per-file commands, layers, style). Where they differ, the project overrides win over the stack rules, and the stack rules over these. Follow these and the project files only, not rules of your own setup.

## Common

- **Scope.** Do what the task asks. Mention an unrelated problem in one line and do not act on it.
- **Fixed task contract.** Read the task's Contract and linked parent agreements before implementing. Follow the specified inputs, outputs, failures, lifecycle, paths and dependencies. Do not redesign a public contract, invent missing product behavior or expand `touches`. A necessary deviation is an unforeseen blocker: report the precise mismatch for planner reconciliation. Routine private implementation choices follow existing patterns. Missing contracts or check plans in an older task require refinement before work, not improvisation.
- **Unwired building blocks.** A planned block can have only test callers until its named consumer or assembly task merges. This is intentional, not a reason to wire it early or remove it as unused. Verify the consumer and the assembled-check owner are named. Shared code still needs the number of real users the project rules ask for; planned users alone do not qualify.
- **Git.** Never run `git add`, `git commit`, `git push` or `git checkout`. The coordinator does all git work.
- **Minimal tools.** Use file read, search and edit tools, and these shell commands only: read-only `git status`, `git diff`, `git log`, `git show`; `rg`, `grep`, `ls`, `cat`, `head`, `tail`, `wc`, `sort`, `diff`, `mkdir`; the per-file format, analyze and test commands and the code generator commands that `.agents/planner-dispatcher/project-overrides.md` names; and the `check` commands of `planner_dispatcher.yaml`. Reviewers use only read-only tools and commands. Work only inside the task's worktree, the folder your brief names.
- **No runtime or manual validation.** Do not launch an app, use emulators or devices, run integration tests, start servers, browse or automate a UI, or call external connectors to validate a task. Do not use Python, shell-edit scripts or other interpreters as helper tooling, install extra tools, or add ad hoc helper scripts. Tasks must already provide sufficient repo context and test or static checks. Missing capabilities return to planning; a tool permission grant alone does not expand task scope.
- **Denied commands.** Never bypass a denied command. Name it under "Open notes" with what it was for.
- **One simple command per check.** Run each check as its own command with literal file paths, as `cd <worktree> && <command>` (your shell may start outside the worktree). Besides that one `cd <worktree> &&`, never use a variable (`F="..."`), `;`, `&&`, `||`, `|` or `$(...)`: one chained line can be denied as a whole. To check everything the change needs in one command, run a `check` command from `planner_dispatcher.yaml`.
- **Edit with your edit tools.** Change files with the edit and write tools, never with a `python3` or `sed` script. If a command is denied, do not retry it another way through the shell. Do the work with the edit tools, or report it under "Blocked" with the exact command you needed. A denied command does not stop the run, but never skip a format, analyze or test run silently.

## Implementation

- **Plan small.** One file or concern per step. Put every new file where the task and the project rules say. If the location requires an unresolved architecture choice, report the missing decision instead of choosing a new architecture.
- **Comments.** One or two short plain sentences explaining why, only where the code is not obvious.
- **Format and analyze.** Run the per-file commands on the files you touched, by literal path. Never pass a directory.

## Tests

- Write tests only for code the task changed. Use the task's exact validation plan and cases. Run the named new or changed tests and the required regressions by literal file path. The coordinator also runs the `check` commands of `planner_dispatcher.yaml`; the task's narrower test list does not waive them.
- The plan must name required fakes and harness changes. Existing infrastructure is reused; do not invent new infrastructure during the tests stage. A missing required capability is a planning blocker. A simple task-specific fake explicitly named in the task is normal test work.
- Do not add redundant tests for pure wiring or insist that every block needs every test kind.
- Integration and device tests are planned and run in a separate workflow, outside ordinary dispatcher tasks. Do not write them or run them.

## Review checks

Flag these, with a file and a line:

- An unapproved contract change, missing named wiring or an unmet acceptance check (critical). If a contract itself must change, require planner reconciliation rather than suggesting a private redesign.
- Out-of-scope helpers or scripts, unplanned test infrastructure, or test kinds the task does not justify (general). Check the task's check plan and the reported evidence; do not infer unobserved command execution from the diff.
- After a change that applies a rule across the project (a style sweep, a rename), run your own search for the pattern and check the matches by hand. Do not rely only on the diff.
