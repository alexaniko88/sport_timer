# Opus review of the proposed split

Separate fresh Claude Opus 5.5 subagent, high effort, completed under D45. Verdict: revise before detailed task files. Six-story shape is sound; accepted D38/D39/D43/D44 remain intact. No code was changed by the reviewer.

## Required technical corrections

1. Replace portable skill assets, retire the Dart dispatcher/model definitions and update corresponding AI-setup assertions atomically. Do not leave dead runner code or unmanaged old roles in a managed skill folder. Separate validator retirement behind parity. Give the task-format contract one canonical source with project-owned pointers.
2. Assign portable planning-branch/workspace preparation to a named command/task before retiring the old synchronizer. Ask separately whether merged-branch cleanup is still wanted.
3. Own an explicit read-only planner-review command using the planning checkout and shared CLI adapters. Remove the unnecessary planner-assets dependency on task publication.
4. Define developer and frozen run-bound checker modes. Cover check order, added-line failure/advisory scans, optional build groups and explicit-file semantics. Keep Sport Timer configuration/parity fixtures outside the extractable generic source subtree. Use one check-selection case table read by both old/new tests.
5. Bootstrap gate must enforce canonical branch names for orchestrated local tasks, document executor metadata, and name explicit Python checks. Resolve offline bootstrap before running Python tasks. The review suggests no external runtime/test dependencies: stdlib unittest, a defined restricted front-matter parser, stdlib tomllib or a vendored licensed tomli fallback on older Python.
6. Keep execution clones outside repository ancestors to prevent active-checkout instructions/indexing from leaking into workers. Use per-user cache locations keyed by repository; keep paths only in ignored state. Canonical run/reservation state belongs under the Git common directory so linked worktrees share it.
7. Backlog-root migration is orchestrator-only, with no active/blocked runs, its own archive at the new root and pending-task links/scopes updated. Extraction requires a non-dispatchable handoff executor and a Sport Timer completion PR recording the destination release/commit so adoption's dependency resolves. Name executor ownership for every cutover task.
8. Add explicit command/port ownership: pd entry point, doctor/auth/identity, GitHub lookup needed by selection, CLI model availability/recommendations and both local/pinned-release install sources. Split setup/restore from explicit update/rollback; revised count becomes 20 if no other resizing is needed.
9. Include a live opt-in Codex worker/reviewer fixture smoke at cutover, with local remote/fake GitHub, to test the actual check/sandbox route. Keep Claude/Antigravity live evidence explicitly unverified when CLIs are absent. Deterministic fixtures alone do not establish live sandbox compatibility.

These are findings to reconcile with repository evidence and the design, not automatic user approval of changed product scope. No extra review is required merely to apply a small factual correction; the requested final whole-plan review remains outstanding.

## User decisions still needed

- U1: resolved by D46: omit merged-local-branch sweeping; task-clone cleanup remains automatic. Assign portable planning workspace preparation before retiring the synchronizer.
- U2: resolved by D47: fresh initial commit, with required MIT notices and an exported-tree leak scan; no Sport Timer history transfer.
- U3: accepted by D48: explicit approved handover of a saved blocked run, with fresh model/provider approval; no automatic thread discovery or takeover of active work. Keep this a small extension of existing resume validation.
- U4: resolved by D50: temporary fixture created per verification run and removed afterward; no permanent GitHub repository.

Optional folding of skill-project-tasks into the planner is not required by the current scope and is not adopted automatically.

## Detailed contracts to settle in task writing

Release keeps work versus cleanup deleting it; trusted run context location; adapter read-only policy; supported test host versus supported user OS; local source/runtime version mismatch diagnostics; exact Antigravity soft-denial parsing. Keep command-level permissions distinct from task policy and independent evidence.
