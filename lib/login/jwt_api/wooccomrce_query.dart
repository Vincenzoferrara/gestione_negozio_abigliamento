import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jwt_connect.dart';
import 'error_list.dart';

// === GESTORE ERRORI SPECIFICO ===
class WooCommerceError {
  final String code;
  final String message;
  WooCommerceError({required this.code, required this.message});
  factory WooCommerceError.fromJson(Map<String, dynamic> json) => WooCommerceError(
        code: json['code'] ?? 'unknown_error',
        message: json['message'] ?? 'Errore sconosciuto da WooCommerce.',
      );
}

// === CLASSE BASE PER I SERVIZI ===
abstract class _WooService {
  final JwtConnect _jwt;
  _WooService(this._jwt);

  Future<dynamic> _request(String method, String endpoint, {Map<String, String>? queryParams, Map<String, dynamic>? body}) async {
    final uri = _jwt.buildUri(_jwt.currentSiteUrl!, endpoint, queryParams: queryParams);
    final response = await _jwt.authenticatedRequest(method, uri, body: body);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        final error = WooCommerceError.fromJson(jsonBody);
        switch (error.code) {
          case 'woocommerce_rest_product_invalid_id': throw ProductNotFoundException();
          case 'woocommerce_rest_product_sku_already_exists': throw SkuAlreadyExistsException();
          default: throw GenericWooCommerceException(code: error.code, message: error.message, statusCode: response.statusCode);
        }
      }
      return jsonBody;
    } on FormatException {
      throw InvalidResponseFormatException();
    }
  }
}

// =======================================================
// == SERVIZI SPECIFICI PER OGNI AREA DI WOOCOMMERCE    ==
// =======================================================

/// Servizio per la gestione dei Prodotti.
class ProductService extends _WooService {
  ProductService(JwtConnect jwt) : super(jwt);

  Future<WooProduct> create(CreateProductData data) async {
    final productData = await _request('POST', 'wc/v3/products', body: data.toJson());
    return WooProduct.fromJson(productData);
  }

  Future<WooProduct> getById(int productId) async {
    final productData = await _request('GET', 'wc/v3/products/$productId');
    return WooProduct.fromJson(productData);
  }

  Future<List<WooProduct>> list({int page = 1, int perPage = 10, String? search, String? status, String? type, String? category}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    
    final List<dynamic> productsData = await _request('GET', 'wc/v3/products', queryParams: queryParams);
    return productsData.map((data) => WooProduct.fromJson(data)).toList();
  }

  Future<WooProduct> update(int productId, UpdateProductData data) async {
    final productData = await _request('PUT', 'wc/v3/products/$productId', body: data.toJson());
    return WooProduct.fromJson(productData);
  }

  Future<void> delete(int productId, {bool force = false}) async {
    final queryParams = force ? {'force': 'true'} : null;
    await _request('DELETE', 'wc/v3/products/$productId', queryParams: queryParams);
  }

  Future<BatchResult> batchUpdate(BatchProductData batch) async {
    final batchData = await _request('POST', 'wc/v3/products/batch', body: batch.toJson());
    return BatchResult.fromJson(batchData);
  }

  // Future<WooProduct> duplicate(int productId, {String? newName}) async {
  //   final original = await getById(productId);
  //   final duplicateData = CreateProductData(
  //     name: newName ?? '${original.name} (Copia)',
  //     type: original.type,
  //     status: 'draft',
  //     regularPrice: original.regularPrice,
  //     salePrice: original.salePrice,
  //     description: original.description,
  //     shortDescription: original.shortDescription,
  //     sku: null,
  //     manageStock: original.manageStock,
  //     stockQuantity: original.stockQuantity,
  //     weight: original.weight,
  //     //dimensions: original.dimensions,
  //     categories: original.categories?.map((c) => c.id).toList(),
  //     tags: original.tags?.map((t) => t.id).toList(),
  //     images: original.images,
  //   );
  //   return await create(duplicateData);
  // }

  
}

