import 'dart:io';

/// The result of a finished command.
class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const CommandResult({required this.exitCode, required this.stdout, required this.stderr});

  bool get ok => exitCode == 0;
}

/// Runs one command. Tests pass a fake; the tool uses [runSystemCommand].
typedef RunCommand = Future<CommandResult> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

Future<CommandResult> runSystemCommand(
  String executable,
  List<String> args, {
  String? workingDirectory,
}) async {
  final result = await Process.run(executable, args, workingDirectory: workingDirectory);
  return CommandResult(
    exitCode: result.exitCode,
    stdout: result.stdout as String,
    stderr: result.stderr as String,
  );
}
