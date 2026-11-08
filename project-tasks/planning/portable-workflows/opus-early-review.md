# Opus review before task splitting

Reviewer: separate Claude Opus 5.5 subagent, high effort. Read-only; no inherited interview conversation. Completed before task splitting, as requested in D42. This is not final validation under D41.

## Findings and disposition

- S1: use one resumable Python lifecycle with next-action/report operations. T3 executes host actions and CLI adapters execute subprocess actions against the same lifecycle. Incorporate into the proposed technical contracts; do not maintain a second lifecycle in skill prose.
- S2: independently run required checks, validate review results, inspect scope and do not trust exit code zero or self-reported success. Incorporate these evidence gates, but retain explicit denial reporting: passing some checks does not prove every denied action was optional or every acceptance criterion was met. Do not claim universal mechanical proof of semantic correctness.
- S3: provide one stable check entry point for workers, using a frozen approved command configuration. Incorporate as a proposed interface. This reduces command-prefix maintenance but does not create a cross-provider security sandbox; project tests/scripts execute code, and platform permissions remain authoritative.
- S4: accepted by the user in D43. Use fresh worker invocations for fix passes, preserving the task workspace, role/settings and findings; the parent thread remains unchanged. Provider-session resume is not required.
- S5: bind task-launch and model-selection authorization to the thread's one run record rather than depending on automatic discovery of every host's thread id. Incorporate with an explicit invocation token; do not treat a run id alone as permission for another thread to inherit authorization.
- S6: keep canonical task identity in the remote branch and run record; host-owned local branch names need not match. Incorporate where host constraints require it.
- S7: the reviewer recommends retaining Sport Timer's Dart validator behind generic configuration. This reverses the accepted Python replacement in D39, so it is not adopted. Keep D39 unless the user explicitly changes scope. Specify check-selection parity and avoid an unnecessarily expressive configuration language.
- S8: the reviewer proposes a tracked stdlib engine instead of an ignored virtual environment. This changes accepted installation D38 and is not adopted automatically. Investigate recreating a task workspace's environment from prepared local package artifacts and explicit invocation context before requesting a different installation design.
- G1: resolved by user decision D44: future dispatcher work uses engine-owned workspaces and provider CLIs everywhere, including under T3. Native T3 per-stage workspace management is out of scope. No unsupported native cleanup guarantee is needed.
- G2: retained local blocked work needs atomic shared local reservations; remote branch detection alone is insufficient. Incorporate local reservation and explicit release contracts, updated task-state documentation and a clear single-machine/checkout visibility limit.
- G3: no adapter can promise that planner readiness eliminates runtime permission failures. Parent/managed restrictions remain authoritative. Preflight reports capabilities and rejects an unsuitable unattended route before coding; runtime denials remain major blockers when required.
- G4: separate engine-owned setup from worker-facing checks. Prepare dependencies before agents run where supported; no automatic unplanned network workaround.
- G5: headless subprocess execution accepted in D44 for all invocation environments. Missing local Claude/Antigravity executables still prevent claiming live CLI verification; contract tests and live host-provider tests are different evidence.
- G6: keep consumer identity, trailers, commit conventions and leak-scan policy outside the generic engine. Incorporate explicit project configuration, with Sport Timer preserving its existing local rules.
- G7: implement a self-contained Python source subtree first, prove/cut over in Sport Timer, then extract to the new GitHub repository and reinstall from the published version. Add Python CI. The extraction boundary needs its own executable handoff; do not imply the old repo-only dispatcher can create or work in a new repository.
- G8: prove non-Flutter use with a tiny fixture Git consumer, fake worker/reviewer, real local bare Git remote and fake GitHub boundary. Exercise selection, reservations, validation, review, publication and cleanup without paid LLM or network dependencies. Distinguish this deterministic lifecycle test from live provider integration evidence.
- G9: local Python is 3.9.6, while stdlib TOML parsing requires 3.11+. Decide supported runtime and parser dependencies consistently with the agreed package-installation design; no silent system Python replacement.
- Retry bounds: the old pipeline has check-failure fixes as well as review fixes. Specify one explicit total repair budget instead of accidentally multiplying loops.
- Cleanup failures: after a PR exists, report publication success plus cleanup warning and retain a cleanup record. Do not create duplicate PRs or falsely claim publication failed.

## Optional ideas

- Scope checking against declared `touches` and SHA-pinned review are useful proposed contract details, not accepted reasons to ignore legitimate generated outputs or task-archive changes. Define those owned paths explicitly.
- Recommend from configured role/complexity policy filtered by actually available models; do not infer host providers from Python PATH or silently replace an unavailable requested model.
- Reuse the same execution abstraction for interview and task cold readers while retaining separate fresh review contexts.

## Next steps

Resolve workspace and installation feasibility, obtain any consequential user decisions, define the concrete contracts and verification, then rerun interview completeness review before proposing the task split. Preserve accepted scope unless the user approves a change. Final Opus validation is still required after the plan is written.
