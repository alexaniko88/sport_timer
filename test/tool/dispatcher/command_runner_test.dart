import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/command_runner.dart';
import '../../../tool/dispatcher/model_catalog.dart';

void main() {
  test('missing model command is tolerated while general commands fail', () async {
    const missing = 'dispatcher_nonexistent_executable_987654321';
    expect(await ModelCatalog.output(missing, []), isEmpty);
    expect(() => runSystemCommand(missing, []), throwsA(isA<ProcessException>()));
  });

  test('resolves a user executable only when PATH does not contain it', () async {
    final root = await Directory.systemTemp.createTemp('dispatcher_test');
    addTearDown(() => root.delete(recursive: true));
    final bin = await Directory('${root.path}/.local/bin').create(recursive: true);
    final executable = File('${bin.path}/example');
    await executable.writeAsString('#!/bin/sh\n');
    await Process.run('chmod', ['755', executable.path]);
    final environment = {'HOME': root.path, 'PATH': '/nonexistent'};
    expect(resolveExecutable('example', environment: environment), executable.path);
    environment['PATH'] = bin.path;
    expect(resolveExecutable('example', environment: environment), 'example');
    expect(resolveExecutable('/explicit/example', environment: environment), '/explicit/example');
    expect(resolveExecutable('missing', environment: environment), 'missing');
  });
}
