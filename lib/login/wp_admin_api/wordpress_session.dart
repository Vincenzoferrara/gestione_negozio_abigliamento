/// Modello sessione per autenticazione WordPress via Application Passwords.
///
/// Le Application Passwords non scadono (possono essere revocate solo
/// manualmente dal profilo WordPress). Non serve `expiresAt`.
class WordPressSession {
  final String username;
  final String appPassword;
  final String siteUrl;
  final String deviceId;
  final DateTime createdAt;

  WordPressSession({
    required this.username,
    required this.appPassword,
    required this.siteUrl,
    required this.deviceId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Serializzazione JSON
  factory WordPressSession.fromJson(Map<String, dynamic> json) {
    return WordPressSession(
      username: json['username'] as String,
      appPassword: json['app_password'] as String,
      siteUrl: json['site_url'] as String,
      deviceId: json['device_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'app_password': appPassword,
      'site_url': siteUrl,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Nessuna password in chiaro nei log
  @override
  String toString() => 'WordPressSession(username: $username, siteUrl: $siteUrl)';
}
