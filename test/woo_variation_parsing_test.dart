import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';

/// Test del parsing delle varianti prodotto WooCommerce (fork locale).
///
/// Il fork patchato in `packages/woocommerce_flutter_api` corregge
/// `WooProductVariation.fromJson`, che nel package originale 1.7.1
/// falliva per ogni variante con:
///   type 'String' is not a subtype of type 'WooProductStatus?'
/// a causa di cast impliciti String→enum (status, tax_status,
/// stock_status, backorders) senza `fromString`, guardie null mancanti
/// su date/image/dimensions e chiavi GMT invertite.
///
/// Le fixture sono payload REST reali catturati da WordPress Docker
/// (localhost:8080) per i prodotti 5869, 5735 e 5733.
void main() {
  group('WooProductVariation.fromJson (fork patchato)', () {
    test('parsa i payload reali senza throw e popola i campi chiave', () {
      for (final fixture in const [
        ('variations_5869.json', 5),
        ('variations_5735.json', 3),
        ('variations_5733.json', 1),
      ]) {
        final raw = File('test/fixtures/${fixture.$1}').readAsStringSync();
        final json = jsonDecode(raw) as List<dynamic>;
        final variations = json
            .map(
              (e) =>
                  WooProductVariation.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        final rawVariations = json.cast<Map<String, dynamic>>();

        expect(variations, hasLength(fixture.$2),
            reason: 'Fixture ${fixture.$1}');
        for (var i = 0; i < variations.length; i++) {
          final v = variations[i];
          final raw = rawVariations[i];
          // Campo che causava il crash: status era una String grezza.
          expect(v.status, WooProductStatus.publish,
              reason: 'SKU ${v.sku}: status non decodificato');
          expect(v.id, isNotNull);
          expect(v.sku, isNotNull);
          expect(v.regularPrice, isNotNull);
          // I valori decodificati devono corrispondere a quelli grezzi.
          expect(v.stockStatus,
              WooProductStockStatus.fromString(raw['stock_status'] ?? ''),
              reason: 'SKU ${v.sku}: stock_status non decodificato');
          expect(v.taxStatus,
              WooProductTaxStatus.fromString(raw['tax_status'] ?? ''),
              reason: 'SKU ${v.sku}: tax_status non decodificato');
          expect(v.backorders,
              WooProductBackorder.fromString(raw['backorders'] ?? ''),
              reason: 'SKU ${v.sku}: backorders non decodificato');
          expect(v.image, isNotNull);
          expect(v.attributes, isNotEmpty);
          // Le varianti usano il formato `option` singolo: la patch del
          // fork deve mapparlo in options[0] (altrimenti il converter
          // dell'app leggerebbe opzione vuota).
          for (final attr in v.attributes) {
            expect(attr.options, isNotNull,
                reason: 'SKU ${v.sku}: attributo ${attr.name} senza options');
            expect(attr.options, isNotEmpty,
                reason: 'SKU ${v.sku}: attributo ${attr.name} senza opzioni');
          }
          expect(v.metaData, isNotEmpty);
        }
      }
    });

    test('date GMT non invertite (dateCreatedGmt = date_created_gmt)', () {
      final raw =
          File('test/fixtures/variations_5869.json').readAsStringSync();
      final json = jsonDecode(raw) as List<dynamic>;
      final v = WooProductVariation.fromJson(
        json.first as Map<String, dynamic>,
      );

      // Il fromJson originale scambiava le chiavi: dateCreatedGmt
      // leggeva date_modified_gmt e viceversa.
      expect(v.dateCreatedGmt, DateTime.parse(json.first['date_created_gmt']));
      expect(v.dateModifiedGmt, DateTime.parse(json.first['date_modified_gmt']));
      expect(v.dateCreatedGmt!.isBefore(v.dateModifiedGmt!), isTrue);
    });

    test('payload edge-case (null/unknown) con fallback tolleranti', () {
      final edge = <String, dynamic>{
        'id': 9999,
        'status': 'future', // stato sconosciuto → default publish
        'description': null,
        'date_created': null,
        'date_created_gmt': null,
        'date_modified': null,
        'date_modified_gmt': null,
        'date_on_sale_from': null,
        'date_on_sale_from_gmt': null,
        'date_on_sale_to': null,
        'date_on_sale_to_gmt': null,
        'sku': null,
        'price': '',
        'regular_price': '',
        'sale_price': '',
        'on_sale': false,
        'downloads': null,
        'tax_status': null,
        'tax_class': null,
        'manage_stock': null,
        'stock_quantity': null,
        'stock_status': '', // sconosciuto → default instock
        'backorders': null,
        'weight': null,
        'image': null,
        'dimensions': null,
        'attributes': null,
        'meta_data': null,
      };

      final v = WooProductVariation.fromJson(edge);

      expect(v.status, WooProductStatus.publish);
      expect(v.stockStatus, WooProductStockStatus.instock);
      expect(v.taxStatus, WooProductTaxStatus.taxable);
      expect(v.backorders, WooProductBackorder.no);
      expect(v.image, isNull);
      expect(v.dimensions, const WooProductDimension());
      expect(v.dateCreated, isNull);
      expect(v.dateOnSaleFrom, isNull);
      expect(v.downloads, isEmpty);
      expect(v.attributes, isEmpty);
      expect(v.metaData, isEmpty);
      expect(v.manageStock, isFalse);
    });
  });
}