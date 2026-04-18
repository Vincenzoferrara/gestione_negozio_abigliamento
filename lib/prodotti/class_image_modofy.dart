import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:http/http.dart' as http;

// ignore_for_file: camel_case_types

class class_image_modofy {
  static const Set<String> _supportedFormats = <String>{'png', 'jpg', 'webp'};
  static const String bgModeAuto = 'auto';
  static const String bgModeLocal = 'local';
  static const String bgModeApi = 'api';
  static Future<void>? _onnxInitFuture;

  final List<String> _inputImages;
  final List<ImageProcessResult> _lastResults = <ImageProcessResult>[];

  bool _enableResize = false;
  int _targetWidth = 0;
  int _targetHeight = 0;

  bool _enableBackgroundRemove = false;

  bool _enableFormatChange = false;
  String _targetFormat = 'png';

  String _backgroundRemoveMode = bgModeAuto;
  String _backgroundApiEndpoint = 'https://api.remove.bg/v1.0/removebg';
  String _backgroundApiKey = '';

  int _jpegQuality = 90;

  class_image_modofy(this._inputImages);

  void modifica_risolzione(bool enabled, int width, int height) {
    _enableResize = enabled;
    _targetWidth = width;
    _targetHeight = height;
  }

  void backgraud_remove(bool enabled) {
    _enableBackgroundRemove = enabled;
  }

  void cambia_formato(bool enabled, String format) {
    _enableFormatChange = enabled;
    _targetFormat = _normalizeFormat(format);
  }

  void qualita_formato({int jpegQuality = 90, int webpQuality = 90}) {
    _jpegQuality = jpegQuality.clamp(1, 100).toInt();
    final _ = webpQuality;
  }

  void modalita_scontorno({
    required String mode,
    String? apiEndpoint,
    String? apiKey,
  }) {
    final normalizedMode = mode.trim().toLowerCase();
    if (normalizedMode != bgModeAuto &&
        normalizedMode != bgModeLocal &&
        normalizedMode != bgModeApi) {
      throw ArgumentError('Modalita scontorno non supportata: $mode');
    }

    _backgroundRemoveMode = normalizedMode;

    if (apiEndpoint != null && apiEndpoint.trim().isNotEmpty) {
      _backgroundApiEndpoint = apiEndpoint.trim();
    }

    if (apiKey != null) {
      _backgroundApiKey = apiKey.trim();
    }
  }

  List<ImageProcessResult> get ultimi_risultati =>
      List<ImageProcessResult>.unmodifiable(_lastResults);

  Future<List<String>> processa() async {
    final results = await processa_dettagliata();
    return results
        .where((r) => r.success && r.outputPath != null)
        .map((r) => r.outputPath!)
        .toList(growable: false);
  }

  Future<List<ImageProcessResult>> processa_dettagliata() async {
    _lastResults.clear();
    if (_inputImages.isEmpty) return <ImageProcessResult>[];

    final results = await _runWithConcurrencyLimit<ImageProcessResult>(
      items: _inputImages,
      maxConcurrent: 1,
      worker: _processSingleSafe,
    );

    _lastResults.addAll(results);
    return List<ImageProcessResult>.unmodifiable(results);
  }

  Future<List<T>> _runWithConcurrencyLimit<T>({
    required List<String> items,
    required int maxConcurrent,
    required Future<T> Function(String item) worker,
  }) async {
    final safeConcurrency = maxConcurrent < 1 ? 1 : maxConcurrent;
    final results = List<T?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> runWorker() async {
      while (true) {
        if (nextIndex >= items.length) return;
        final current = nextIndex;
        nextIndex++;
        results[current] = await worker(items[current]);
      }
    }

    final workers = List.generate(
      safeConcurrency,
      (_) => runWorker(),
      growable: false,
    );

    await Future.wait(workers);
    return results.cast<T>();
  }

