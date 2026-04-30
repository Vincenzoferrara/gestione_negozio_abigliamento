import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Livelli di logging
enum LogLevel {
  debug, // Solo per sviluppo: dettagli tecnici, stack trace completi
  warning, // Anomalie non critiche, deprecazioni, fallback
  error, // Errori critici che richiedono attenzione
}

/// Servizio di logging centralizzato che salva i log su file
/// con protezione automatica delle informazioni sensibili
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late Logger _logger;
  File? _logFile;
  bool _initialized = false;

  /// Pattern per identificare informazioni sensibili
  static final _sensitivePatterns = <RegExp>[
    RegExp(r'password["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'passwd["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'pwd["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'token["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'jwt["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'bearer\s+[a-zA-Z0-9\-._~+/]+=*', caseSensitive: false),
    RegExp(r'authorization["\s:]+bearer\s+[^,}\s]+', caseSensitive: false),
    RegExp(r'api[_-]?key["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'app[_-]?password["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'secret["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'consumer[_-]?(key|secret)["\s:=]+[^,}\s]+', caseSensitive: false),
    RegExp(r'\b(c[ks]_[a-zA-Z0-9]{20,})\b', caseSensitive: false),
  ];

  /// Sanitizza un messaggio rimuovendo informazioni sensibili
  String _sanitize(dynamic message) {
    if (message == null) return 'null';

    String text = message.toString();

    // Applica tutti i pattern per mascherare le informazioni sensibili
    for (final pattern in _sensitivePatterns) {
      text = text.replaceAllMapped(pattern, (match) {
        final matched = match.group(0) ?? '';
        if (matched.contains(':') || matched.contains('=')) {
          final separator = matched.contains(':') ? ':' : '=';
          final parts = matched.split(separator);
          return '${parts[0]}$separator ***REDACTED***';
        }
        return '***REDACTED***';
      });
    }

    // Maschera anche eventuali token JWT completi (formato: xxx.yyy.zzz)
    text = text.replaceAllMapped(
      RegExp(r'eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+'),
      (match) => '***JWT_TOKEN_REDACTED***',
    );

    return text;
  }

  /// Inizializza il logger
  Future<void> init({LogLevel minLevel = LogLevel.debug}) async {
    if (_initialized) return;

    try {
      // Ottieni la directory per salvare i log
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Crea file di log con data corrente
      final now = DateTime.now();
      final fileName =
          'app_log_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.txt';
      _logFile = File('${logDir.path}/$fileName');

      // Configura il logger con formato semplice e numeri di riga
      _logger = Logger(
        filter: _CustomFilter(minLevel),
        printer: _SimplePrinter(),
        output: MultiOutput([ConsoleOutput(), _FileOutput(file: _logFile!)]),
      );

      _initialized = true;
      _logger.d(
        'Logger initialized - Level: ${minLevel.name} - File: ${_logFile!.path}',
      );
    } catch (e) {
      debugPrint('Error initializing logger: $e');
    }
  }

  /// Log debug (solo in sviluppo)
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.d(_sanitize(message), error: error, stackTrace: stackTrace);
  }

  /// Log warning
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.w(_sanitize(message), error: error, stackTrace: stackTrace);
  }

  /// Log error
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.e(
      _sanitize(message),
      error: error != null ? _sanitize(error) : null,
      stackTrace: stackTrace,
    );
  }

  // Alias per compatibilità con codice esistente
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.t(_sanitize(message), error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.i(_sanitize(message), error: error, stackTrace: stackTrace);
  }

  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) return;
    _logger.f(_sanitize(message), error: error, stackTrace: stackTrace);
  }

  /// Ottieni il percorso del file di log corrente
  String? get currentLogPath => _logFile?.path;

  /// Ottieni tutti i file di log
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) return [];

      final files = await logDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Più recenti prima
    } catch (e) {
      debugPrint('Error reading log files: $e');
      return [];
    }
  }

  /// Leggi il contenuto di un file di log
  Future<String> readLogFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  /// Cancella il contenuto di tutti i file di log (mantiene i file)
  Future<void> clearAllLogs() async {
    try {
      final files = await getAllLogFiles();

      for (final file in files) {
        if (await file.exists()) {
          // Svuota il contenuto del file invece di eliminarlo
          await file.writeAsString('', flush: true);
        }
      }

      // Resetta il contatore delle righe
      _SimplePrinter._lineNumber = 0;

      debugPrint('All log files cleared (${files.length} files)');
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}

/// Filtro personalizzato per gestire i 3 livelli
class _CustomFilter extends LogFilter {
  final LogLevel minLevel;

  _CustomFilter(this.minLevel);

  @override
  bool shouldLog(LogEvent event) {
    // In release mode, logga solo warning ed error
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }

    // In debug mode, rispetta il minLevel configurato
    switch (minLevel) {
      case LogLevel.debug:
        return true; // Logga tutto
      case LogLevel.warning:
        return event.level.index >= Level.warning.index;
      case LogLevel.error:
        return event.level.index >= Level.error.index;
    }
  }
}

/// Printer personalizzato semplice con numeri di riga come un IDE
class _SimplePrinter extends LogPrinter {
  static int _lineNumber = 0;
  static final _levelNames = {
    Level.trace: 'TRACE  ',
    Level.debug: 'DEBUG  ',
    Level.info: 'INFO   ',
    Level.warning: 'WARNING',
    Level.error: 'ERROR  ',
    Level.fatal: 'FATAL  ',
  };

  @override
  List<String> log(LogEvent event) {
    final lines = <String>[];
    final timestamp = DateTime.now().toString().substring(
      0,
      19,
    ); // yyyy-MM-dd HH:mm:ss
    final level = _levelNames[event.level] ?? 'UNKNOWN';
    _lineNumber++;

    // Formato: [LINE] TIMESTAMP [LEVEL] Message
    lines.add('[$_lineNumber] $timestamp [$level] ${event.message}');

    // Se c'è un errore, aggiungilo
    if (event.error != null) {
      _lineNumber++;
      lines.add('[$_lineNumber] $timestamp [$level] Error: ${event.error}');
    }

    // Se c'è uno stack trace, aggiungilo (solo prime 10 righe)
    if (event.stackTrace != null && event.level.index >= Level.error.index) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (final line in stackLines.take(10)) {
        if (line.trim().isEmpty) continue;
        _lineNumber++;
        lines.add('[$_lineNumber] $timestamp [$level] $line');
      }
    }

    return lines;
  }
}

/// Output personalizzato per salvare su file
class _FileOutput extends LogOutput {
  final File file;

  _FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    try {
      final buffer = StringBuffer();
      for (var line in event.lines) {
        buffer.writeln(line);
      }
      file.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Error writing log to file: $e');
    }
  }
}

/// Shortcut globale per accedere al logger
final log = AppLogger();
