// Checks the small text and path helpers of tool/dispatcher/extensions/.
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/dispatcher/extensions/command_options.dart';
import '../../../../tool/dispatcher/extensions/front_matter_text.dart';
import '../../../../tool/dispatcher/extensions/markdown_sections.dart';
import '../../../../tool/dispatcher/extensions/posix_path.dart';
import '../../../../tool/dispatcher/extensions/repo_url.dart';
import '../../../../tool/dispatcher/extensions/text_case.dart';
import '../../../../tool/dispatcher/extensions/touch_paths.dart';

void main() {
  group('FrontMatterText', () {
    test('reads scalars, inline lists and block lists, and drops comments', () {
      const text = '''
---
id: TPL-03-02
status: draft          # draft | ready
depends-on: [TPL-03-01, TPL-03-00]
touches:               # paths the task changes
  - lib/features/templates/**
  - test/snapshots/goldens/a.png
skills: []
---

# Title
''';

      expect(text.frontMatter, {
        'id': 'TPL-03-02',
        'status': 'draft',
        'depends-on': ['TPL-03-01', 'TPL-03-00'],
        'touches': ['lib/features/templates/**', 'test/snapshots/goldens/a.png'],
        'skills': <String>[],
      });
    });

    test('reads block list items that are not indented', () {
      const text = '---\nid: A-01\ntouches:\n- lib/a.dart\n- lib/b.dart\n---\n';

      expect(text.frontMatter['touches'], ['lib/a.dart', 'lib/b.dart']);
    });

    test('a file without front matter gives an empty map', () {
      expect('# Title\n\nid: nope'.frontMatter, isEmpty);
    });
  });

  group('MarkdownSections', () {
    const text = '# Title\n\n## Goal\n\nDo it.\n\n## Acceptance\n\n- [ ] One\n- [x] Two\n\n## Last\n\nEnd.\n';

    test('returns the text of a section up to the next heading', () {
      expect(text.section('Acceptance'), '- [ ] One\n- [x] Two');
      expect(text.section('Last'), 'End.');
      expect(text.section('Missing'), '');
    });

    test('reads the first heading', () {
      expect(text.firstHeading, 'Title');
    });
  });

  group('TouchPaths', () {
    test('a folder glob overlaps a file inside it', () {
      expect(['lib/features/templates/**'].overlaps(['lib/features/templates/a.dart']), isTrue);
    });

    test('two different golden files do not overlap', () {
      expect(['test/snapshots/goldens/a.png'].overlaps(['test/snapshots/goldens/b.png']), isFalse);
    });

    test('a glob in a file name keeps the folder as its base', () {
      expect(['lib/a/*.dart'].overlaps(['lib/b/x.dart']), isFalse);
      expect(['lib/a/*.dart'].overlaps(['lib/a/x.dart']), isTrue);
    });

    test('an empty list overlaps everything', () {
      expect(<String>[].overlaps(['lib/a.dart']), isTrue);
    });
  });

  group('PosixPath', () {
    test('normalizes dots and double dots', () {
      expect('a/./b/../c'.normalized, 'a/c');
    });

    test('resolves and writes relative paths', () {
      expect('../index.md'.resolveFrom('p/stories/01-s/01-t'), 'p/stories/01-s/index.md');
      expect('p/stories/01-s/index.md'.relativeTo('p/stories/01-s/done/01-t'), '../../index.md');
    });
  });

  group('RepoUrl', () {
    test('reads the slug of https and ssh URLs', () {
      expect('https://github.com/owner/repo.git'.githubSlug, 'owner/repo');
      expect('git@github.com:owner/repo'.githubSlug, 'owner/repo');
      expect('https://example.com/owner/repo'.githubSlug, isNull);
    });
  });

  test('TextCase lowers only the first letter', () {
    expect('Store Custom'.lowerFirst, 'store Custom');
  });

  test('CommandOptions splits options and positional arguments', () {
    final args = ['TPL-1', '--tool=codex', '--flag'];

    expect(args.options, {'tool': 'codex', 'flag': 'true'});
    expect(args.positional, ['TPL-1']);
  });
}
