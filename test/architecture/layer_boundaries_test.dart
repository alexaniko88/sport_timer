// Checks the layer rules described in CLAUDE.md by reading the `import`,
// `export` and `part` lines of every file under lib/ (both URIs of a
// conditional import), and the folder layout of lib/features and lib/shared.
//
// Scope: only those directives and file paths. It cannot see other couplings,
// such as a View calling `getIt<T>()` or a domain class using a type that
// reached it through an allowed import. It also does not check which feature
// imports which feature, or the rule that Views never touch repositories.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _packagePrefix = 'package:sport_timer/';

final _domainFile = RegExp(r'^lib/features/[^/]+/domain/');
final _dataFile = RegExp(r'^lib/features/[^/]+/data/');
final _presentationFile = RegExp(r'^(lib/features/[^/]+/presentation/|lib/shared/presentation/)');
final _coreFile = RegExp(r'^lib/core/');

final _anyData = RegExp(r'^lib/features/[^/]+/data/');
final _anyPresentation = RegExp(r'^lib/(features/[^/]+|shared)/presentation/');
final _featureDomain = RegExp(r'^lib/features/[^/]+/domain/');

/// Packages that talk to the platform. Presentation code must not import them.
const _platformPackages = [
  'firebase_',
  'google_sign_in',
  'sqflite',
  'shared_preferences',
  'audioplayers',
  'audio_service',
  'permission_handler',
  'wakelock_plus',
];

/// Presentation files that may import a platform package, with the reason.
/// Keep this list as short as possible.
const _presentationExceptions = <String, Map<String, String>>{
  'lib/features/timer/presentation/timer_page.dart': {
    'wakelock_plus': 'The page keeps the screen on only while it is shown, so it owns the wakelock.',
  },
};

/// `dart:` libraries that need the platform or Flutter. Domain and core must
/// not import them.
const _platformDartLibraries = ['dart:ui', 'dart:io', 'dart:html', 'dart:js', 'dart:ffi', 'dart:isolate'];

bool _isPlatformDartLibrary(String target) {
  return _platformDartLibraries.any((name) => target == name || target.startsWith('${name}_'));
}

final _featureFile = RegExp(r'^lib/features/[^/]+/');
final _featureLayerFile = RegExp(r'^lib/features/[^/]+/(domain|data|presentation)/');
final _sharedFile = RegExp(r'^lib/shared/');
final _sharedPresentationFile = RegExp(r'^lib/shared/presentation/');

/// Returns the layout rule broken by the location of [filePath], if any.
List<String> findLayoutViolations(String filePath) {
  if (_featureFile.hasMatch(filePath) && !_featureLayerFile.hasMatch(filePath)) {
    return ['$filePath: a feature file must be inside domain/, data/ or presentation/'];
  }
  if (_sharedFile.hasMatch(filePath) && !_sharedPresentationFile.hasMatch(filePath)) {
    return ['$filePath: a shared file must be inside presentation/'];
  }
  return [];
}

/// Returns what [importUri] becomes: a `lib/...` path for files of this app,
/// or the original `dart:` or `package:` URI for anything else.
String normalizeImport(String filePath, String importUri) {
  if (importUri.startsWith(_packagePrefix)) {
    return 'lib/${importUri.substring(_packagePrefix.length)}';
  }
  if (importUri.startsWith('dart:') || importUri.startsWith('package:')) {
    return importUri;
  }
  return Uri.parse(filePath).resolve(importUri).path;
}

bool _isPlatformPackage(String target) {
  if (!target.startsWith('package:')) return false;
  final name = target.substring('package:'.length);
  return _platformPackages.any(name.startsWith);
}