  Future<ImageProcessResult> _processSingleSafe(String inputPath) async {
    try {
      final outputPath = await _processSingle(inputPath);
      return ImageProcessResult.success(
        inputPath: inputPath,
        outputPath: outputPath,
      );
    } catch (e) {
      return ImageProcessResult.error(
        inputPath: inputPath,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String> _processSingle(String inputPath) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw Exception('File non trovato: $inputPath');
    }

    _validateResizeConfig(inputPath);

    var currentPath = inputPath;

    if (_enableResize) {
      currentPath = await _applyResize(
        path: currentPath,
        width: _targetWidth,
        height: _targetHeight,
      );
    }

    if (_enableBackgroundRemove) {
      currentPath = await _applyBackgroundRemove(currentPath);
    }

    if (_enableFormatChange) {
      currentPath = await _applyFormatChange(currentPath, _targetFormat);
    }

    return currentPath;
  }

  void _validateResizeConfig(String inputPath) {
    if (!_enableResize) return;
    if (_targetWidth < 0 || _targetHeight < 0) {
      throw Exception(
        'Risoluzione non valida per "$inputPath": width e height non possono essere negativi.',
      );
    }
  }

  Future<String> _applyResize({
    required String path,
    required int width,
    required int height,
  }) async {
    if (width <= 0 && height <= 0) return path;

    final image = await _decodeImage(path);
    final size = _targetResizeSize(
      sourceWidth: image.width,
      sourceHeight: image.height,
      targetWidth: width,
      targetHeight: height,
    );

    final resized = img.copyResize(
      image,
      width: size.$1,
      height: size.$2,
      interpolation: img.Interpolation.average,
    );

    final outputFormat = _extensionOf(path);
    final outputPath = _buildOutputPath(path, '_resized', outputFormat);
    await _writeImageByFormat(resized, outputPath, outputFormat);
    return outputPath;
  }

  (int, int) _targetResizeSize({
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
  }) {
    if (targetWidth > 0 && targetHeight > 0) {
      final scaleX = targetWidth / sourceWidth;
      final scaleY = targetHeight / sourceHeight;
      final scale = math.min(scaleX, scaleY);
      final width = math.max(1, (sourceWidth * scale).round());
      final height = math.max(1, (sourceHeight * scale).round());
      return (width, height);
    }

    if (targetWidth > 0) {
      final aspect = sourceHeight / sourceWidth;
      return (targetWidth, (targetWidth * aspect).round());
    }

    final aspect = sourceWidth / sourceHeight;
    return ((targetHeight * aspect).round(), targetHeight);
  }

  Future<String> _applyBackgroundRemove(String path) async {
    if (_backgroundRemoveMode == bgModeAuto) {
      return _applyBackgroundRemoveLocal(path);
    }

    if (_backgroundRemoveMode == bgModeApi) {
      try {
        return await _applyBackgroundRemoveApi(path);
      } catch (_) {
        return _applyBackgroundRemoveLocal(path);
      }
    }
    return _applyBackgroundRemoveLocal(path);
  }

  Future<String> _applyBackgroundRemoveLocal(String path) async {
    try {
      await _ensureOnnxInitialized();
      final bytes = await File(path).readAsBytes();
      final ui.Image resultImage = await BackgroundRemover.instance.removeBg(bytes);
      final data = await resultImage.toByteData(format: ui.ImageByteFormat.png);
      resultImage.dispose();
      if (data == null) {
        throw Exception('Output ONNX non valido.');
      }

      final refinedPng = _refineRemovedBackgroundPng(data.buffer.asUint8List());

      final outputPath = _buildOutputPath(path, '_nobg', 'png');
      await File(outputPath).writeAsBytes(refinedPng, flush: true);
      return outputPath;
    } catch (_) {
      return _applyBackgroundRemoveHeuristic(path);
    }
  }

  Future<void> _ensureOnnxInitialized() async {
    _onnxInitFuture ??= BackgroundRemover.instance.initializeOrt();
    await _onnxInitFuture;
  }

  Future<String> _applyBackgroundRemoveHeuristic(String path) async {
    final image = await _decodeImage(path);
    final rgba = _toRgba(image);

    final samplePoints = _edgeSamplePoints(rgba.width, rgba.height);
    final bgColor = _estimateBackgroundColor(rgba, samplePoints);
    final tolerance = _dynamicTolerance(rgba, bgColor, samplePoints);

    _removeConnectedBackground(
      image: rgba,
      bgColor: bgColor,
      tolerance: tolerance,
    );
    _refineBackgroundMask(
      image: rgba,
      bgColor: bgColor,
      tolerance: tolerance,
    );

    final outputPath = _buildOutputPath(path, '_nobg', 'png');
    await File(outputPath).writeAsBytes(img.encodePng(rgba, level: 6), flush: true);
    return outputPath;
  }

  List<int> _refineRemovedBackgroundPng(Uint8List pngBytes) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return pngBytes;

    final rgba = _toRgba(decoded);
    final width = rgba.width;
    final height = rgba.height;
    final length = width * height;

    final alpha = Uint8List(length);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        alpha[i++] = rgba.getPixel(x, y).a.toInt();
      }
    }

    final blurredAlpha = _boxBlurAlpha(alpha, width, height);
    i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = rgba.getPixel(x, y);
        final refined = _refineAlphaValue(blurredAlpha[i]);
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();
        if (refined == 0) {
          rgba.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          rgba.setPixelRgba(x, y, red, green, blue, refined);
        }
        i++;
      }
    }

    return img.encodePng(rgba, level: 6);
  }

  Uint8List _boxBlurAlpha(Uint8List alpha, int width, int height) {
    final out = Uint8List(alpha.length);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var sum = 0;
        var count = 0;
        for (var ky = -1; ky <= 1; ky++) {
          final yy = y + ky;
          if (yy < 0 || yy >= height) continue;
          for (var kx = -1; kx <= 1; kx++) {
            final xx = x + kx;
            if (xx < 0 || xx >= width) continue;
            sum += alpha[yy * width + xx];
            count++;
          }
        }
        out[y * width + x] = (sum / count).round();
      }
    }
    return out;
  }

  int _refineAlphaValue(int alpha) {
    const low = 14;
    const high = 245;
    if (alpha <= low) return 0;
    if (alpha >= high) return 255;
    final t = (alpha - low) / (high - low);
    final smooth = t * t * (3 - 2 * t);
    return (smooth * 255).round().clamp(0, 255);
  }

  Future<String> _applyBackgroundRemoveApi(String path) async {
    if (_backgroundApiEndpoint.trim().isEmpty) {
      throw Exception('Endpoint API scontorno mancante in impostazioni.');
    }
    if (_backgroundApiKey.trim().isEmpty) {
      throw Exception('API key scontorno mancante in impostazioni.');
    }

    final uri = Uri.parse(_backgroundApiEndpoint.trim());
    final request = http.MultipartRequest('POST', uri)
      ..fields['size'] = 'auto'
      ..files.add(await http.MultipartFile.fromPath('image_file', path));

    final key = _backgroundApiKey.trim();
    if (key.toLowerCase().startsWith('bearer ')) {
      request.headers['Authorization'] = key;
    } else {
      request.headers['X-Api-Key'] = key;
    }

    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final body = String.fromCharCodes(bytes);
      throw Exception(
        'Errore API scontorno (${streamed.statusCode}): ${body.isEmpty ? 'nessun dettaglio' : body}',
      );
    }

    if (bytes.isEmpty) {
      throw Exception('Risposta API scontorno vuota.');
    }

    final outputPath = _buildOutputPath(path, '_nobg', 'png');
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  Future<String> _applyFormatChange(String path, String format) async {
    final normalizedFormat = _normalizeFormat(format);
    final image = await _decodeImage(path);
    final outputPath = _buildOutputPath(path, '_format', normalizedFormat);
    await _writeImageByFormat(image, outputPath, normalizedFormat);
    return outputPath;
  }

  Future<img.Image> _decodeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Immagine non leggibile o formato non supportato: $path');
    }
    return decoded;
  }

  img.Image _toRgba(img.Image source) {
    final rgba = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        rgba.setPixelRgba(
          x,
          y,
          p.r.toInt(),
          p.g.toInt(),
          p.b.toInt(),
          p.a.toInt(),
        );
      }
    }

    return rgba;
  }

  Future<void> _writeImageByFormat(
    img.Image image,
    String outputPath,
    String format,
  ) async {
    late final List<int> encoded;
    switch (format) {
      case 'png':
        encoded = img.encodePng(image, level: 6);
        break;
      case 'jpg':
        encoded = img.encodeJpg(image, quality: _jpegQuality);
        break;
      case 'webp':
        encoded = img.encodePng(image, level: 6);
        break;
      default:
        throw Exception('Formato non supportato: $format');
    }
    await File(outputPath).writeAsBytes(encoded, flush: true);
  }

  String _normalizeFormat(String format) {
    final normalized = format.trim().toLowerCase();
    if (normalized == 'jpeg') return 'jpg';
    if (normalized == 'webp') return 'png';
    if (_supportedFormats.contains(normalized)) return normalized;
    throw ArgumentError('Formato non supportato: $format. Usa webp, jpg o png.');
  }

  String _buildOutputPath(String originalPath, String suffix, String extension) {
    final originalFile = File(originalPath);
    final directory = originalFile.parent.path;
    final name = _basenameWithoutExtension(originalPath);
    return '$directory${Platform.pathSeparator}${name}$suffix.$extension';
  }

  String _basenameWithoutExtension(String path) {
    final normalized = path.replaceAll('\\', '/');
    final filename = normalized.split('/').last;
    final dot = filename.lastIndexOf('.');
    if (dot <= 0) return filename;
    return filename.substring(0, dot);
  }

  String _extensionOf(String path) {
    final filename = path.replaceAll('\\', '/').split('/').last.toLowerCase();
    if (filename.endsWith('.jpeg') || filename.endsWith('.jpg')) return 'jpg';
    if (filename.endsWith('.png')) return 'png';
    if (filename.endsWith('.webp')) return 'webp';
    return 'png';
  }

  List<_Point> _edgeSamplePoints(int width, int height) {
    final maxX = width - 1;
    final maxY = height - 1;
    return <_Point>[
      _Point(0, 0),
      _Point(maxX, 0),
      _Point(0, maxY),
      _Point(maxX, maxY),
      _Point(width ~/ 2, 0),
      _Point(width ~/ 2, maxY),
      _Point(0, height ~/ 2),
      _Point(maxX, height ~/ 2),
    ];
  }

  _Rgb _estimateBackgroundColor(img.Image image, List<_Point> points) {
    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;

    for (final p in points) {
      final pixel = image.getPixel(p.x, p.y);
      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;
    }

    final count = points.length.toDouble();
    return _Rgb(
      (red / count).round(),
      (green / count).round(),
      (blue / count).round(),
    );
  }

  int _dynamicTolerance(img.Image image, _Rgb bgColor, List<_Point> points) {
    var maxDistSquared = 0;

    for (final p in points) {
      final pixel = image.getPixel(p.x, p.y);
      final distanceSquared = _colorDistanceSquared(
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        bgColor.r,
        bgColor.g,
        bgColor.b,
      );
      if (distanceSquared > maxDistSquared) {
        maxDistSquared = distanceSquared;
      }
    }

    final tolerance = (math.sqrt(maxDistSquared) + 22).round();
    return tolerance.clamp(18, 56);
  }

  void _removeConnectedBackground({
    required img.Image image,
    required _Rgb bgColor,
    required int tolerance,
  }) {
    final width = image.width;
    final height = image.height;
    final toleranceSquared = tolerance * tolerance;

    final visited = Uint8List(width * height);
    final queue = ListQueue<_Point>();

    void enqueueIfBackground(int x, int y) {
      final index = y * width + x;
      if (visited[index] == 1) return;

      final pixel = image.getPixel(x, y);
      final isBackground = _colorDistanceSquared(
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
            bgColor.r,
            bgColor.g,
            bgColor.b,
          ) <=
          toleranceSquared;

      if (!isBackground) return;

      visited[index] = 1;
      queue.add(_Point(x, y));
    }

    for (var x = 0; x < width; x++) {
      enqueueIfBackground(x, 0);
      enqueueIfBackground(x, height - 1);
    }
    for (var y = 0; y < height; y++) {
      enqueueIfBackground(0, y);
      enqueueIfBackground(width - 1, y);
    }

    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      final pixel = image.getPixel(p.x, p.y);
      image.setPixelRgba(
        p.x,
        p.y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        0,
      );

      if (p.x > 0) enqueueIfBackground(p.x - 1, p.y);
      if (p.x < width - 1) enqueueIfBackground(p.x + 1, p.y);
      if (p.y > 0) enqueueIfBackground(p.x, p.y - 1);
      if (p.y < height - 1) enqueueIfBackground(p.x, p.y + 1);
    }
  }

  void _refineBackgroundMask({
    required img.Image image,
    required _Rgb bgColor,
    required int tolerance,
  }) {
    final hardThreshold = ((tolerance * 0.85) * (tolerance * 0.85)).round();
    final softThreshold = ((tolerance * 1.20) * (tolerance * 1.20)).round();

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha == 0) continue;

        final distanceSquared = _colorDistanceSquared(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          bgColor.r,
          bgColor.g,
          bgColor.b,
        );

        if (distanceSquared <= hardThreshold) {
          image.setPixelRgba(
            x,
            y,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
            0,
          );
        } else if (distanceSquared <= softThreshold) {
          final softAlpha = math.min(alpha, 160);
          image.setPixelRgba(
            x,
            y,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
            softAlpha,
          );
        }
      }
    }
  }

  int _colorDistanceSquared(int r1, int g1, int b1, int r2, int g2, int b2) {
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return dr * dr + dg * dg + db * db;
  }
}

class _Point {
  final int x;
  final int y;

  const _Point(this.x, this.y);
}

class _Rgb {
  final int r;
  final int g;
  final int b;

  const _Rgb(this.r, this.g, this.b);
}

class ImageProcessResult {
  final String inputPath;
  final String? outputPath;
  final bool success;
  final String? errorMessage;

  const ImageProcessResult._({
    required this.inputPath,
    required this.outputPath,
    required this.success,
    required this.errorMessage,
  });

  factory ImageProcessResult.success({
    required String inputPath,
    required String outputPath,
  }) {
    return ImageProcessResult._(
      inputPath: inputPath,
      outputPath: outputPath,
      success: true,
      errorMessage: null,
    );
  }

  factory ImageProcessResult.error({
    required String inputPath,
    required String errorMessage,
  }) {
    return ImageProcessResult._(
      inputPath: inputPath,
      outputPath: null,
      success: false,
      errorMessage: errorMessage,
    );
  }
}
