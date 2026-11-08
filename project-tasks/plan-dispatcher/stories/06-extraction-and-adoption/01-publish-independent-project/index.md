---
id: PLD-06-01
status: draft
type: feat
complexity: medium
executor: handoff
depends-on: [PLD-05-03]
touches:
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/01-publish-independent-project/index.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/01-publish-independent-project/index.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/01-publish-independent-project/notes.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/index.md
  - docs/tasks/plan-dispatcher/index.md
skills: []
---

# Publish the independent public PlanDispatcher project

Story: [Independent release and consumer adoption](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Create the public GitHub repository `alexaniko88/plan-dispatcher` with one fresh commit holding only the generic package, tag it `v0.1.0` and publish a GitHub release. Then open a Sport Timer PR that archives this task with the release evidence, so PLD-06-02 can adopt the exact commit.

## Context

- This is a **handoff**: an agent runs it in the user's session when the user asks. No dispatcher selects it. After PLD-05-02 this task lives under `docs/tasks/`; the paths here already use that root.
- Source: the `tool/plan_dispatcher/` subtree of Sport Timer `origin/master` HEAD at handoff time, after checking that PLD-05-03 is archived there (checklist step 1). Any later source fix simply lands on master first and is picked up the same way. Call it `SOURCE_SHA`.
- Cross-task shapes are owned by [contracts.md](../../../contracts.md) and are not restated here: "Package layout" (subtree contents, wheel build), "Extraction and adoption proof", "Runner boundary for this epic", and the shared boundary pattern file under "Planned tests and invocation". Prerequisite: [PLD-05-03](../../05-sport-timer-cutover/03-retire-dart-validator/index.md). Shared requirements: R1, R16, R17.

## Contract

Target repository (new, not Sport Timer files): `https://github.com/alexaniko88/plan-dispatcher`, public, default branch `main`, one initial commit, annotated tag `v0.1.0`, GitHub release `v0.1.0`.

Target tree (exactly): every file of `SOURCE_SHA:tool/plan_dispatcher/`, at the repository root and unchanged (including `LICENSE`, `src/plan_dispatcher/_vendor/tomli/LICENSE` and `PROVENANCE.md`), plus three new files:

- `AGENTS.md` (short): what the package is; `python3 tests/run_tests.py` runs the offline suite; stdlib only, Python 3.9 or newer, macOS first; no project-specific rules in the package; consumer rules live in each consumer's `.plan-dispatcher/config.toml` and instruction files.
- `.gitignore`: `__pycache__/`, `dist/`, `build/`, `*.egg-info/`.
- `.github/workflows/python.yml`, exactly:

  ```yaml
  name: python
  on:
    pull_request:
    push:
      branches: [main]
  jobs:
    test:
      runs-on: macos-latest
      strategy:
        matrix:
          python: ["3.9", "3.13"]
      steps:
        - uses: actions/checkout@v7.0.1
        - uses: actions/setup-python@<tag>
          with:
            python-version: ${{ matrix.python }}
        - run: python tests/run_tests.py
  ```

  `<tag>` is the exact `actions/setup-python@…` tag in Sport Timer's `.github/workflows/plan-dispatcher.yml` at `SOURCE_SHA` (pinned by PLD-01-02), so both repositories use the same action versions. The Sport Timer parity step is not copied: its files are consumer files and do not exist in the target.

- `LICENSE`: MIT. Its text is created in the source by PLD-01-02 and copied unchanged here, so the holder line is settled there.
  - `LICENSE` holder line is `Copyright (c) 2026 alexaniko88`, set in PLD-01-02 and copied unchanged (user decision D54).
- Commit identity and message:
  - Every commit in `alexaniko88/plan-dispatcher` uses the author email `40612984+alexaniko88@users.noreply.github.com` (set with `git config user.email` in the target clone before the first commit) and has no `Co-Authored-By` trailer (user decision D55: the global personal-repo and no-AI-attribution rules apply there).
  - Message first line: `feat: initial PlanDispatcher release`.

Handoff log (local, never committed): `~/Library/Caches/PlanDispatcher/handoff/plan-dispatcher/log.md`. It records `SOURCE_SHA`, the preflight output, each finished step and the target commit, so a stopped handoff can continue. The work folder is `~/Library/Caches/PlanDispatcher/handoff/plan-dispatcher/work/`. Both paths are fixed, so a later session finds them.

Source completion (Sport Timer): branch `feat/pld-06-01-publish-independent-project` from current `origin/master`. It moves this task into `done/` with `status: done` and every Acceptance box ticked (`- [x]`, each backed by its `## Evidence` line), adds one `../` to every relative link that leaves the task folder, rewrites **every** link to this task to the `done/` path (story index: task list, handoff sentence and the R1, R16 and R17 rows; epic index: every coverage row that links it, found with `git grep -n "01-publish-independent-project/index.md" -- docs/tasks/plan-dispatcher/index.md docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/index.md`), and adds `notes.md` with exactly this section, which PLD-06-02 reads:

```markdown
## Release

- repository: https://github.com/alexaniko88/plan-dispatcher
- tag: v0.1.0
- commit: <40-hex target commit>
- source: <SOURCE_SHA>
```

plus `## Evidence` (one line per criterion) and `## Steps` (copied from the handoff log, with every home-folder path written as `~/…` and every temp path as `<tmp>/…`). Before committing, run `.plan-dispatcher/venv/bin/pd check --skip-build docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/01-publish-independent-project/notes.md` (explicit-path form, every line counts as added), whose added-line scans include the local-path pattern; any match is fixed by hand before the commit. Commit message, following `.agents/rules/git-commits.md`: first line `chore: record plan-dispatcher v0.1.0 release`, a blank line, and the `Co-Authored-By: <tool> <model>` line. PR title `feat: publish independent PlanDispatcher project`. The branch is pushed and the PR opened after the second approval; it is never merged by the agent. Its merge completes this task for PLD-06-02.

## Behavior

Handoff checklist. Each step appends a line to the handoff log when it finishes. Run steps 4 and 5 with `PYTHONDONTWRITEBYTECODE=1` in the environment.

1. **Preflight** (Sport Timer checkout root):
   - `git fetch origin`; `gh auth status`.
   - `git cat-file -e origin/master:docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/done/03-retire-dart-validator/index.md` must succeed (PLD-05-03 is merged); otherwise stop and report. Then `SOURCE_SHA = git rev-parse origin/master`, recorded in the log; a resumed handoff reuses the logged value.
   - `gh repo view alexaniko88/plan-dispatcher --json name,isEmpty,visibility,owner`:
     - does not exist: continue at step 2;
     - exists, public, `isEmpty: true`, and the log records "created": continue at step 4;
     - exists with `main` whose head equals the target commit in the log: continue at step 7;
     - anything else (other content, private, no log entry, or a `v0.1.0` tag on another commit in `git ls-remote --tags https://github.com/alexaniko88/plan-dispatcher.git`): stop and report. Never overwrite, force-push or delete.
   - Write the preflight output to the log.
2. **Approval.** Show the user the target file list, the commit message, the repository settings (public, MIT, `main`) and the tag. One approval covers creating the repository, the commit, the push, the tag and the release. The source completion commit and PR are approved separately in step 10.
3. **Create.** `gh repo create alexaniko88/plan-dispatcher --public --description "Portable planner and dispatcher for AI coding agents"` (no clone, template or license generation). Log "created".
4. **Export.** Remove and recreate the work folder (only when the log has no target commit yet). From the Sport Timer root: `git archive <SOURCE_SHA> tool/plan_dispatcher | tar -x -C <work> --strip-components=2`. In `<work>`: `git init -b main`, write the three new files, then `git config user.name alexaniko88` and `git config user.email 40612984+alexaniko88@users.noreply.github.com` (repo-local).
5. **Verify before commit** (in `<work>`):
   - `python3 tests/run_tests.py` passes.
   - `python3 -m venv <work>/../venv`; `python3 -m pip wheel --no-deps --no-build-isolation -w <work>/../dist <work>`; `<work>/../venv/bin/python -m pip install --no-index --no-deps <work>/../dist/plan_dispatcher-0.1.0-py3-none-any.whl`; `<work>/../venv/bin/pd --help` exits 0; `unzip -l <wheel>` lists `plan_dispatcher/resources/skills/skill-planner/SKILL.md` and `plan_dispatcher/resources/skills/skill-dispatcher/SKILL.md`; `unzip -p <wheel> '*/METADATA'` shows `Version: 0.1.0`. The wheel and venv live outside `<work>`; delete both afterward.
   - `git add -A`, then the tree check: `diff <(git ls-files | sort) <( (git -C <sport-timer-root> ls-tree -r --name-only <SOURCE_SHA> tool/plan_dispatcher | sed 's#^tool/plan_dispatcher/##'; printf '%s\n' AGENTS.md .gitignore .github/workflows/python.yml) | sort)` prints nothing.
   - Scan: `git grep -n -I -i -E -f <sport-timer-root>/test/tool/fixtures/plan_dispatcher_boundary_patterns.txt -- . ':!LICENSE' ':!src/plan_dispatcher/_vendor'` prints nothing. `git grep -n -I -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}'` shows only the vendored tomli notice and `users.noreply.github.com` addresses.
6. **Commit, push and wait for CI.** `git commit`, log the target commit, `git remote add origin https://github.com/alexaniko88/plan-dispatcher.git`, `git push origin main`. Then wait for the first `python` workflow run on that commit: `RUN=$(gh run list --repo alexaniko88/plan-dispatcher --workflow python --commit <commit> --limit 1 --json databaseId --jq '.[0].databaseId')` (repeat the lookup until it returns an id, at most 10 tries 30 s apart), then `gh run watch "$RUN" --repo alexaniko88/plan-dispatcher --exit-status`. Both matrix jobs (3.9 and 3.13) are in that run. A failed run stops the handoff before step 7: no tag or release is made, the log records the run URL, and the fix goes into the Sport Timer source first, through a normal planned change on master, because the public history must not be rewritten. The handoff then resumes at step 4 with `SOURCE_SHA` = the new `origin/master` HEAD (log it), exports the tree again over the work folder's checkout of `main`, and adds one fix commit `fix: <short description>` on top; steps 5 and 6 repeat, and the tag goes on the first commit whose run passes.
7. **Tag and release.** Each part is skipped when it already exists on the right commit:
   - Tag: if `git ls-remote origin refs/tags/v0.1.0^{}` is empty, `git tag -a v0.1.0 -m "v0.1.0" <commit>` and `git push origin v0.1.0`; if it equals the commit, skip; otherwise stop.
   - Release: if `gh release view v0.1.0 --repo alexaniko88/plan-dispatcher` fails, `gh release create v0.1.0 --repo alexaniko88/plan-dispatcher --verify-tag --title v0.1.0 --notes "First public release."`; otherwise skip.
8. **Check GitHub.** `gh repo view alexaniko88/plan-dispatcher --json visibility,licenseInfo,defaultBranchRef` shows `PUBLIC`, MIT and `main`; `git ls-remote origin refs/tags/v0.1.0^{}` equals the commit; `gh release view v0.1.0 --repo alexaniko88/plan-dispatcher --json tagName,isDraft` shows `isDraft: false`. Log the outputs.
9. **Remove the work folder** after step 8 passes; keep the log. On failure keep both and report their paths.
10. **Source completion PR.** Show the Sport Timer commit message, files and PR title; after approval, create the branch, commit, push it and open the PR as described in Contract.

The source package stays in Sport Timer until PLD-06-02 succeeds. Never rewrite history, force-push, or merge.

## Decisions

- Fresh public history and MIT license, no Sport Timer history (D47, approved acceptance R17).
- The release is pinned by commit, and the commit is written into this task's archived notes, so adoption never trusts a tag alone.
- The source completion PR is the dependency gate, so cross-repository evidence is reviewed before adoption.

## Out of scope

- Transferring Sport Timer history, tasks, config, Firebase files or private data.
- Publishing to PyPI, overwriting an existing repository or tag, merging any PR.
- Any app, UI or localization change.

## Classification rehearsal

Read-only, run once before step 2 so acceptance 3 is proven even though the real target does not exist yet. It applies the step 1 rules to inputs whose answer is known:

1. `gh repo view alexaniko88/sport_timer --json name,isEmpty,visibility,owner` (exists, not empty, no log entry) must classify as "stop".
2. In a temp folder: `git init --bare r.git`, push one commit to it, tag a different commit `v0.1.0` and push the tag; `git ls-remote --tags <tmp>/r.git` shows `v0.1.0` on a commit other than `main` and must classify as "stop". Delete the temp folder afterward.
3. `gh repo view alexaniko88/plan-dispatcher` before step 3 must fail (does not exist) and classify as "continue at step 2".

Record each input, the observed output and the classification in the log.

## Files and tests

Sport Timer files: only this task's folder move, `notes.md`, and the links in the story and epic indexes (see `touches`). Target files are listed in Contract and are not Sport Timer paths.

Commands:

- Sport Timer root, before export: `.plan-dispatcher/venv/bin/pd check` and `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`.
- Target work folder: the commands in checklist steps 5 and 8.

## Acceptance

- [ ] When the handoff publishes the target, then a public MIT repository holds a fresh initial commit (plus only `fix:` commits exported from the source if the first CI run failed) with only the target tree, and tag `v0.1.0` and its release point to that commit. Check: checklist step 5 (suite, wheel install, tree check, scan) and step 8 (`gh repo view`, `git ls-remote`, `gh release view`) outputs, copied into `notes.md` `## Evidence`.
- [ ] When the handoff completes in Sport Timer, then its PR archives this task under `done/` with the `## Release` section filled. Check: `gh pr view <number> --json files` lists only the `touches` paths, and the `## Release` section has repository, tag, a 40-hex commit and the source SHA.
- [ ] When the target already holds other content or a different `v0.1.0`, then the handoff stops before writing anything. Check: the classification rehearsal below, run before step 2, with its output in `notes.md` `## Evidence`.
- [ ] When the first CI run on the target commit is red, then no tag or release exists. Check: step 6 `gh run watch --exit-status` output in the log; step 7 runs only after exit 0.