/// Servizio per la gestione delle Categorie.
class CategoryService extends _WooService {
  CategoryService(JwtConnect jwt) : super(jwt);

  Future<List<WooCategory>> list() async {
    final List<dynamic> categoriesData = await _request('GET', 'wc/v3/products/categories');
    return categoriesData.map((data) => WooCategory.fromJson(data)).toList();
  }
  
  Future<WooCategory> create(String name, {String? description, int? parent}) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    if (parent != null) data['parent'] = parent.toString();
    
    final categoryData = await _request('POST', 'wc/v3/products/categories', body: data);
    return WooCategory.fromJson(categoryData);
  }
}

/// Servizio per la gestione degli Ordini.
class OrderService extends _WooService {
  OrderService(JwtConnect jwt) : super(jwt);

  Future<List<WooOrder>> list({int page = 1, int perPage = 10, String? status}) async {
    final queryParams = {'page': page.toString(), 'per_page': perPage.toString()};
    if (status != null) queryParams['status'] = status;
    
    final List<dynamic> ordersData = await _request('GET', 'wc/v3/orders', queryParams: queryParams);
    return ordersData.map((data) => WooOrder.fromJson(data)).toList();
  }
  
  Future<WooOrder> updateStatus(int orderId, String status) async {
    final orderData = await _request('PUT', 'wc/v3/orders/$orderId', body: {'status': status});
    return WooOrder.fromJson(orderData);
  }
}

// =======================================================
// ==      MODELLI DI DATI (DTOs) E OGGETTI DI DOMINIO   ==
// =======================================================

/// Dati per creare un prodotto
class CreateProductData {
  final String name;
  final String type;
  final String status;
  final String? regularPrice;
  final String? salePrice;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final bool? manageStock;
  final int? stockQuantity;
  final String? weight;
  final Map<String, String>? dimensions;
  final List<int>? categories;
  final List<int>? tags;
  final List<Map<String, dynamic>>? images;

  CreateProductData({
    required this.name,
    this.type = 'simple',
    this.status = 'draft',
    this.regularPrice,
    this.salePrice,
    this.description,
    this.shortDescription,
    this.sku,
    this.manageStock,
    this.stockQuantity,
    this.weight,
    this.dimensions,
    this.categories,
    this.tags,
    this.images,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'type': type,
      'status': status,
    };
    if (regularPrice != null) json['regular_price'] = regularPrice;
    if (salePrice != null) json['sale_price'] = salePrice;
    if (description != null) json['description'] = description;
    if (shortDescription != null) json['short_description'] = shortDescription;
    if (sku != null) json['sku'] = sku;
    if (manageStock != null) json['manage_stock'] = manageStock;
    if (stockQuantity != null) json['stock_quantity'] = stockQuantity;
    if (weight != null) json['weight'] = weight;
    if (dimensions != null) json['dimensions'] = dimensions;
    if (categories != null) json['categories'] = categories!.map((id) => {'id': id}).toList();
    if (tags != null) json['tags'] = tags!.map((id) => {'id': id}).toList();
    if (images != null) json['images'] = images;
    return json;
  }
}

/// Dati per aggiornare un prodotto
class UpdateProductData {
  final String? name;
  final String? status;
  final String? regularPrice;
  final String? salePrice;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final bool? manageStock;
  final int? stockQuantity;

  UpdateProductData({
    this.name,
    this.status,
    this.regularPrice,
    this.salePrice,
    this.description,
    this.shortDescription,
    this.sku,
    this.manageStock,
    this.stockQuantity,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (status != null) json['status'] = status;
    if (regularPrice != null) json['regular_price'] = regularPrice;
    if (salePrice != null) json['sale_price'] = salePrice;
    if (description != null) json['description'] = description;
    if (shortDescription != null) json['short_description'] = shortDescription;
    if (sku != null) json['sku'] = sku;
    if (manageStock != null) json['manage_stock'] = manageStock;
    if (stockQuantity != null) json['stock_quantity'] = stockQuantity;
    return json;
  }
}

/// Dati per operazioni batch
class BatchProductData {
  final List<CreateProductData>? create;
  final List<Map<String, dynamic>>? update;
  final List<int>? delete;