/// Returns the rules broken by [filePath] importing [importUri]. Both are
/// described in the result, so a failure says what to fix.
List<String> findViolations(String filePath, String importUri) {
  final target = normalizeImport(filePath, importUri);
  final violations = <String>[];
  void add(String reason) => violations.add('$filePath imports $importUri: $reason');

  if (_domainFile.hasMatch(filePath)) {
    final allowed = (target.startsWith('dart:') && !_isPlatformDartLibrary(target)) ||
        _coreFile.hasMatch(target) ||
        _featureDomain.hasMatch(target);
    if (!allowed) {
      add('domain may import only platform-free dart: libraries, core and domain files of any feature');
    }
  } else if (_presentationFile.hasMatch(filePath)) {
    if (_anyData.hasMatch(target)) {
      add('presentation must not import a data file');
    }
    if (_isPlatformPackage(target)) {
      final package = _platformPackages.firstWhere(
        (name) => target.startsWith('package:$name'),
      );
      final isException = _presentationExceptions[filePath]?.containsKey(package) ?? false;
      if (!isException) {
        add('presentation must not import the platform package $package');
      }
    }
  } else if (_dataFile.hasMatch(filePath)) {
    if (_anyPresentation.hasMatch(target)) {
      add('data must not import a presentation file');
    }
  } else if (_coreFile.hasMatch(filePath)) {
    final isFlutter = target.startsWith('package:flutter/') || target == 'package:flutter';
    if (isFlutter || target.startsWith('lib/features/') || target.startsWith('lib/shared/')) {
      add('core must not import flutter, features or shared');
    }
    if (_isPlatformDartLibrary(target)) {
      add('core must not import a platform dart: library');
    }
  }
  return violations;
}

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"][^;]*;''', multiLine: true);
final _conditionalUri = RegExp(r'''\sif\s*\([^)]*\)\s*['"]([^'"]+)['"]''');
final _partDirective = RegExp(r'''^\s*part\s+(?:of\s+)?['"a-zA-Z_.]''', multiLine: true);

/// Returns every URI of the import and export lines, including the second URI
/// of a conditional import.
List<String> extractImportUris(String source) {
  final uris = <String>[];
  for (final match in _directive.allMatches(source)) {
    uris.add(match.group(1)!);
    for (final conditional in _conditionalUri.allMatches(match.group(0)!)) {
      uris.add(conditional.group(1)!);
    }
  }
  return uris;
}

/// True when [source] has a `part` or `part of` line.
bool hasPartDirective(String source) => _partDirective.hasMatch(source);

