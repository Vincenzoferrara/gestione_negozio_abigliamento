import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'jwt_connect.dart';
import 'api_client.dart';

class NewProductData {
  final String name;
  final String price;
  final String sku;
  final String description;

  NewProductData({required this.name, required this.price, required this.sku, required this.description});

  Map<String, dynamic> toJson() => {
        'name': name, 'type': 'simple', 'status': 'draft', 'regular_price': price, 'sku': sku, 'description': description,
      };
}

class ProductService {
  final ApiClient _apiClient;

  ProductService({required String siteUrl, required UserSession session})
      : _apiClient = ApiClient(siteUrl: siteUrl, session: session);

  Future<void> createProduct(NewProductData productData) async {
    debugPrint('Tentativo di creare il prodotto: ${productData.name}');
    try {
      final response = await _apiClient.post('/wc/v3/products', body: productData.toJson());
      final responseBody = jsonDecode(response.body);
      debugPrint('Prodotto creato con successo! ID: ${responseBody['id']}');
    } catch (e) {
      debugPrint('Errore intercettato in ProductService: ${e.toString()}');
      rethrow;
    }
  }
}