  BatchProductData({this.create, this.update, this.delete});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (create != null) json['create'] = create!.map((item) => item.toJson()).toList();
    if (update != null) json['update'] = update;
    if (delete != null) json['delete'] = delete!;
    return json;
  }
}

/// Risultato di un'operazione batch
class BatchResult {
  final List<WooProduct>? created;
  final List<WooProduct>? updated;
  final List<WooProduct>? deleted;

  BatchResult({this.created, this.updated, this.deleted});

  factory BatchResult.fromJson(Map<String, dynamic> json) {
    return BatchResult(
      created: (json['create'] as List<dynamic>?)?.map((item) => WooProduct.fromJson(item)).toList(),
      updated: (json['update'] as List<dynamic>?)?.map((item) => WooProduct.fromJson(item)).toList(),
      deleted: (json['delete'] as List<dynamic>?)?.map((item) => WooProduct.fromJson(item)).toList(),
    );
  }
}

/// Modello per un prodotto WooCommerce
class WooProduct {
  final int id;
  final String name;
  final String slug;
  final String type;
  final String status;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final String? regularPrice;
  final String? salePrice;
  final bool manageStock;
  final int? stockQuantity;
  final String? weight;
  final Map<String, dynamic>? dimensions;
  final List<WooCategory>? categories;
  final List<WooTag>? tags;
  final List<Map<String, dynamic>>? images;

  WooProduct({
    required this.id, required this.name, required this.slug, required this.type, required this.status,
    this.description, this.shortDescription, this.sku, this.regularPrice, this.salePrice,
    required this.manageStock, this.stockQuantity, this.weight, this.dimensions,
    this.categories, this.tags, this.images,
  });

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    return WooProduct(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      type: json['type'] ?? 'simple',
      status: json['status'] ?? 'draft',
      description: json['description'],
      shortDescription: json['short_description'],
      sku: json['sku'],
      regularPrice: json['regular_price'],
      salePrice: json['sale_price'],
      manageStock: json['manage_stock'] ?? false,
      stockQuantity: json['stock_quantity'],
      weight: json['weight'],
      dimensions: (json['dimensions'] as Map<String, dynamic>?)?.cast<String, dynamic>(),
      categories: (json['categories'] as List<dynamic>?)?.map((cat) => WooCategory.fromJson(cat)).toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => WooTag.fromJson(tag)).toList(),
      images: (json['images'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
    );
  }
}

/// Modello per una categoria WooCommerce
class WooCategory {
  final int id;
  final String name;
  final String slug;

  WooCategory({required this.id, required this.name, required this.slug});

  factory WooCategory.fromJson(Map<String, dynamic> json) {
    return WooCategory(id: json['id'], name: json['name'], slug: json['slug']);
  }
}

/// Modello per un tag WooCommerce
class WooTag {
  final int id;
  final String name;
  final String slug;

  WooTag({required this.id, required this.name, required this.slug});

  factory WooTag.fromJson(Map<String, dynamic> json) {
    return WooTag(id: json['id'], name: json['name'], slug: json['slug']);
  }
}

/// Modello per un ordine WooCommerce
class WooOrder {
  final int id;
  final String status;
  final String total;
  final DateTime dateCreated;

  WooOrder({required this.id, required this.status, required this.total, required this.dateCreated});

  factory WooOrder.fromJson(Map<String, dynamic> json) {
    return WooOrder(
      id: json['id'],
      status: json['status'],
      total: json['total'],
      dateCreated: DateTime.parse(json['date_created_gmt']),
    );
  }
}