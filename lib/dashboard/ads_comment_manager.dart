// Ads Comment Manager - Sistema per gestire commenti cifrati sulle inserzioni
//
// Storage locale con cifratura semplice per commenti persistenti
// Mantiene l'associazione con le inserzioni per 3+ anni

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../log_viewer/app_logger.dart';

/// Modello per un commento su un'inserzione
class AdsComment {
  final String adId; // ID univoco dell'inserzione (es. "meta_campaign_123")
  final String platform; // Piattaforma: meta, google, tiktok, instagram
  final String accountId; // ID dell'account/cliente (per multi-utente)
  final String comment; // Testo del commento
  final DateTime timestamp; // Data creazione
  final DateTime lastModified; // Data ultima modifica

  AdsComment({
    required this.adId,
    required this.platform,
    required this.accountId,
    required this.comment,
    required this.timestamp,
    required this.lastModified,
  });

  /// Genera la chiave univoca per questo commento (accountId + platform + adId)
  String get uniqueKey => '${accountId}_${platform}_$adId';

  Map<String, dynamic> toJson() => {
    'adId': adId,
    'platform': platform,
    'accountId': accountId,
    'comment': comment,
    'timestamp': timestamp.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
  };

  factory AdsComment.fromJson(Map<String, dynamic> json) => AdsComment(
    adId: json['adId'],
    platform: json['platform'],
    accountId: json['accountId'],
    comment: json['comment'],
    timestamp: DateTime.parse(json['timestamp']),
    lastModified: DateTime.parse(json['lastModified']),
  );
}

/// Manager per gestire i commenti con cifratura
class AdsCommentManager {
  static final AdsCommentManager _instance = AdsCommentManager._internal();
  factory AdsCommentManager() => _instance;
  AdsCommentManager._internal();

  // Cache dei commenti in memoria
  final Map<String, AdsComment> _comments = {};

  // Chiave di cifratura (generata da un seed fisso del dispositivo)
  late encrypt.Key _key;
  late encrypt.IV _iv;
  late encrypt.Encrypter _encrypter;

  bool _initialized = false;

  /// Inizializza il manager e carica i commenti salvati
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Genera chiave di cifratura basata su un seed fisso
      // Usa un identificatore del dispositivo o un valore fisso
      final seedString = 'ads_comments_encryption_key_2024';
      final keyBytes = sha256.convert(utf8.encode(seedString)).bytes;
      _key = encrypt.Key(Uint8List.fromList(keyBytes));

      // IV fisso per semplicità (in produzione potrebbe essere randomizzato per file)
      _iv = encrypt.IV.fromLength(16);

      _encrypter = encrypt.Encrypter(encrypt.AES(_key));

      // Carica i commenti dal file
      await _loadComments();

      _initialized = true;
    } catch (e) {
      log.e('ADS_COMMENT_MANAGER - Errore inizializzazione', e);
      _initialized = false;
    }
  }

  /// Ottiene il path del file dei commenti
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/ads_comments.encrypted';
  }

  /// Carica i commenti dal file cifrato
  Future<void> _loadComments() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        log.d(
          'ADS_COMMENT_MANAGER - File commenti non esiste, creazione nuovo',
        );
        return;
      }

      final encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        log.d('ADS_COMMENT_MANAGER - File commenti vuoto');
        return;
      }

      // Decifra il contenuto
      final decrypted = _encrypter.decrypt64(encryptedContent, iv: _iv);
      final jsonData = json.decode(decrypted) as Map<String, dynamic>;

      // Carica i commenti nella cache
      _comments.clear();
      jsonData.forEach((key, value) {
        _comments[key] = AdsComment.fromJson(value);
      });

      log.d('ADS_COMMENT_MANAGER - Caricati ${_comments.length} commenti');
    } catch (e) {
      log.e('ADS_COMMENT_MANAGER - Errore caricamento commenti', e);
      // In caso di errore, continua con cache vuota
      _comments.clear();
    }
  }

  /// Salva i commenti nel file cifrato
  Future<void> _saveComments() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // Converti i commenti in JSON
      final jsonData = <String, dynamic>{};
      _comments.forEach((key, value) {
        jsonData[key] = value.toJson();
      });

      // Cifra il contenuto
      final jsonString = json.encode(jsonData);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

      // Salva nel file
      await file.writeAsString(encrypted.base64);

      log.d('ADS_COMMENT_MANAGER - Salvati ${_comments.length} commenti');
    } catch (e) {
      log.e('ADS_COMMENT_MANAGER - Errore salvataggio commenti', e);
    }
  }

  /// Aggiunge o aggiorna un commento (con supporto multi-utente)
  Future<void> setComment(
    String adId,
    String platform,
    String accountId,
    String comment,
  ) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final uniqueKey = '${accountId}_${platform}_$adId';
    final existingComment = _comments[uniqueKey];

    _comments[uniqueKey] = AdsComment(
      adId: adId,
      platform: platform,
      accountId: accountId,
      comment: comment,
      timestamp: existingComment?.timestamp ?? now,
      lastModified: now,
    );

    await _saveComments();
  }

  /// Ottiene un commento per un'inserzione specifica di un account
  AdsComment? getComment(String adId, String platform, String accountId) {
    if (!_initialized) return null;
    final uniqueKey = '${accountId}_${platform}_$adId';
    return _comments[uniqueKey];
  }

  /// Verifica se esiste un commento per un'inserzione specifica di un account
  bool hasComment(String adId, String platform, String accountId) {
    if (!_initialized) return false;
    final uniqueKey = '${accountId}_${platform}_$adId';
    return _comments.containsKey(uniqueKey);
  }

  /// Rimuove un commento specifico di un account
  Future<void> removeComment(
    String adId,
    String platform,
    String accountId,
  ) async {
    if (!_initialized) await initialize();

    final uniqueKey = '${accountId}_${platform}_$adId';
    _comments.remove(uniqueKey);
    await _saveComments();
  }

  /// Ottiene tutti i commenti per una piattaforma e account specifico
  List<AdsComment> getCommentsByPlatform(String platform, String accountId) {
    if (!_initialized) return [];
    return _comments.values
        .where(
          (comment) =>
              comment.platform == platform && comment.accountId == accountId,
        )
        .toList();
  }

  /// Ottiene tutti i commenti di un account specifico
  List<AdsComment> getCommentsByAccount(String accountId) {
    if (!_initialized) return [];
    return _comments.values
        .where((comment) => comment.accountId == accountId)
        .toList();
  }

  /// Ottiene tutti i commenti (tutti gli account)
  List<AdsComment> getAllComments() {
    if (!_initialized) return [];
    return _comments.values.toList();
  }

  /// Pulisce tutti i commenti (use with caution)
  Future<void> clearAllComments() async {
    if (!_initialized) await initialize();

    _comments.clear();
    await _saveComments();
  }

  /// Esporta i commenti in formato JSON non cifrato (per backup)
  Future<String> exportCommentsToJson() async {
    if (!_initialized) await initialize();

    final jsonData = <String, dynamic>{};
    _comments.forEach((key, value) {
      jsonData[key] = value.toJson();
    });

    return json.encode(jsonData);
  }

  /// Importa commenti da JSON (per ripristino backup)
  Future<void> importCommentsFromJson(String jsonString) async {
    if (!_initialized) await initialize();

    try {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      jsonData.forEach((key, value) {
        _comments[key] = AdsComment.fromJson(value);
      });

      await _saveComments();
    } catch (e) {
      log.e('ADS_COMMENT_MANAGER - Errore importazione commenti', e);
    }
  }
}
