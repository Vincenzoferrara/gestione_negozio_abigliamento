import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';

/// Query class per la gestione dei clienti WooCommerce
/// Utilizza JwtConnect per l'autenticazione centralizzata
class WooQueryClienti {
  // Singleton pattern
  static final WooQueryClienti _instance = WooQueryClienti._internal();
  factory WooQueryClienti() => _instance;
  WooQueryClienti._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;

  /// Ottiene l'istanza WooCommerce con autenticazione JWT
  WooCommerce _getWooCommerce() {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    if (_woo != null) return _woo!;

    _woo = WooCommerce(
      baseUrl: _auth.currentSiteUrl!,
      username: '',
      password: '',
      useFaker: false,
      isDebug: false,
    );

    // Usa il Dio autenticato di JwtConnect
    _woo!.dio = _auth.getAuthenticatedDio();
    return _woo!;
  }

  /// Reset dell'istanza WooCommerce (utile dopo logout)
  void reset() {
    _woo = null;
  }

  /// Ottiene lista clienti con paginazione e filtri
  Future<List<WooCustomer>> getCustomers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? email,
    WooCustomerRole? role,
    WooCustomerSort orderBy = WooCustomerSort.registered_date,
    WooSortOrder order = WooSortOrder.desc,
  }) async {
    final woo = _getWooCommerce();

    return await woo.getCustomers(
      page: page,
      perPage: perPage,
      search: search,
      email: email,
      role: role ?? WooCustomerRole.customer,
      orderby: orderBy,
      order: order,
    );
  }

  /// Ottiene un cliente specifico per ID
  Future<WooCustomer> getCustomerById(int customerId) async {
    final woo = _getWooCommerce();
    return await woo.getCustomer(customerId);
  }

  /// Cerca clienti per email
  Future<List<WooCustomer>> searchCustomersByEmail(String email) async {
    final woo = _getWooCommerce();
    return await woo.getCustomers(
      email: email,
      perPage: 100,
    );
  }

  /// Cerca clienti per nome o cognome
  Future<List<WooCustomer>> searchCustomersByName(String searchTerm) async {
    final woo = _getWooCommerce();
    return await woo.getCustomers(
      search: searchTerm,
      perPage: 100,
    );
  }

  /// Crea un nuovo cliente
  Future<WooCustomer> createCustomer({
    required String email,
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    WooBilling? billing,
    WooShipping? shipping,
    List<WooMetaData>? metaData,
  }) async {
    final woo = _getWooCommerce();

    final customer = WooCustomer(
      email: email,
      firstName: firstName,
      lastName: lastName,
      username: username,
      password: password,
      billing: billing,
      shipping: shipping,
      metaData: metaData,
    );

    return await woo.createCustomer(customer);
  }

  /// Aggiorna un cliente esistente
  Future<WooCustomer> updateCustomer({
    required int customerId,
    String? email,
    String? firstName,
    String? lastName,
    WooBilling? billing,
    WooShipping? shipping,
    List<WooMetaData>? metaData,
  }) async {
    final woo = _getWooCommerce();

    // Prima ottieni il cliente esistente
    final existingCustomer = await woo.getCustomer(customerId);

    // Crea un nuovo cliente con i campi aggiornati
    final updatedCustomer = WooCustomer(
      id: customerId,
      email: email ?? existingCustomer.email,
      firstName: firstName ?? existingCustomer.firstName,
      lastName: lastName ?? existingCustomer.lastName,
      billing: billing ?? existingCustomer.billing,
      shipping: shipping ?? existingCustomer.shipping,
      metaData: metaData ?? existingCustomer.metaData,
      username: existingCustomer.username,
      role: existingCustomer.role,
    );

    return await woo.updateCustomer(updatedCustomer);
  }

  /// Aggiorna l'indirizzo di fatturazione di un cliente
  Future<WooCustomer> updateBillingAddress({
    required int customerId,
    String? firstName,
    String? lastName,
    String? company,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? email,
    String? phone,
  }) async {
    // Ottieni il cliente esistente
    final existingCustomer = await getCustomerById(customerId);
    final existingBilling = existingCustomer.billing;

    final billing = WooBilling(
      firstName: firstName ?? existingBilling?.firstName,
      lastName: lastName ?? existingBilling?.lastName,
      company: company ?? existingBilling?.company,
      address1: address1 ?? existingBilling?.address1,
      address2: address2 ?? existingBilling?.address2,
      city: city ?? existingBilling?.city,
      state: state ?? existingBilling?.state,
      postcode: postcode ?? existingBilling?.postcode,
      country: country ?? existingBilling?.country,
      email: email ?? existingBilling?.email,
      phone: phone ?? existingBilling?.phone,
    );

    return await updateCustomer(
      customerId: customerId,
      billing: billing,
    );
  }

  /// Aggiorna l'indirizzo di spedizione di un cliente
  Future<WooCustomer> updateShippingAddress({
    required int customerId,
    String? firstName,
    String? lastName,
    String? company,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
  }) async {
    // Ottieni il cliente esistente
    final existingCustomer = await getCustomerById(customerId);
    final existingShipping = existingCustomer.shipping;

    final shipping = WooShipping(
      firstName: firstName ?? existingShipping?.firstName,
      lastName: lastName ?? existingShipping?.lastName,
      company: company ?? existingShipping?.company,
      address1: address1 ?? existingShipping?.address1,
      address2: address2 ?? existingShipping?.address2,
      city: city ?? existingShipping?.city,
      state: state ?? existingShipping?.state,
      postcode: postcode ?? existingShipping?.postcode,
      country: country ?? existingShipping?.country,
    );

    return await updateCustomer(
      customerId: customerId,
      shipping: shipping,
    );
  }

  /// Elimina un cliente
  Future<bool> deleteCustomer({
    required int customerId,
    int? reassign,
  }) async {
    final woo = _getWooCommerce();
    return await woo.deleteCustomer(
      customerId,
      reassign: reassign,
    );
  }

  /// Ottiene clienti per ruolo
  Future<List<WooCustomer>> getCustomersByRole(WooCustomerRole role, {
    int page = 1,
    int perPage = 20,
  }) async {
    final woo = _getWooCommerce();
    return await woo.getCustomers(
      role: role,
      page: page,
      perPage: perPage,
    );
  }

  /// Ottiene tutti i clienti (uso con cautela!)
  Future<List<WooCustomer>> getAllCustomers() async {
    final woo = _getWooCommerce();
    final List<WooCustomer> allCustomers = [];
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      final customers = await woo.getCustomers(
        page: currentPage,
        perPage: 100,
      );

      if (customers.isEmpty) {
        hasMore = false;
      } else {
        allCustomers.addAll(customers);
        currentPage++;
      }
    }

    return allCustomers;
  }

  /// Batch update clienti (usa Dio diretto)
  Future<Map<String, dynamic>> batchUpdateCustomers({
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    final batchData = {
      if (create != null && create.isNotEmpty) 'create': create,
      if (update != null && update.isNotEmpty) 'update': update,
      if (delete != null && delete.isNotEmpty) 'delete': delete,
    };

    final response = await _auth.getAuthenticatedDio().post(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/customers/batch',
      data: batchData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Ottiene statistiche clienti
  Future<Map<String, dynamic>> getCustomerStats() async {
    final woo = _getWooCommerce();
    final allCustomers = await woo.getCustomers(perPage: 1, page: 1);

    // WooCommerce non fornisce direttamente il totale,
    // quindi facciamo una richiesta per ottenere il numero
    final response = await _auth.getAuthenticatedDio().get(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/customers',
      queryParameters: {'per_page': 1, 'page': 1},
    );

    final totalCustomers = int.tryParse(
      response.headers.value('x-wp-total') ?? '0'
    ) ?? 0;

    return {
      'total_customers': totalCustomers,
      'customers_per_page': allCustomers.length,
    };
  }

  /// Verifica se un email esiste già
  Future<bool> emailExists(String email) async {
    try {
      final customers = await searchCustomersByEmail(email);
      return customers.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene gli ordini di un cliente
  Future<List<WooOrder>> getCustomerOrders(int customerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final woo = _getWooCommerce();
    return await woo.getOrders(
      customer: customerId,
      page: page,
      perPage: perPage,
    );
  }

  /// Ottiene il totale speso da un cliente
  Future<double> getCustomerTotalSpent(int customerId) async {
    final orders = await getCustomerOrders(customerId, perPage: 100);
    double total = 0.0;

    for (var order in orders) {
      if (order.status == 'completed' || order.status == 'processing') {
        total += double.tryParse(order.total?.toString() ?? '0') ?? 0.0;
      }
    }

    return total;
  }

  /// Ottiene download disponibili per un cliente
  Future<List<WooCustomerDownload>> getCustomerDownloads(int customerId) async {
    final woo = _getWooCommerce();
    return await woo.getCustomerDownloads(customerId);
  }
}
