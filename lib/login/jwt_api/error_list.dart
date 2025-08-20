/// Classe base per tutte le eccezioni specifiche della nostra API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// --- ERRORI DI CONNESSIONE E RETE ---
class NetworkException extends ApiException {
  NetworkException() : super('Errore di rete. Controlla la tua connessione e l\'URL del sito.');
}
class TimeoutException extends ApiException {
  TimeoutException() : super('Il server non ha risposto in tempo. Riprova più tardi.');
}

// --- ERRORI DI AUTENTICAZIONE (4xx) ---
class InvalidCredentialsException extends ApiException {
  InvalidCredentialsException(String message) : super(message, statusCode: 403);
}
class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Sessione non valida o scaduta. Effettua nuovamente il login.', statusCode: 401);
}
class ForbiddenException extends ApiException {
  ForbiddenException() : super('Permessi insufficienti per eseguire questa operazione.', statusCode: 403);
}
class NotFoundException extends ApiException {
  NotFoundException(String resource) : super('Risorsa non trovata: $resource. Plugin disattivo o URL errato?', statusCode: 404);
}

// --- ERRORI DEL SERVER (5xx) ---
class ServerException extends ApiException {
  ServerException() : super('Si è verificato un errore interno del server. Riprova più tardi.', statusCode: 500);
}

// --- ERRORI SPECIFICI DELL'APPLICAZIONE ---
class InvalidResponseException extends ApiException {
  InvalidResponseException() : super('La risposta del server non è in un formato valido.');
}