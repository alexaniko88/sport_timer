import 'extensions/front_matter_text.dart';
import 'extensions/markdown_sections.dart';

/// One task folder of `project-tasks/`, as described in
/// `.agents/rules/project-tasks-format.md`.
class Task {
  final String id;
  final String status;
  final String type;
  final String? complexity;
  final List<String> dependsOn;
  final List<String> touches;
  final List<String> skills;
  final String directory;
  final String title;
  final String text;

  const Task({
    required this.id,
    required this.status,
    required this.type,
    required this.complexity,
    required this.dependsOn,
    required this.touches,
    required this.skills,
    required this.directory,
    required this.title,
    required this.text,
  });

  bool get isDone => directory.contains('/done/');

  bool get isReady => status == 'ready' && !isDone;

  /// Where the task folder lives once it is closed: `<parent>/done/<name>`.
  String get doneDirectory => '${directory.substring(0, directory.lastIndexOf('/'))}/done/${directory.split('/').last}';

  String get indexPath => '$directory/index.md';

  String get slug => directory.split('/').last.replaceFirst(RegExp(r'^\d+-'), '');

  /// `<type>/<id-lowercase>-<slug>`, for example `feat/tpl-03-02-save-template`.
  String get branch => '$type/${id.toLowerCase()}-$slug';

  /// The acceptance checkboxes, one trimmed line each.
  List<String> get acceptance {
    return text
        .section('Acceptance')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('- ['))
        .toList();
  }

  /// Returns null when [path] is not a task `index.md` (an epic or story has no `id`).
  static Task? tryParse({required String path, required String text}) {
    if (!path.endsWith('/index.md')) return null;
    final front = text.frontMatter;
    final id = _scalar(front['id']);
    if (id == null) return null;
    return Task(
      id: id,
      status: _scalar(front['status']) ?? 'draft',
      type: _scalar(front['type']) ?? 'feat',
      complexity: _scalar(front['complexity']),
      dependsOn: _list(front['depends-on']),
      touches: _list(front['touches']),
      skills: _list(front['skills']),
      directory: path.substring(0, path.length - '/index.md'.length),
      title: text.firstHeading,
      text: text,
    );
  }

  static String? _scalar(Object? value) => value is String && value.isNotEmpty ? value : null;

  static List<String> _list(Object? value) => switch (value) {
        final List<String> list => list,
        final String text when text.isNotEmpty => [text],
        _ => const [],
      };
}
