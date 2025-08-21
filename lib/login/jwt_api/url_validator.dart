class UrlValidator {
  /// Controlla se un host è un IP locale o riservato.
  static bool isLocalOrReservedIp(String host) {
    if (host.toLowerCase() == 'localhost' || host == '127.0.0.1' || host == '::1') return true;
    
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(host)) return false;

    final parts = host.split('.').map((p) => int.tryParse(p) ?? 256).toList();
    if (parts.any((p) => p > 255)) return false;
    
    if (parts[0] == 10) return true;
    if (parts[0] == 127) return true;
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    if (parts[0] == 192 && parts[1] == 168) return true;

    return false;
  }
  
  /// Valida un URL completo.
  static String? validateUrl(String? value, {bool allowLocalhost = false}) {
    if (value == null || value.isEmpty) {
      return 'Inserisci l\'URL del tuo sito';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isAbsolute) {
      return allowLocalhost 
          ? 'URL non valido (es. http://localhost)' 
          : 'URL non valido (es. https://...)';
    }

    bool isLocal = isLocalOrReservedIp(uri.host);
    
    if (isLocal && !allowLocalhost) {
      return 'Per indirizzi locali, abilita la modalità sviluppo.';
    }
    
    if (!isLocal && uri.scheme != 'https') {
      return 'Le connessioni a siti esterni devono usare HTTPS.';
    }
    
    return null; // L'URL è valido
  }
}