void main() {
  group('findViolations', () {
    test('accepts allowed imports', () {
      expect(findViolations('lib/features/timer/domain/a.dart', 'dart:async'), isEmpty);
      expect(
        findViolations(
          'lib/features/timer/domain/a.dart',
          'package:sport_timer/features/settings/domain/timer_style.dart',
        ),
        isEmpty,
      );
      expect(findViolations('lib/features/timer/domain/a.dart', 'b.dart'), isEmpty);
      expect(
        findViolations(
          'lib/features/user/data/a.dart',
          'package:firebase_auth/firebase_auth.dart',
        ),
        isEmpty,
      );
    });

    test('detects a domain file importing a platform package', () {
      expect(
        findViolations(
          'lib/features/user/domain/a.dart',
          'package:firebase_auth/firebase_auth.dart',
        ),
        isNotEmpty,
      );
    });

    test('detects a domain file importing flutter', () {
      expect(
        findViolations('lib/features/timer/domain/a.dart', 'package:flutter/foundation.dart'),
        isNotEmpty,
      );
    });

    test('detects a domain file importing data, also through a relative path', () {
      expect(
        findViolations(
          'lib/features/user/domain/a.dart',
          'package:sport_timer/features/user/data/firebase_user_repository.dart',
        ),
        isNotEmpty,
      );
      expect(
        findViolations('lib/features/user/domain/a.dart', '../data/firebase_user_repository.dart'),
        isNotEmpty,
      );
    });

    test('detects presentation importing data', () {
      expect(
        findViolations(
          'lib/features/login/presentation/a.dart',
          'package:sport_timer/features/user/data/firebase_user_repository.dart',
        ),
        isNotEmpty,
      );
      expect(
        findViolations(
          'lib/shared/presentation/a.dart',
          'package:sport_timer/features/user/data/firebase_user_repository.dart',
        ),
        isNotEmpty,
      );
    });

    test('detects presentation importing a platform package', () {
      expect(
        findViolations('lib/features/settings/presentation/a.dart', 'package:sqflite/sqflite.dart'),
        isNotEmpty,
      );
      expect(
        findViolations('lib/features/timer/presentation/a.dart', 'package:wakelock_plus/wakelock_plus.dart'),
        isNotEmpty,
      );
    });

    test('allows the documented wakelock exception only in timer_page.dart', () {
      expect(
        findViolations(
          'lib/features/timer/presentation/timer_page.dart',
          'package:wakelock_plus/wakelock_plus.dart',
        ),
        isEmpty,
      );
      expect(
        findViolations(
          'lib/features/timer/presentation/timer_page.dart',
          'package:sqflite/sqflite.dart',
        ),
        isNotEmpty,
      );
    });

    test('detects a domain or core file importing a platform dart: library', () {
      expect(findViolations('lib/features/timer/domain/a.dart', 'dart:ui'), isNotEmpty);
      expect(findViolations('lib/features/timer/domain/a.dart', 'dart:io'), isNotEmpty);
      expect(findViolations('lib/features/timer/domain/a.dart', 'dart:js_interop'), isNotEmpty);
      expect(findViolations('lib/core/a.dart', 'dart:ui'), isNotEmpty);
      expect(findViolations('lib/core/a.dart', 'dart:async'), isEmpty);
    });

    test('detects data importing presentation', () {
      expect(
        findViolations(
          'lib/features/timer/data/a.dart',
          'package:sport_timer/features/timer/presentation/timer_state.dart',
        ),
        isNotEmpty,
      );
      expect(
        findViolations(
          'lib/features/timer/data/a.dart',
          'package:sport_timer/shared/presentation/extensions/l10n_context.dart',
        ),
        isNotEmpty,
      );
    });

    test('detects core importing flutter, features or shared', () {
      expect(findViolations('lib/core/a.dart', 'package:flutter/material.dart'), isNotEmpty);
      expect(
        findViolations(
          'lib/core/a.dart',
          'package:sport_timer/features/timer/domain/timer_params.dart',
        ),
        isNotEmpty,
      );
      expect(
        findViolations(
          'lib/core/a.dart',
          'package:sport_timer/shared/presentation/extensions/l10n_context.dart',
        ),
        isNotEmpty,
      );
    });
  });

  test('extractImportUris reads imports and exports and ignores comments', () {
    const source = '''
import 'dart:async';
import "package:a/a.dart" as a;
export 'b.dart' show B;
// import 'commented.dart';
''';

    expect(extractImportUris(source), ['dart:async', 'package:a/a.dart', 'b.dart']);
  });

  test('extractImportUris reads the second URI of a conditional import', () {
    const source = "import 'stub.dart' if (dart.library.io) 'io_impl.dart';";

    expect(extractImportUris(source), ['stub.dart', 'io_impl.dart']);
  });

  test('hasPartDirective detects part and part of lines', () {
    expect(hasPartDirective("part 'a.g.dart';"), isTrue);
    expect(hasPartDirective("part of 'a.dart';"), isTrue);
    expect(hasPartDirective("import 'a.dart';\nclass Part {}"), isFalse);
  });

  test('findLayoutViolations detects misplaced files', () {
    expect(findLayoutViolations('lib/features/timer/timer_view_model.dart'), isNotEmpty);
    expect(findLayoutViolations('lib/features/timer/widgets/a.dart'), isNotEmpty);
    expect(findLayoutViolations('lib/shared/theme/a.dart'), isNotEmpty);
    expect(findLayoutViolations('lib/features/timer/domain/a.dart'), isEmpty);
    expect(findLayoutViolations('lib/shared/presentation/theme/a.dart'), isEmpty);
    expect(findLayoutViolations('lib/main.dart'), isEmpty);
    expect(findLayoutViolations('lib/core/result.dart'), isEmpty);
  });

  test('no file under lib/ breaks a layer rule', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);

    final violations = <String>[];
    for (final file in files) {
      final filePath = file.path.replaceAll(r'\', '/');
      final source = file.readAsStringSync();
      for (final uri in extractImportUris(source)) {
        violations.addAll(findViolations(filePath, uri));
      }
      if (hasPartDirective(source)) {
        violations.add('$filePath: part and part of files are not allowed');
      }
      violations.addAll(findLayoutViolations(filePath));
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
