import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'logging.dart';

final log = Logger("process");

class CommandFailedException implements Exception {
  final String executable;
  final List<String> arguments;
  final ProcessResult result;

  CommandFailedException({
    required this.executable,
    required this.arguments,
    required this.result,
  });

  @override
  String toString() {
    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();
    return [
      "External Command: $executable ${arguments.map((e) => '"$e"').join(' ')}",
      "Returned Exit Code: ${result.exitCode}",
      kSeparator,
      "STDOUT:",
      if (stdout.isNotEmpty) stdout,
      kSeparator,
      "STDERR:",
      if (stderr.isNotEmpty) stderr,
    ].join('\n');
  }
}

ProcessResult runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
}) {
  log.finer('Running command $executable ${arguments.join(' ')}');

  final res = Process.runSync(
    _resolveExecutable(executable),
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stderrEncoding: stderrEncoding,
    stdoutEncoding: stdoutEncoding,
  );

  if (res.exitCode != 0) {
    throw CommandFailedException(
      executable: executable,
      arguments: arguments,
      result: res,
    );
  } else {
    return res;
  }
}

Future<ProcessResult> runCommandStreamStdout(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
}) async {
  log.finer('Running command $executable ${arguments.join(' ')}');

  final process = await Process.start(
    _resolveExecutable(executable),
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );

  process.stdout
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => stdout.writeln(line));

  process.stderr
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => stderr.writeln(line));

  final pid = process.pid;
  final exitCode = await process.exitCode;
  final res = ProcessResult(
    pid,
    exitCode,
    '',
    '',
  );

  if (res.exitCode != 0) {
    throw CommandFailedException(
      executable: executable,
      arguments: arguments,
      result: res,
    );
  } else {
    return res;
  }
}

String _resolveExecutable(String executable) {
  return executable;
}
