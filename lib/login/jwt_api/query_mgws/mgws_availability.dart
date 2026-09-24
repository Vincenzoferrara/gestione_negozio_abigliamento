import 'query_mgws_inventory.dart';
import 'query_mgws_loyalty.dart';

abstract interface class MgwsAvailabilityChecker {
  Future<bool> check();
}

class MgwsAvailability {
  MgwsAvailability({MgwsAvailabilityChecker? checker})
    : _checker = checker ?? _DefaultMgwsAvailabilityChecker();

  final MgwsAvailabilityChecker _checker;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  Future<bool> refresh() async {
    try {
      _isAvailable = await _checker.check();
    } catch (_) {
      _isAvailable = false;
    }
    return _isAvailable;
  }

  /// Assicura che lo stato di disponibilità sia verificato dal vivo.
  /// Se il flag cached è `false` (es. check eseguito prima del login,
  /// sito cambiato, sessione rinnovata) esegue un refresh prima di decidere.
  /// Auto-ripara il flag stale che bloccava tutti i moduli MGWS.
  Future<bool> ensureAvailable() async {
    if (_isAvailable) return true;
    return refresh();
  }

  void markUnavailable() {
    _isAvailable = false;
  }
}

class _DefaultMgwsAvailabilityChecker implements MgwsAvailabilityChecker {
  @override
  Future<bool> check() async {
    final results = await Future.wait([
      QueryMgwsInventory().isInventoryServiceAvailable(),
      QueryMgwsLoyalty().isLoyaltyAvailable(),
    ]);
    return results.every((result) => result);
  }
}

MgwsAvailability? _mgwsAvailability;

MgwsAvailability get mgwsAvailability =>
    _mgwsAvailability ??= MgwsAvailability();
