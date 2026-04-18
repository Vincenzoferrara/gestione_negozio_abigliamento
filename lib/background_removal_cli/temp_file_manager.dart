import 'dart:io';

class TempJobFiles {
  final Directory workDir;
  final File inputFile;
  final File outputFile;

  const TempJobFiles({
    required this.workDir,
    required this.inputFile,
    required this.outputFile,
  });
}

class TempFileManager {
  const TempFileManager();

  Future<TempJobFiles> prepare(String sourceImagePath) async {
    final source = File(sourceImagePath);
    if (!source.existsSync()) {
      throw Exception('File sorgente non trovato: $sourceImagePath');
    }

    final ext = _extensionOf(sourceImagePath);
    final workDir = await Directory.systemTemp.createTemp('bg_remove_');

    final inputFile = File('${workDir.path}${Platform.pathSeparator}input.$ext');
    final outputFile = File('${workDir.path}${Platform.pathSeparator}output.png');

    await source.copy(inputFile.path);

    return TempJobFiles(workDir: workDir, inputFile: inputFile, outputFile: outputFile);
  }

  Future<void> cleanup(TempJobFiles job) async {
    if (job.workDir.existsSync()) {
      await job.workDir.delete(recursive: true);
    }
  }

  String _extensionOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'png';
    return name.substring(dot + 1).toLowerCase();
  }
}
