import '../query_mgws/query_mgws_loyalty.dart';
import '../query_mgws/mgws_availability.dart';

class LoyaltyGateway {
  LoyaltyGateway({MgwsAvailability? availability})
    : _availability = availability ?? mgwsAvailability;

  final QueryMgwsLoyalty _mgws = QueryMgwsLoyalty();
  final MgwsAvailability _availability;

  Future<int> getCustomerPoints(int customerId) async {
    if (!_availability.isAvailable) return 0;
    return _mgws.getCustomerPoints(customerId);
  }

  Future<bool> addPointsToCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    if (!_availability.isAvailable) return false;
    return _mgws.addPointsToCustomer(
      customerId: customerId,
      points: points,
      reference: reference,
      note: note,
    );
  }

  Future<bool> deductPointsFromCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    if (!_availability.isAvailable) return false;
    return _mgws.deductPointsFromCustomer(
      customerId: customerId,
      points: points,
      reference: reference,
      note: note,
    );
  }

  Future<Map<String, dynamic>?> getCustomerLoyaltyCard(int customerId) async {
    if (!_availability.isAvailable) return null;
    return _mgws.getCustomerLoyaltyCard(customerId);
  }

  Future<Map<String, dynamic>?> findCustomerByCardNumber(
    String cardNumber,
  ) async {
    if (!_availability.isAvailable) return null;
    return _mgws.findCustomerByCardNumber(cardNumber);
  }

  Future<Map<String, dynamic>?> findCustomerByEmail(String email) async {
    if (!_availability.isAvailable) return null;
    return _mgws.findCustomerByEmail(email);
  }

  Future<bool> createOrUpdateLoyaltyCard({
    required int customerId,
    required String cardNumber,
    String tier = 'bronze',
  }) async {
    if (!_availability.isAvailable) return false;
    return _mgws.createOrUpdateLoyaltyCard(
      customerId: customerId,
      cardNumber: cardNumber,
      tier: tier,
    );
  }

  Future<bool> removeLoyaltyCard(int customerId) async {
    if (!_availability.isAvailable) return false;
    return _mgws.removeLoyaltyCard(customerId);
  }

  Future<List<Map<String, dynamic>>> getPointsHistory(
    int customerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    if (!_availability.isAvailable) return const <Map<String, dynamic>>[];
    return _mgws.getPointsHistory(customerId, page: page, perPage: perPage);
  }

  Future<Map<String, dynamic>> getLoyaltyStats() async {
    if (!_availability.isAvailable) return const <String, dynamic>{};
    return _mgws.getLoyaltyStats();
  }

  Future<bool> isLoyaltyAvailable() async => _availability.isAvailable;
}
