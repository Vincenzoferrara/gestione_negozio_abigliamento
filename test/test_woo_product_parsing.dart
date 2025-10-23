import 'package:flutter_test/flutter_test.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';

void main() {
  test('Test WooProduct parsing with actual WooCommerce response', () {
    // Questo è l'esatto JSON che WooCommerce restituisce
    final json = {
      "id": 29,
      "name": "Prodotto Test Script",
      "slug": "prodotto-test-script-3",
      "permalink": "http://localhost:8080/prodotto/prodotto-test-script-3/",
      "date_created": "2025-10-21T11:25:44",
      "date_created_gmt": "2025-10-21T09:25:44",
      "date_modified": "2025-10-21T11:25:44",
      "date_modified_gmt": "2025-10-21T09:25:44",
      "type": "simple",
      "status": "publish",
      "featured": false,
      "catalog_visibility": "visible",
      "description": "",
      "short_description": "",
      "sku": "",
      "price": "19.99",
      "regular_price": "19.99",
      "sale_price": "",
      "date_on_sale_from": null,  // QUESTO è il problema!
      "date_on_sale_from_gmt": null,
      "date_on_sale_to": null,
      "date_on_sale_to_gmt": null,
      "on_sale": false,
      "purchasable": true,
      "total_sales": 0,
      "virtual": false,
      "downloadable": false,
      "downloads": [],
      "download_limit": -1,
      "download_expiry": -1,
      "external_url": "",
      "button_text": "",
      "tax_status": "taxable",
      "tax_class": "",
      "manage_stock": false,
      "stock_quantity": null,
      "backorders": "no",
      "backorders_allowed": false,
      "backordered": false,
      "low_stock_amount": null,
      "sold_individually": false,
      "weight": "",
      "dimensions": {
        "length": "",
        "width": "",
        "height": ""
      },
      "shipping_required": true,
      "shipping_taxable": true,
      "shipping_class": "",
      "shipping_class_id": 0,
      "reviews_allowed": true,
      "average_rating": "0.00",
      "rating_count": 0,
      "upsell_ids": [],
      "cross_sell_ids": [],
      "parent_id": 0,
      "purchase_note": "",
      "categories": [],
      "tags": [],
      "images": [],
      "attributes": [],
      "default_attributes": [],
      "variations": [],
      "grouped_products": [],
      "menu_order": 0,
      "stock_status": "instock",
    };

    try {
      final product = WooProduct.fromJson(json);
      print('✅ Success: ${product.name}');
      print('   Weight: ${product.weight}');
      print('   Date on sale from: ${product.dateOnSaleFrom}');
    } catch (e, stack) {
      print('❌ Error: $e');
      print('   Line in stack: ${stack.toString().split('\n').first}');
      fail('Failed to parse product: $e');
    }
  });
}
