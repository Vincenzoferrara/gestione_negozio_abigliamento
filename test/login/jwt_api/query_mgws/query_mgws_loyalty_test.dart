import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_loyalty.dart';

void main() {
  test('loyalty lookup paths encode dynamic card and email segments', () {
    expect(
      QueryMgwsLoyalty.cardLookupPath('CARD:201 / ?'),
      '/wp-json/mgws/v1/loyalty/lookup/card/CARD%3A201%20%2F%20%3F',
    );
    expect(
      QueryMgwsLoyalty.emailLookupPath('ada+vip@example.test'),
      '/wp-json/mgws/v1/loyalty/lookup/email/ada%2Bvip%40example.test',
    );
  });
}
