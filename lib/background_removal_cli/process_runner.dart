import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ProcessRunResult {
  final int exitCode;
  final String stdoutText;
  final String stderrText;
  final Duration duration;
  final bool timedOut;

  const ProcessRunResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
    required this.duration,
    required this.timedOut,
  });

  bool get success => exitCode == 0 && !timedOut;
}

class ProcessRunner {
  const ProcessRunner();

  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 90),
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final stopwatch = Stopwatch()..start();

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );

    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    var timedOut = false;
    final exitCodeFuture = process.exitCode.timeout(
      timeout,
      onTimeout: () async {
        timedOut = true;
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );

    final exitCode = await exitCodeFuture;
    final stdoutText = await stdoutFuture;
    final stderrText = await stderrFuture;

    stopwatch.stop();

    return ProcessRunResult(
      exitCode: exitCode,
      stdoutText: stdoutText,
      stderrText: stderrText,
      duration: stopwatch.elapsed,
      timedOut: timedOut,
    );
  }
}
