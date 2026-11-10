// Checks the path-to-check rules and the diff reader of tool/agent_check.dart.
// No command is run: the tests only look at the plan and the parsed lines.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agent_check.dart';

ChangeSet _changes(List<String> files, {Set<String>? existing}) {
  return ChangeSet(files, exists: (path) => existing == null || existing.contains(path));
}

List<String> _labels(ChangeSet changes, {bool skipBuild = false}) {
  return changes.plan(skipBuild: skipBuild).map((command) => command.label).toList();
}

void main() {
  group('ChangeSet', () {
    test('normalizes, removes duplicates and sorts the files', () {
      final changes = _changes(['./b.md', 'a.md', 'b.md', '']);

      expect(changes.files, ['a.md', 'b.md']);
    });

    test('a documentation change needs no check', () {
      expect(_changes(['README.md', 'docs/backlog/x.md']).plan(), isEmpty);
    });

    test('a presentation file gets format, analyze and the matching tests', () {
      final changes = _changes(
        ['lib/features/timer/presentation/timer_page.dart'],
        existing: {
          'lib/features/timer/presentation/timer_page.dart',
          'test/features/timer/presentation/timer_page_test.dart',
          'test/architecture/layer_boundaries_test.dart',
          'test/snapshots/ui_snapshots_test.dart',
        },
      );

      expect(_labels(changes), ['Format (check only)', 'Analyze changed files', 'Tests']);
      expect(changes.testFiles, [
        'test/architecture/layer_boundaries_test.dart',
        'test/features/timer/presentation/timer_page_test.dart',
        'test/snapshots/ui_snapshots_test.dart',
      ]);
    });

    test('a data file does not run the golden snapshots', () {
      final changes = _changes(['lib/features/settings/data/settings_repository.dart']);

      expect(changes.testFiles, isNot(contains('test/snapshots/ui_snapshots_test.dart')));
      expect(changes.testFiles, contains('test/architecture/layer_boundaries_test.dart'));
    });

    test('a test that does not exist is not run', () {
      final changes = _changes(
        ['lib/core/result.dart'],
        existing: {'lib/core/result.dart', 'test/architecture/layer_boundaries_test.dart'},
      );

      expect(changes.testFiles, ['test/architecture/layer_boundaries_test.dart']);
    });

    test('a changed test file runs itself', () {
      final changes = _changes(['test/core/result_test.dart']);

      expect(changes.testFiles, ['test/core/result_test.dart']);
    });

    test('a tool file runs its mirrored test', () {
      final changes = _changes(['tool/agent_check.dart']);

      expect(changes.testFiles, ['test/tool/agent_check_test.dart']);
    });

    test('generated and deleted files are not analyzed', () {
      final changes = _changes(
        ['lib/l10n/app_localizations.dart', 'lib/firebase_options.dart', 'lib/core/gone.dart', 'lib/core/kept.dart'],
        existing: {'lib/l10n/app_localizations.dart', 'lib/firebase_options.dart', 'lib/core/kept.dart'},
      );

      expect(changes.dartFiles, ['lib/core/kept.dart']);
    });

    test('an arb change generates localizations first', () {
      final changes = _changes(['lib/l10n/app_en.arb']);

      expect(_labels(changes), ['Generate localizations', 'Tests']);
      expect(changes.testFiles, ['test/snapshots/ui_snapshots_test.dart']);
    });

    test('a change in the AI setup runs the setup test', () {
      for (final file in ['CLAUDE.md', '.agents/rules/dart-style.md', '.codex/agents/x.toml']) {
        expect(
          _changes([file]).testFiles,
          ['test/architecture/ai_setup_test.dart'],
          reason: file,
        );
      }
    });

    test('android or pubspec changes build the apk, and skipBuild skips it', () {
      for (final file in ['android/app/build.gradle', 'pubspec.yaml']) {
        final changes = _changes([file]);

        expect(
          _labels(changes),
          ['Android debug build'],
          reason: file,
        );
        expect(
          _labels(changes, skipBuild: true),
          isEmpty,
          reason: file,
        );
      }
    });

    test('an ios change builds ios', () {
      expect(_labels(_changes(['ios/Runner/Info.plist'])), ['iOS debug build']);
    });
  });

  group('DiffReader', () {
    const diff = '''
diff --git a/lib/a.dart b/lib/a.dart
index 111..222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,2 +1,3 @@
 keep
+added one
 keep
@@ -10,0 +12,2 @@
+added two
+added three
diff --git a/lib/b.dart b/lib/b.dart
--- a/lib/b.dart
+++ b/lib/b.dart
@@ -5 +5 @@
-old
+new
diff --git a/lib/gone.dart b/lib/gone.dart
--- a/lib/gone.dart
+++ /dev/null
@@ -1 +0,0 @@
-removed
''';

    test('reads added lines with their line numbers in the new file', () {
      final added = DiffReader.fromDiff(diff).map((line) => '${line.file}:${line.line} ${line.text}').toList();

      expect(added, [
        'lib/a.dart:2 added one',
        'lib/a.dart:12 added two',
        'lib/a.dart:13 added three',
        'lib/b.dart:5 new',
      ]);
    });

    test('counts every line of a new file as added', () {
      final added = DiffReader.fromNewFile('x.md', 'one\ntwo');

      expect(added.map((line) => line.line), [1, 2]);
    });

    test('drops the tab git adds after a path with spaces', () {
      const spaced = 'diff --git a/a b.md b/a b.md\n+++ b/a b.md\t\n@@ -0,0 +1 @@\n+text\n';

      expect(DiffReader.fromDiff(spaced).single.file, 'a b.md');
    });

    test('a file that is not readable text has no lines', () {
      final folder = Directory.systemTemp.createTempSync('agent_check_test');
      addTearDown(() => folder.deleteSync(recursive: true));
      final binary = File('${folder.path}/image.bin')..writeAsBytesSync([0xff, 0xfe, 0x00, 0xc3, 0x28]);
      final text = File('${folder.path}/note.md')..writeAsStringSync('one\ntwo');

      expect(DiffReader.fromPath(binary.path), isEmpty);
      expect(DiffReader.fromPath('${folder.path}/missing.md'), isEmpty);
      expect(DiffReader.fromPath(text.path).map((line) => line.line), [1, 2]);
    });

    test('the markers match a local path and an open note', () {
      expect('final p = "${homePathMarker}me/x";'.contains(homePathMarker), isTrue);
      expect(openNotePattern.hasMatch('// ${'TO'}DO later'), isTrue);
      expect(openNotePattern.hasMatch('// fixed later'), isFalse);
    });
  });
}
