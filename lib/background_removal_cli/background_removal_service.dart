import 'dart:io';
import 'dart:typed_data';

import 'process_runner.dart';
import 'temp_file_manager.dart';

class BackgroundRemovalResult {
  final Uint8List pngBytes;
  final ProcessRunResult process;

  const BackgroundRemovalResult({
    required this.pngBytes,
    required this.process,
  });
}

class BackgroundRemovalService {
  final ProcessRunner processRunner;
  final TempFileManager tempFileManager;

  const BackgroundRemovalService({
    this.processRunner = const ProcessRunner(),
    this.tempFileManager = const TempFileManager(),
  });

  Future<BackgroundRemovalResult> removeBackgroundFromFile(
    String sourceImagePath, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final binary = _resolveBundledBinaryPath();
    if (binary == null) {
      throw Exception(
        'Binary background remover non trovato. Atteso in bg_engine per questa piattaforma.',
      );
    }

    final job = await tempFileManager.prepare(sourceImagePath);
    try {
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', binary]);
      }

      final args = <String>[
        '-i',
        job.inputFile.path,
        '-o',
        job.outputFile.path,
      ];

      final runResult = await processRunner.run(
        binary,
        args,
        timeout: timeout,
        workingDirectory: job.workDir.path,
      );

      if (!runResult.success) {
        throw Exception(
          'Background remover fallito (exit ${runResult.exitCode}). '
          'stderr: ${runResult.stderrText.trim().isEmpty ? '(vuoto)' : runResult.stderrText.trim()}',
        );
      }

      if (!job.outputFile.existsSync()) {
        throw Exception('Output PNG non generato dal binary.');
      }

      final bytes = await job.outputFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Output PNG generato ma vuoto.');
      }

      return BackgroundRemovalResult(
        pngBytes: bytes,
        process: runResult,
      );
    } finally {
      await tempFileManager.cleanup(job);
    }
  }

  String? _resolveBundledBinaryPath() {
    final fromEnv = Platform.environment['BG_REMOVER_BIN'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      final envFile = File(fromEnv.trim());
      if (envFile.existsSync()) return envFile.path;
    }

    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[];

    if (Platform.isWindows) {
      candidates.add('$executableDir\\bg_engine\\backgroundremover.exe');
    } else if (Platform.isLinux) {
      candidates.add('$executableDir/bg_engine/backgroundremover');
    } else if (Platform.isMacOS) {
      candidates.add('$executableDir/../Resources/bg_engine/backgroundremover');
      candidates.add('$executableDir/bg_engine/backgroundremover');
    }

    final scriptDir = Directory.current.path;
    if (Platform.isWindows) {
      candidates.add('$scriptDir\\tools\\bg_engine\\windows\\backgroundremover.exe');
    } else if (Platform.isLinux) {
      candidates.add('$scriptDir/tools/bg_engine/linux/backgroundremover');
    } else if (Platform.isMacOS) {
      candidates.add('$scriptDir/tools/bg_engine/macos/backgroundremover');
    }

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }
}
