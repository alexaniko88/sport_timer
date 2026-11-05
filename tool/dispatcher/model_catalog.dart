import 'dart:convert';

import 'role_models.dart';

/// One model of a tool's catalog, split into vendor, family and version.
class CatalogModel {
  final String id;
  final String vendor;
  final String family;
  final List<int> version;

  const CatalogModel({
    required this.id,
    required this.vendor,
    required this.family,
    required this.version,
  });

  /// Whether this version is newer than [other]'s.
  bool isNewerThan(CatalogModel other) {
    final length = version.length > other.version.length ? version.length : other.version.length;
    for (var index = 0; index < length; index++) {
      final mine = index < version.length ? version[index] : 0;
      final theirs = index < other.version.length ? other.version[index] : 0;
      if (mine != theirs) return mine > theirs;
    }
    return false;
  }
}

/// Reads what `codex debug models` and `agy models` print, and keeps only the
/// newest model of each family.
class ModelCatalog {
  static final _vendorVersionFamily = RegExp(r'^([a-z]+)-(\d+(?:\.\d+)*)-([a-z]+)$');
  static final _vendorFamilyVersion = RegExp(r'^([a-z]+)-([a-z]+)-(\d+(?:-\d+)*)$');
  static final _effortSuffix = RegExp(r'-(low|medium|high|xhigh|max)$');

  /// The visible models of `codex debug models` (JSON).
  static List<CatalogModel> parseCodex(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const [];
    }
    final entries = switch (decoded) {
      {'models': final List<Object?> models} => models,
      final List<Object?> models => models,
      _ => const <Object?>[],
    };
    final models = <CatalogModel>[];
    for (final entry in entries) {
      if (entry case {'slug': final String slug, 'visibility': 'list'}) {
        if (_parse(slug) case final model?) models.add(model);
      }
    }
    return models;
  }

  /// The lines of `agy models`: an id, a tab and a display name.
  static List<CatalogModel> parseAntigravity(String text) {
    final models = <CatalogModel>[];
    for (final line in text.split('\n')) {
      final id = line.split('\t').first.trim();
      if (id.isEmpty) continue;
      if (_parse(id.replaceFirst(_effortSuffix, ''), id: id) case final model?) models.add(model);
    }
    return models;
  }

  /// The newest model of every vendor and family. For Antigravity the ids keep
  /// their effort suffix, so every effort of the newest version is kept.
  static List<CatalogModel> latestPerFamily(List<CatalogModel> models) {
    final newest = <String, CatalogModel>{};
    for (final model in models) {
      final key = '${model.vendor}/${model.family}';
      final current = newest[key];
      if (current == null || model.isNewerThan(current)) newest[key] = model;
    }
    return models.where((model) {
      final best = newest['${model.vendor}/${model.family}'];
      return best != null && !best.isNewerThan(model) && !model.isNewerThan(best);
    }).toList();
  }

  /// Whether [id] is in [models] and has no newer version in its family.
  static bool isCurrent({required String id, required List<CatalogModel> models}) {
    return latestPerFamily(models).any((model) => model.id == id);
  }

  static CatalogModel? _parse(String name, {String? id}) {
    final id0 = id ?? name;
    if (_vendorVersionFamily.firstMatch(name) case final match?) {
      return CatalogModel(
        id: id0,
        vendor: match.group(1) ?? '',
        family: match.group(3) ?? '',
        version: _numbers(match.group(2) ?? '', '.'),
      );
    }
    if (_vendorFamilyVersion.firstMatch(name) case final match?) {
      return CatalogModel(
        id: id0,
        vendor: match.group(1) ?? '',
        family: match.group(2) ?? '',
        version: _numbers(match.group(3) ?? '', '-'),
      );
    }
    return null;
  }

  static List<int> _numbers(String text, String separator) {
    return text.split(separator).map((part) => int.tryParse(part) ?? 0).toList();
  }

  /// The fixed models that are missing or no longer the newest of their family.
  ///
  /// Claude has no catalog: its aliases always point to the newest model.
  static List<String> staleModels({required Tool tool, required List<CatalogModel> models}) {
    if (tool == Tool.claude) return const [];
    final stale = <String>[];
    for (final role in Role.values) {
      final model = RoleModels.of(tool: tool, role: role).model;
      if (!isCurrent(id: model, models: models)) stale.add('${role.name}: $model');
    }
    return stale;
  }
}
