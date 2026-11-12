// Checks that the AI tool setup described in CLAUDE.md ("Workflow" and "AI
// tools setup") is in place: instruction, rule and skill symlinks, only the
// planner and dispatcher skills plus the helper skills, the planner_dispatcher
// config and project files, and that every rule or skill path mentioned in the
// docs exists.
//
// Scope: files and links only. It does not judge what a rule or skill says.
// The library tests its own skills; this file only checks how they are wired.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _skills = [
  'skill-dispatcher',
  'skill-dispatcher-check',
  'skill-fl-chart',
  'skill-planner',
];

const _config = 'planner_dispatcher.yaml';

const _projectFiles = {
  '.agents/planner-dispatcher/project-overrides.md': ['## Common', '## Implementation', '## Tests', '## Review checks'],
  '.agents/planner-dispatcher/planner-notes.md': [
    '## Branches and pull requests',
    '## UI sources',
    '## Project skills',
    '## Checks',
    '## Coverage checks',
  ],
};

const _removedPaths = [
  '.codex',
  '.claude/agents',
  '.agents/roles',
  'project-tasks',
  'tool/dispatcher.dart',
  'tool/dispatcher',
  'tool/sync_master.dart',
];

const _removedMentions = [
  'skill-orchestrator',
  'skill-project-tasks',
  'skill-pr-feedback',
  '.codex/',
  'project-tasks/',
];

final _referencedPath = RegExp(
  r'\.agents/(?:rules|planner-dispatcher)/[A-Za-z0-9_./\-]+\.md'
  r'|\.agents/skills/[A-Za-z0-9_\-]+/SKILL\.md',
);

bool _isLink(String path) => FileSystemEntity.isLinkSync(path);

String _canonical(String path) => Directory(path).absolute.resolveSymbolicLinksSync();

String _lastSegment(FileSystemEntity entity) => entity.uri.pathSegments.where((s) => s.isNotEmpty).last;

/// Lists [dir] without throwing when it is missing or unreadable, and skips
/// dot-files such as `.DS_Store`. A missing folder gives an empty list; the
/// tests that need the folder check that it exists and fail with a clear reason.
List<FileSystemEntity> _entries(String dir) {
  final folder = Directory(dir);
  if (!folder.existsSync()) return [];
  try {
    return folder.listSync(followLinks: false).where((entry) => !_lastSegment(entry).startsWith('.')).toList();
  } on FileSystemException {
    return [];
  }
}

/// Returns the items of the top-level YAML list [key] of [source], written
/// either inline (`key: [a, b]`) or as one `  - item` per line.
List<String> _yamlList(String source, String key) {
  final inline = RegExp('^$key: \\[(.*)\\]\\s*\$', multiLine: true).firstMatch(source)?.group(1);
  if (inline != null) {
    return inline.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }
  final block = RegExp('^$key:\\s*\\r?\\n((?:  - .*\\r?\\n?)*)', multiLine: true).firstMatch(source)?.group(1);
  if (block == null) return [];
  return RegExp(r'^  - (.*)$', multiLine: true).allMatches(block).map((match) => match.group(1)!.trim()).toList();
}

/// Returns the value of the top-level YAML scalar [key] of [source].
String? _yamlValue(String source, String key) {
  return RegExp('^$key: (.*)\$', multiLine: true).firstMatch(source)?.group(1)?.trim();
}

