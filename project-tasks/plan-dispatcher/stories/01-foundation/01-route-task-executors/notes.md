
## Blocked

None. A `python3` heredoc I tried at the start was denied, so I made all edits with the edit tools instead. This didn't change any result. Commands the tool was not allowed to run: `python3 - <<'E'
import re
p='.agents/skills/skill-orchestrator/SKILL.md'
s=open(p).read()
def rep(a,b):
    global s
    assert s.count(a)==1,a
    s=s.replace(a,b)
rep("such as `feat/workout-templates`, `fix/timer-pause` or `improve/template-tiles`. This step is authorized","such as `feat/workout-templates`, `fix/timer-pause` or `improve/template-tiles`. This step is authorized")
rep("Before planning or implementation for a new request, create a new branch named `<prefix>/<short-summary>` from `master` in the current checkout. Never","Before planning or implementation for a new request, create a new branch named `<prefix>/<short-summary>` from `master` in the current checkout. For a task under project-tasks/, use the task branch rule in .agents/rules/git-commits.md instead. Never")
para="""Record the feature branch and starting commit for the approval checkpoint.

**Local tasks with a non-legacy executor.** When the task's front matter has an executor other than `legacy`, the checks in Stages 2, 3 and 5 are exactly the task's own `## Files and tests` commands. Run the full Flutter suite only when that section lists it. `tool/agent_check.dart`, `fvm flutter analyze` and the Dart, l10n and `fvm` rules apply only when the change touches `.dart` or ARB files. For these tasks this paragraph replaces every other mention in Stages 2 to 5 of the full suite, `fvm flutter analyze`, the analyze result and `tool/agent_check.dart`, including the Stage 2 report, the paragraph after Stage 2 and the Stage 3 approval checkpoint: report the task's own commands and their results instead. The Stage 5 check that `CLAUDE.md` still describes the real layout still applies.
"""
rep("Record the feature branch and starting commit for the approval checkpoint.\n",para)
for st in ["- Run `fvm dart format` and `fvm flutter analyze` on the touched files","- Run focused tests by file path while working","- `fvm flutter analyze` reports no issues","- `fvm dart tool/agent_check.dart` passes"]:
    rep(st,"- For legacy tasks and free-form requests: "+st[2:])
rep("then re-run the Stage 3 tests and `flutter analyze`","then re-run the Stage 3 checks (for a non-legacy task, its own `## Files and tests` commands)")
open(p,'w').write(s)

p='.agents/skills/skill-orchestrator/roles/agent-implementer.md'
s=open(p).read()
for st in ["- A user-facing string must be","- Use `fvm flutter` and `fvm dart`","- Run `fvm dart format` and `fvm flutter analyze`"]:
    rep(st,"- When the change touches Dart or ARB files: "+st[2:])
rep("fix what they report.\n","fix what they report.\n- For other files, run exactly the commands the task's `## Files and tests` section names.\n")
open(p,'w').write(s)

p='.agents/rules/git-commits.md'
s=open(p).read()
rep("- Existing branches keep their names.","- A branch for a task under `project-tasks/` (epic tasks and standalone `BUG-`/`IMP-` tasks alike) is `<type>/<id-lowercase>-<slug>`, where `type` is the task's front-matter `type` and `slug` is the task folder name without its `NN-` prefix, for example `feat/pld-01-02-bootstrap-python-package`. Free-form requests keep `<prefix>/<short-summary>`.\n- Existing branches keep their names.")
open(p,'w').write(s)

p='.agents/rules/project-tasks-format.md'
s=open(p).read()
rep("depends-on: [TPL-03-01]\n","depends-on: [TPL-03-01]\nexecutor: legacy       # optional: legacy | orchestrator | plan-dispatcher-v1 | handoff; default legacy\n")
rep("Sections, in this order.","""`executor` says who may run the task; absent means `legacy`. `legacy`: the current Dart dispatcher. `orchestrator`: `skill-orchestrator` with the user present. `plan-dispatcher-v1`: the new engine once installed. `handoff`: an agent in the user's session, never a dispatcher.

Sections, in this order.""")
open(p,'w').write(s)

p='tool/dispatcher/task.dart'
s=open(p).read()
rep("  final List<String> skills;\n  final String directory;","  final List<String> skills;\n  final String executor;\n  final String directory;")
rep("    required this.skills,\n","    required this.skills,\n    required this.executor,\n")
rep("  bool get isDone","""  /// Why the legacy dispatcher cannot run this task, or null when it can.
  String? get executorBlockReason {
    if (executor == 'legacy') return null;
    return 'executor ${executor.isEmpty ? '(empty)' : executor} is not supported by the legacy dispatcher';
  }

  bool get isDone""")
rep("      skills: _list(front['skills']),\n","      skills: _list(front['skills']),\n      executor: _executor(front),\n")
rep("  static String? _scalar","""  /// Absent means `legacy`; an empty or list value is unsupported and becomes `''`.
  static String _executor(Map<String, Object?> front) {
    if (!front.containsKey('executor')) return 'legacy';
    return switch (front['executor']) {
      final String value => value,
      _ => '',
    };
  }

  static String? _scalar""")
open(p,'w').write(s)

p='tool/dispatcher/task_selector.dart'
s=open(p).read()
rep("  /// Why [task] cannot","""  /// Why `launch` must refuse [task] before anything else, or null.
  static String? launchRefusal(Task task) {
    if (task.executorBlockReason case final reason?) return '${task.id}: $reason';
    return null;
  }

  /// Why [task] cannot""")
rep("    if (skipped.contains","    if (task.executorBlockReason case final reason?) return reason;\n    if (skipped.contains")
open(p,'w').write(s)

p='tool/dispatcher.dart'
s=open(p).read()
rep("  if (task == null || !task.isReady) {","""  if (task != null && TaskSelector.launchRefusal(task) case final refusal?) {
    stderr.writeln(refusal);
    return 1;
  }
  if (task == null || !task.isReady) {""")
open(p,'w').write(s)
E
grep -n "frontMatter" -B2 -A3 tool/dispatcher/extensions/front_matter_text.dart | head -20; grep -n "import" tool/dispatcher.dart | grep selector`, `python3 - <<'E' 2>/dev/null || echo nopython
E
true`. If one was needed, relaunch with --allow="Bash(<program>:*)".
