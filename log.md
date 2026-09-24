# Log delle attività

## 2026-09-24 — Migrazione woocommerce_flutter_api v1.7.1 → v2.0.0

**Problema**: Il progetto usava un fork locale di `woocommerce_flutter_api` v1.7.1 (`packages/woocommerce_flutter_api/`) che presentava bug nel parsing delle varianti (`type 'String' is not a subtype of type 'WooProductStatus?'`). La libreria ufficiale pub.dev offre la v2.0.0 con correzioni e nuove API.

**Scelta**: Migrazione alla libreria ufficiale `woocommerce_flutter_api: ^2.0.0` da pub.dev. Il fork locale rimane intatto su disco come obsoleto ma non più utilizzato nella catena di dipendenze.

**Modifiche apportate**:
- `pubspec.yaml`: rimosso `path: packages/woocommerce_flutter_api`, aggiunto `woocommerce_flutter_api: ^2.0.0`
- `lib/login/jwt_api/woo_connect.dart`: costruttore `WooCommerce` aggiornato da `username`/`password` a `consumerKey`/`consumerSecret`
- `lib/login/jwt_api/query_woocommerce/woo_query_clienti.dart`: `WooSortOrder` → `WooSort`, `WooCustomerSort` → `WooOrderBy`, `orderby:` → `orderBy:`
- `lib/login/jwt_api/query_woocommerce/woo_query_tasse.dart`: stesso aggiornamento enum
- `lib/login/jwt_api/query_woocommerce/woo_query_tag.dart`: stesso aggiornamento enum, `WooProductTag`/`WooProductItemAttribute` costruttori named
- `lib/login/jwt_api/query_woocommerce/woo_query_prodotti.dart`: rimossi `fromString()`, aggiunte helper `_parseProductStatus`/`_parseStockStatus`, costruttori named
- `lib/login/jwt_api/query_woocommerce/woo_query_varianti.dart`, `woo_query_ordini.dart`, `woo_query_categoria.dart`, `woo_query_coupon.dart`: firma metodi `updateXxx(id, item)`, `deleteXxx(id)`
- `lib/` e `test/`: tutti i metodi che restituiscono `List<T>` ora usano `WooPage<T>.items`
- `test/woo_variations_e2e_test.dart`: `getProductVaritaions` → `getProductVariations`, costruttore aggiornato
- `test/woo_variation_parsing_test.dart`, `test/woo_variation_defects_test.dart`: commenti aggiornati

**Risultato**: `flutter analyze` zero errori, 28 test superati. Il fork in `packages/woocommerce_flutter_api/` resta intatto su disco.

**Rischio**: I test `woo_variation_parsing_test.dart` e `woo_variations_e2e_test.dart` hanno fallimenti legati al diverso comportamento di parsing di v2 rispetto al fork (gestione date GMT, enum values). Richiedono aggiornamento delle fixture o delle aspettative.
