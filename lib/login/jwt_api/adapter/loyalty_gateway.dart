import '../query_mgws/query_mgws_loyalty.dart';

class LoyaltyGateway {
  LoyaltyGateway();

  final QueryMgwsLoyalty _mgws = QueryMgwsLoyalty();

  Future<int> getCustomerPoints(int customerId) {
    return _mgws.getCustomerPoints(customerId);
  }

  Future<bool> addPointsToCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) {
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
  }) {
    return _mgws.deductPointsFromCustomer(
      customerId: customerId,
      points: points,
      reference: reference,
      note: note,
    );
  }

  Future<Map<String, dynamic>?> getCustomerLoyaltyCard(int customerId) {
    return _mgws.getCustomerLoyaltyCard(customerId);
  }

  Future<Map<String, dynamic>?> findCustomerByCardNumber(String cardNumber) {
    return _mgws.findCustomerByCardNumber(cardNumber);
  }

  Future<Map<String, dynamic>?> findCustomerByEmail(String email) {
    return _mgws.findCustomerByEmail(email);
  }

  Future<bool> createOrUpdateLoyaltyCard({
    required int customerId,
    required String cardNumber,
    String tier = 'bronze',
  }) {
    return _mgws.createOrUpdateLoyaltyCard(
      customerId: customerId,
      cardNumber: cardNumber,
      tier: tier,
    );
  }

  Future<bool> removeLoyaltyCard(int customerId) {
    return _mgws.removeLoyaltyCard(customerId);
  }

  Future<List<Map<String, dynamic>>> getPointsHistory(
    int customerId, {
    int page = 1,
    int perPage = 20,
  }) {
    return _mgws.getPointsHistory(customerId, page: page, perPage: perPage);
  }

  Future<Map<String, dynamic>> getLoyaltyStats() {
    return _mgws.getLoyaltyStats();
  }

  Future<bool> isLoyaltyAvailable() {
    return _mgws.isLoyaltyAvailable();
  }
}
