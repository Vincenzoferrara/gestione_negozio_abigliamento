import 'package:dio/dio.dart';
import '../../../log_viewer/app_logger.dart';
import '../../jwt_api/woo_connect.dart';

/// Motivo per cui MGWS risulta non utilizzabile.
///
/// L'avviso mostrato all'utente distingue i tre casi perche' richiedono
/// interventi diversi: un backend irraggiungibile e' un problema di rete o di
/// URL, un servizio spento e' un problema di configurazione del plugin, le
/// tabelle mancanti indicano un'installazione incompleta.
enum MgwsUnavailableReason {
  /// MGWS non e' mai stato verificato nella sessione corrente.
  unknown,

  /// Nessuna sessione WordPress attiva: le rotte MGWS non possono partire.
  noSession,

  /// Le rotte di stato non rispondono o rispondono con errore.
  unreachable,

  /// Le rotte rispondono ma il servizio e' disabilitato (`enabled: false`).
  serviceDisabled,
}

/// Verifica di stato dei servizi MGWS.
///
/// Sta in `connection/` e non importa i client di `query/`: la disponibilita'
/// di MGWS non deve dipendere da un client specifico, altrimenti lo stato
/// erediterebbe i difetti di quel client. Le rotte di stato sono lette qui
/// direttamente, con il Dio autenticato del connettore attivo.
class MgwsAuth {
  MgwsAuth({WooConnect? woo}) : _woo = woo ?? WooConnect();

  final WooConnect _woo;
  final AppLogger _log = AppLogger();

  static const String _inventoryStatusPath = '/wp-json/mgws/v1/inventory/status';
  static const String _loyaltyStatusPath = '/wp-json/mgws/v1/loyalty/status';

  /// Verifica MGWS e restituisce l'esito con il motivo dell'eventuale
  /// fallimento. Non solleva eccezioni: un errore di rete e' un esito
  /// negativo, non un'eccezione da gestire a monte.
  Future<MgwsAuthResult> verify() async {
    if (!_woo.isAuthenticated) {
      return const MgwsAuthResult(
        available: false,
        reason: MgwsUnavailableReason.noSession,
      );
    }

    final siteUrl = _woo.siteUrl;
    if (siteUrl == null || siteUrl.isEmpty) {
      return const MgwsAuthResult(
        available: false,
        reason: MgwsUnavailableReason.noSession,
      );
    }

    try {
      final dio = _woo.getAuthenticatedDio();
      final results = await Future.wait([
        _readServiceStatus(dio, siteUrl, _inventoryStatusPath),
        _readServiceStatus(dio, siteUrl, _loyaltyStatusPath),
      ]);

      // Un solo servizio spento rende MGWS inutilizzabile: inventario e
      // loyalty sono le due funzionalita' che i moduli MGWS espongono, e
      // un'installazione parziale produrrebbe errori a meta' operazione.
      final failed = results.where((result) => !result.usable).toList();
      if (failed.isEmpty) {
        return const MgwsAuthResult(
          available: true,
          reason: MgwsUnavailableReason.unknown,
        );
      }

      final reachable = results.any((result) => result.reachable);
      return MgwsAuthResult(
        available: false,
        reason: reachable
            ? MgwsUnavailableReason.serviceDisabled
            : MgwsUnavailableReason.unreachable,
      );
    } catch (e) {
      _log.w('MGWS non raggiungibile: $e');
      return const MgwsAuthResult(
        available: false,
        reason: MgwsUnavailableReason.unreachable,
      );
    }
  }

  Future<_ServiceProbe> _readServiceStatus(
    Dio dio,
    String siteUrl,
    String path,
  ) async {
    try {
      final response = await dio.get<dynamic>('$siteUrl$path');
      if (response.statusCode != 200) {
        return const _ServiceProbe(reachable: false, usable: false);
      }
      return _ServiceProbe(
        reachable: true,
        usable: isServiceBodyUsable(response.data),
      );
    } catch (_) {
      return const _ServiceProbe(reachable: false, usable: false);
    }
  }

  /// Le rotte `status` rispondono 200 anche quando il servizio e' spento, per
  /// esempio con le tabelle MGWS non installate: in quel caso `enabled` e
  /// `ok` valgono `false`. Guardare solo lo status HTTP dichiarerebbe MGWS
  /// disponibile e ogni chiamata reale fallirebbe sul campo, quindi la
  /// disponibilita' si legge dal corpo della risposta.
  ///
  /// Vive qui e non nel trasporto perche' e' la lettura del contratto di
  /// stato MGWS: [MgwsConnection] e i client di `query/` devono condividere
  /// la stessa interpretazione del corpo.
  static bool isServiceUsable(Response<dynamic> response) {
    if (response.statusCode != 200) return false;
    return isServiceBodyUsable(response.data);
  }

  static bool isServiceBodyUsable(Object? data) {
    if (data is! Map) return true;
    final enabled = data['enabled'];
    if (enabled is bool) return enabled;
    final ok = data['ok'];
    if (ok is bool) return ok;
    return true;
  }
}

class MgwsAuthResult {
  const MgwsAuthResult({required this.available, required this.reason});

  final bool available;
  final MgwsUnavailableReason reason;
}

class _ServiceProbe {
  const _ServiceProbe({required this.reachable, required this.usable});

  /// La rotta ha risposto qualcosa, anche se il servizio e' spento.
  final bool reachable;

  /// Il servizio dichiara di poter operare.
  final bool usable;
}
