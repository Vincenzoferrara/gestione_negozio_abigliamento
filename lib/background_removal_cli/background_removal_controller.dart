import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'background_removal_service.dart';

enum BackgroundUiStatus { idle, running, done, error }

class BackgroundRemovalController extends ChangeNotifier {
  final BackgroundRemovalService service;

  BackgroundUiStatus status = BackgroundUiStatus.idle;
  String? inputPath;
  Uint8List? outputBytes;
  String? error;
  String stdoutText = '';
  String stderrText = '';
  Duration? elapsed;

  BackgroundRemovalController({required this.service});

  Future<void> pickInputImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    inputPath = result.files.first.path;
    outputBytes = null;
    error = null;
    status = BackgroundUiStatus.idle;
    notifyListeners();
  }

  Future<void> process() async {
    if (inputPath == null) {
      status = BackgroundUiStatus.error;
      error = 'Seleziona prima un\'immagine.';
      notifyListeners();
      return;
    }

    status = BackgroundUiStatus.running;
    error = null;
    stdoutText = '';
    stderrText = '';
    elapsed = null;
    notifyListeners();

    try {
      final result = await service.removeBackgroundFromFile(inputPath!);
      outputBytes = result.pngBytes;
      stdoutText = result.process.stdoutText.trim();
      stderrText = result.process.stderrText.trim();
      elapsed = result.process.duration;
      status = BackgroundUiStatus.done;
      notifyListeners();
    } catch (e) {
      status = BackgroundUiStatus.error;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveOutputAsPng() async {
    if (outputBytes == null) return;

    final fileName = _buildDefaultFileName();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva PNG scontornato',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['png'],
      bytes: outputBytes,
    );

    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(outputBytes!, flush: true);
  }

  String _buildDefaultFileName() {
    if (inputPath == null) return 'output_nobg.png';
    final normalized = inputPath!.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return '${base}_nobg.png';
  }
}
