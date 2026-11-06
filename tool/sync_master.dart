// Moves the local repo to an up to date `master` and deletes the local
// branches whose pull request is already merged.
//
//   fvm dart tool/sync_master.dart
//
// It stops with no change when there are uncommitted changes. It deletes a
// branch only when GitHub shows a merged pull request into master with the
// same last commit, and never touches remote branches. The rules are in
// tool/dispatcher/master_sync.dart and are unit tested.
import 'dart:io';

import 'dispatcher/command_runner.dart';
import 'dispatcher/master_sync.dart';

Future<void> main() async {
  final sync = MasterSync(workspace: Directory.current.path, run: runSystemCommand);
  try {
    final report = await sync.sync();
    if (report.switchedFrom case final branch?) stdout.writeln('Switched from $branch to master. It was kept.');
    stdout.writeln('On master, up to date.');
    stdout.writeln(
      report.deleted.isEmpty ? 'No merged branches to delete.' : 'Deleted: ${report.deleted.join(', ')}',
    );
    for (final MapEntry(key: branch, value: reason) in report.kept.entries) {
      stdout.writeln('Kept $branch: $reason');
    }
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }
}
