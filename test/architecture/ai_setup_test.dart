// Checks that the AI tool setup described in CLAUDE.md ("AI tools setup") is
// in place: instruction and skill symlinks, role files with frontmatter, one
// Codex model carrier per role, and that every rule or role path mentioned in
// the docs exists.
//
// Scope: files and links only. It does not judge what a rule or role says.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _modelPairs = {'gpt-6.1-sol': 'opus', 'gpt-6.1-terra': 'sonnet'};

const _rolesDir = '.agents/skills/skill-orchestrator/roles';

const _efforts = {'high', 'medium'};

const _accessModes = {'read-only', 'edit'};

const _sandboxByAccess = {'read-only': 'read-only', 'edit': 'workspace-write'};

const _forbiddenMentions = ['.claude/agents', '.agents/roles', '~/.claude/agents'];

final _referencedPath = RegExp(
  r'\.agents/(?:rules|skills/skill-orchestrator/roles)/[A-Za-z0-9_.\-]+\.md'
  r'|\.agents/skills/[A-Za-z0-9_\-]+/SKILL\.md'
  r'|\.codex/agents/[A-Za-z0-9_\-]+\.toml',
);

final _relativeSkillLink = RegExp(r'\.\./(skill-[A-Za-z0-9_\-]+)/SKILL\.md');

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

List<String> _names(String dir, String extension) {
  return _entries(dir)
      .whereType<File>()
      .map(_lastSegment)
      .where((name) => name.endsWith(extension))
      .map((name) => name.substring(0, name.length - extension.length))
      .toList()
    ..sort();
}

/// Returns the value of [key] in a TOML file of one `key = "value"` per line.
String? _tomlValue(String source, String key) {
  return RegExp('^$key = "(.*)"\$', multiLine: true).firstMatch(source)?.group(1);
}

/// Returns the value of [key] in the YAML frontmatter of a Markdown file.
String? _frontmatterValue(String source, String key) {
  final block = RegExp(r'^---\r?\n(.*?)\r?\n---', dotAll: true).firstMatch(source)?.group(1);
  if (block == null) return null;
  final match = RegExp('^$key: (.*)\$', multiLine: true).firstMatch(block);
  return match?.group(1)?.trim();
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

    test('.agents/skills exists and has skills', () {
      expect(Directory('.agents/skills').existsSync(), isTrue, reason: '.agents/skills is missing');
      expect(skills, isNotEmpty, reason: '.agents/skills has no skill folders');
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

  group('agent roles', () {
    final roles = _names(_rolesDir, '.md');

    test('there is at least one role', () {
      expect(roles, isNotEmpty);
    });

    test('Claude and the old role folder have no agent files', () {
      expect(Directory('.claude/agents').existsSync(), isFalse, reason: '.claude/agents must not exist');
      expect(Directory('.agents/roles').existsSync(), isFalse, reason: '.agents/roles must not exist');
    });

    test('a Codex model carrier exists for every role and for no other name', () {
      expect(_names('.codex/agents', '.toml'), roles);
    });

    for (final role in roles) {
      final rolePath = '$_rolesDir/$role.md';

      test('$role has valid frontmatter', () {
        final markdown = File(rolePath).readAsStringSync();

        expect(_frontmatterValue(markdown, 'name'), role);
        expect(_modelPairs.values, contains(_frontmatterValue(markdown, 'model')));
        expect(_efforts, contains(_frontmatterValue(markdown, 'effort')));
        expect(_accessModes, contains(_frontmatterValue(markdown, 'access')));
      });

      test('$role read-only access is stated in the role file', () {
        final markdown = File(rolePath).readAsStringSync();

        if (_frontmatterValue(markdown, 'access') == 'read-only') {
          expect(markdown, contains('Never edit'), reason: '$rolePath is read-only but does not say "Never edit"');
        }
      });

      test('$role matches its Codex model carrier', () {
        final markdown = File(rolePath).readAsStringSync();
        final toml = File('.codex/agents/$role.toml').readAsStringSync();

        expect(_tomlValue(toml, 'name'), role);
        expect(toml, contains(rolePath), reason: 'the Codex file must point to $rolePath');
        expect(_tomlValue(toml, 'model_reasoning_effort'), _frontmatterValue(markdown, 'effort'));

        final codexModel = _tomlValue(toml, 'model');
        expect(_modelPairs, contains(codexModel), reason: 'unknown Codex model $codexModel');
        expect(_modelPairs[codexModel], _frontmatterValue(markdown, 'model'));

        final access = _frontmatterValue(markdown, 'access');
        expect(
          _tomlValue(toml, 'sandbox_mode'),
          _sandboxByAccess[access],
          reason: 'sandbox_mode must match access $access',
        );
      });
    }
  });

  group('documented paths', () {
    const skillFiles = [
      '.agents/skills/skill-orchestrator/SKILL.md',
      '.agents/skills/skill-project-tasks/SKILL.md',
    ];
    final sources = [
      'CLAUDE.md',
      ...skillFiles,
      ..._names(_rolesDir, '.md').map((name) => '$_rolesDir/$name.md'),
      ..._names('.codex/agents', '.toml').map((name) => '.codex/agents/$name.toml'),
    ];

    for (final source in sources) {
      test('every rule, skill, role or Codex path in $source exists', () {
        final text = File(source).readAsStringSync();
        for (final match in _referencedPath.allMatches(text)) {
          final path = match.group(0)!;
          expect(File(path).existsSync(), isTrue, reason: '$source mentions $path, which does not exist');
        }
      });

      test('$source does not mention the removed agent folders', () {
        final text = File(source).readAsStringSync();
        for (final mention in _forbiddenMentions) {
          expect(text, isNot(contains(mention)), reason: '$source must not mention $mention');
        }
      });
    }

    for (final source in skillFiles) {
      test('every relative skill link in $source exists', () {
        final text = File(source).readAsStringSync();
        final folder = File(source).parent.path;
        for (final match in _relativeSkillLink.allMatches(text)) {
          final path = '$folder/${match.group(0)!}';
          expect(File(path).existsSync(), isTrue, reason: '$source links to ${match.group(0)}, which does not exist');
        }
      });
    }
  });
}