void main() {
  group('instruction files', () {
    for (final name in ['AGENTS.md', 'GEMINI.md']) {
      test('$name is a symlink to CLAUDE.md', () {
        expect(_isLink(name), isTrue, reason: '$name must be a symlink');
        expect(File(name).resolveSymbolicLinksSync(), File('CLAUDE.md').resolveSymbolicLinksSync());
      });
    }
  });

  group('rules', () {
    test('.claude/rules is a symlink to .agents/rules', () {
      expect(_isLink('.claude/rules'), isTrue, reason: '.claude/rules must be a symlink');
      expect(_canonical('.claude/rules'), _canonical('.agents/rules'));
    });
  });

  group('skills', () {
    final skills = _entries('.agents/skills').whereType<Directory>().map(_lastSegment).toList()..sort();

    test('.agents/skills has only the planner, the dispatcher and the helper skills', () {
      expect(skills, _skills);
    });

    for (final skill in skills) {
      test('.claude/skills/$skill links to .agents/skills/$skill', () {
        expect(_isLink('.claude/skills/$skill'), isTrue, reason: 'missing symlink for $skill');
        expect(_canonical('.claude/skills/$skill'), _canonical('.agents/skills/$skill'));
      });
    }

    test('every .claude/skills link resolves to an existing folder', () {
      expect(Directory('.claude/skills').existsSync(), isTrue, reason: '.claude/skills is missing');
      for (final entry in _entries('.claude/skills')) {
        final name = _lastSegment(entry);
        expect(_isLink(entry.path), isTrue, reason: '.claude/skills/$name must be a symlink');
        expect(Directory(entry.path).existsSync(), isTrue, reason: '.claude/skills/$name is a broken link');
        expect(skills, contains(name), reason: '.claude/skills/$name has no folder in .agents/skills');
      }
    });
  });

  group('old setup', () {
    for (final path in _removedPaths) {
      test('$path is gone', () {
        expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound, reason: '$path must not exist');
      });
    }
  });

  group('planner-dispatcher', () {
    final config = File(_config).existsSync() ? File(_config).readAsStringSync() : '';

    test('$_config exists', () {
      expect(File(_config).existsSync(), isTrue, reason: '$_config is missing');
    });

    test('every rules entry of $_config exists', () {
      final rules = _yamlList(config, 'rules');
      expect(rules, isNotEmpty, reason: '$_config has no rules');
      for (final rule in rules) {
        expect(File(rule).existsSync(), isTrue, reason: '$_config lists $rule, which does not exist');
      }
    });

    test('the flutter stack is configured and installed', () {
      expect(_yamlList(config, 'stacks'), ['flutter']);
      expect(File('.agents/rules/stacks/flutter/rules.md').existsSync(), isTrue, reason: 'run the install command');
    });

    test('the backlog folder of $_config exists', () {
      final tasksDir = _yamlValue(config, 'tasks_dir');
      expect(tasksDir, 'docs/backlog');
      expect(Directory(tasksDir ?? '').existsSync(), isTrue, reason: '$tasksDir is missing');
    });

    for (final MapEntry(key: path, value: headings) in _projectFiles.entries) {
      test('$path has its sections in order', () {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
        final found = RegExp(r'^## .*$', multiLine: true)
            .allMatches(File(path).readAsStringSync())
            .map((match) => match.group(0)!.trim())
            .toList();
        expect(found, headings);
      });
    }
  });

  group('project layout', () {
    test('every folder under lib/features is named in the "Project layout" section of CLAUDE.md', () {
      final claude = File('CLAUDE.md').readAsStringSync();
      final section = RegExp(
        r'^## Project layout\r?\n(.*?)(?=^## )',
        multiLine: true,
        dotAll: true,
      ).firstMatch(claude)?.group(1);
      expect(section, isNotNull, reason: 'CLAUDE.md has no "## Project layout" section');

      final features = _entries('lib/features').whereType<Directory>().map(_lastSegment).toList()..sort();
      expect(features, isNotEmpty, reason: 'lib/features has no feature folders');
      for (final feature in features) {
        expect(
          section,
          contains('`$feature`'),
          reason: 'lib/features/$feature is not named as `$feature` in the "Project layout" section of CLAUDE.md',
        );
      }
    });
  });

  group('documented paths', () {
    final sources = [
      'CLAUDE.md',
      ..._projectFiles.keys,
      '.agents/skills/skill-fl-chart/SKILL.md',
    ];

    for (final source in sources) {
      test('every rule, project file or skill path in $source exists', () {
        final text = File(source).readAsStringSync();
        for (final match in _referencedPath.allMatches(text)) {
          final path = match.group(0)!;
          expect(File(path).existsSync(), isTrue, reason: '$source mentions $path, which does not exist');
        }
      });

      test('$source does not mention the removed setup', () {
        final text = File(source).readAsStringSync();
        for (final mention in _removedMentions) {
          expect(text, isNot(contains(mention)), reason: '$source must not mention $mention');
        }
      });
    }
  });
}
