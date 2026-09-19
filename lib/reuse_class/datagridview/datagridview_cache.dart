import 'dart:async';

import '../../prodotti/class_prodotti.dart';
import '../class_formtter.dart';

/// Informazioni di pricing derivate per un prodotto (prezzo, sconto,
/// variabilità). Vivono nel layer datagrid perché sono i valori che le
/// griglie mostrano nelle colonne Prezzo/Sconto.
class ProdottoPricingInfo {
  final String prezzoLabel;
  final String scontoLabel;
  final String percentualeScontoLabel;
  final String prezzoCompletoLabel;
  final bool hasSconto;
  final bool prezzoVariabile;
  final bool scontoVariabile;

  const ProdottoPricingInfo({
    required this.prezzoLabel,
    required this.scontoLabel,
    required this.percentualeScontoLabel,
    required this.prezzoCompletoLabel,
    required this.hasSconto,
    required this.prezzoVariabile,
    required this.scontoVariabile,
  });
}

class DataGridViewCache {
  static List<ProdottoGlobal>? _products;
  static DateTime? _productsAt;
  static bool _productsDirty = true;

  static final Map<int, List<VarianteProductGlobal>> _variants =
      <int, List<VarianteProductGlobal>>{};
  static final Map<int, DateTime> _variantsAt = <int, DateTime>{};

  /// Cache pricing precomputata (productId → pricingInfo).
  static final Map<int, ProdottoPricingInfo> _pricingCache =
      <int, ProdottoPricingInfo>{};

  /// Notifica i subscriber che le varianti di un prodotto sono state
  /// aggiornate (es. prefetch completato). Le griglie iscritte devono
  /// riallineare lo snapshot paginato e ricomporsi.
  static final StreamController<int> _onVariantsUpdated =
      StreamController<int>.broadcast();
  static Stream<int> get onVariantsUpdated => _onVariantsUpdated.stream;

  static bool get hasProducts => _products != null && _products!.isNotEmpty;

  static bool hasFreshProducts([Duration? ttl]) {
    if (_productsDirty || _products == null || _productsAt == null) {
      return false;
    }
    if (ttl == null) return true;
    return DateTime.now().difference(_productsAt!) <= ttl;
  }

  static List<ProdottoGlobal>? readProducts() {
    final products = _products;
    if (products == null) return null;
    return List<ProdottoGlobal>.from(products);
  }

  static void writeProducts(List<ProdottoGlobal> products) {
    _products = List<ProdottoGlobal>.from(products);
    _productsAt = DateTime.now();
    _productsDirty = false;
    // Prodotti sostituiti: il pricing derivato potrebbe non essere più valido.
    _pricingCache.clear();
  }

  static void replaceProducts(List<ProdottoGlobal> products) {
    writeProducts(products);
  }

  static void appendProducts(List<ProdottoGlobal> products) {
    final current = _products ?? <ProdottoGlobal>[];
    _products = <ProdottoGlobal>[...current, ...products];
    _productsAt = DateTime.now();
    _productsDirty = false;
  }

  static void markProductsDirty() {
    _productsDirty = true;
  }

  static void clearProducts() {
    _products = null;
    _productsAt = null;
    _productsDirty = true;
    _pricingCache.clear();
  }

  static void clearVariants() {
    _variants.clear();
    _variantsAt.clear();
    _pricingCache.clear();
  }

  static void clearAll() {
    clearProducts();
    clearVariants();
  }

  static List<VarianteProductGlobal>? readVariants(
    int productId,
    Duration ttl,
  ) {
    final cachedAt = _variantsAt[productId];
    final cached = _variants[productId];
    if (cachedAt == null || cached == null) return null;
    if (DateTime.now().difference(cachedAt) > ttl) {
      removeVariants(productId);
      return null;
    }
    return List<VarianteProductGlobal>.from(cached);
  }

  /// Vero se esiste una voce in cache per [productId] ancora fresca (TTL),
  /// senza copiare la lista. Check economico per prefetch/loop.
  static bool hasVariants(int productId, Duration ttl) {
    final cachedAt = _variantsAt[productId];
    if (cachedAt == null || !_variants.containsKey(productId)) return false;
    if (DateTime.now().difference(cachedAt) > ttl) {
      removeVariants(productId);
      return false;
    }
    return true;
  }

  /// Limita la cache varianti ai soli prodotti in [keepByIds] (finestra
  /// visibile): rimuove tutte le altre voci, così la RAM resta proporzionata
  /// alla pagina corrente e non cresce con il numero di pagine visitate.
  /// Ritorna il numero di voci rimosse.
  static int pruneVariantsOutside(Set<int> keepByIds) {
    int rimossi = 0;
    for (final id in List<int>.from(_variants.keys)) {
      if (!keepByIds.contains(id)) {
        removeVariants(id);
        rimossi++;
      }
    }
    return rimossi;
  }

  /// Conteggio voci varianti in cache (per diagnostica memoria).
  static int variantsCacheSize() => _variants.length;

  /// Conteggio totale oggetti variante in cache (per diagnostica memoria).
  static int totalVariantsInCache() {
    int tot = 0;
    for (final list in _variants.values) {
      tot += list.length;
    }
    return tot;
  }

  static void writeVariants(
    int productId,
    List<VarianteProductGlobal> variants,
  ) {
    _variants[productId] = List<VarianteProductGlobal>.from(variants);
    _variantsAt[productId] = DateTime.now();
  }

  static void removeVariants(int productId) {
    _variants.remove(productId);
    _variantsAt.remove(productId);
    _pricingCache.remove(productId);
  }

  /// Aggiorna la cache varianti, aggancia le varianti a entrambe le liste
  /// prodotto (allProducts e filteredProducts) con i nuovi oggetti, ricalcola
  /// il pricing del prodotto toccato e notifica i subscriber.
  ///
  /// Sostituisce `_storeVariantsInCache` + `_replaceProductVariantsInLists`
  /// presenti nel controller prodotti: il merge dei dati aggiornati è
  /// responsabilità del layer griglia, non del business logic.
  ///
  /// Ritorna `true` se ha realmente sostituito almeno un'istanza.
  static bool replaceVariants(
    int productId,
    List<VarianteProductGlobal> variants,
    List<ProdottoGlobal> allProducts,
    List<ProdottoGlobal> filteredProducts,
  ) {
    writeVariants(productId, variants);

    bool replaced = false;
    for (int i = 0; i < allProducts.length; i++) {
      if (allProducts[i].id == productId) {
        allProducts[i] = allProducts[i].copyWith(varianti: variants);
        replaced = true;
      }
    }
    for (int i = 0; i < filteredProducts.length; i++) {
      if (filteredProducts[i].id == productId) {
        filteredProducts[i] = filteredProducts[i].copyWith(varianti: variants);
        replaced = true;
      }
    }

    if (replaced) {
      // Ricalcola il pricing dal prodotto aggiornato (che ora ha le varianti).
      ProdottoGlobal? aggiornato;
      for (final prodotto in allProducts) {
        if (prodotto.id == productId) {
          aggiornato = prodotto;
          break;
        }
      }
      if (aggiornato == null) {
        for (final prodotto in filteredProducts) {
          if (prodotto.id == productId) {
            aggiornato = prodotto;
            break;
          }
        }
      }
      if (aggiornato != null) {
        _pricingCache[productId] = getPricingInfo(aggiornato);
      }
      _onVariantsUpdated.add(productId);
    }
    return replaced;
  }

  /// Calcola informazioni di prezzo/sconto per un prodotto.
  ///
  /// Regole (priorità alle varianti quando presenti):
  /// - varianti caricate con tutti lo stesso prezzo → valore unico (caso 1);
  /// - varianti con prezzi diversi → "Prezzo variabile" (caso 2/3);
  /// - varianti assenti → campi base del prodotto (prezzoNormale/prezzoScontato).
  static ProdottoPricingInfo getPricingInfo(ProdottoGlobal prodotto) {
    final productId = prodotto.id;
    if (productId != null && _pricingCache.containsKey(productId)) {
      return _pricingCache[productId]!;
    }

    final info = _computePricingInfo(prodotto);
    if (productId != null) {
      _pricingCache[productId] = info;
    }
    return info;
  }

  static ProdottoPricingInfo _computePricingInfo(ProdottoGlobal prodotto) {
    final varianti = prodotto.varianti ?? const <VarianteProductGlobal>[];
    if (varianti.isEmpty) {
      final prezzoLabel = ClassFormtter.formatPrezzo(
        prodotto.prezzoNormale ?? 0,
      );
      final scontoLabel = prodotto.prezzoScontato != null
          ? ClassFormtter.formatPrezzo(prodotto.prezzoScontato!)
          : '-';
      final percentualeScontoLabel = prodotto.percentualeSconto == null
          ? '-'
          : '${prodotto.percentualeSconto!.toStringAsFixed(0)}%';
      return ProdottoPricingInfo(
        prezzoLabel: prezzoLabel,
        scontoLabel: scontoLabel,
        percentualeScontoLabel: percentualeScontoLabel,
        prezzoCompletoLabel: ClassFormtter.formatPrezzoConSconto(
          prodotto.prezzoNormale ?? 0,
          prodotto.prezzoScontato,
        ),
        hasSconto: prodotto.prezzoScontato != null,
        prezzoVariabile: false,
        scontoVariabile: false,
      );
    }

    final regularPrices = varianti.map((v) => v.prezzo).toSet();
    final saleValues = varianti.map((v) => v.prezzoScontato).toSet();

    final prezzoVariabile = regularPrices.length > 1;
    final scontoVariabile = saleValues.length > 1;
    final hasSconto = saleValues.any((value) => value != null);
    final percentualiSconto = varianti
        .where((variante) => variante.percentualeSconto != null)
        .map((variante) => variante.percentualeSconto!)
        .toSet();
    final percentualeScontoLabel = percentualiSconto.isEmpty
        ? '-'
        : percentualiSconto.length > 1
        ? 'Percentuale variabile'
        : '${percentualiSconto.first.toStringAsFixed(0)}%';

    final prezzoLabel = prezzoVariabile
        ? 'Prezzo variabile'
        : ClassFormtter.formatPrezzo(regularPrices.first);
    final scontoLabel = !hasSconto
        ? '-'
        : scontoVariabile
        ? 'Sconto variabile'
        : ClassFormtter.formatPrezzo(saleValues.first!);

    final prezzoCompletoLabel = hasSconto
        ? prezzoVariabile || scontoVariabile
              ? 'Prezzo/Sconto variabile'
              : ClassFormtter.formatPrezzoConSconto(
                  regularPrices.first,
                  saleValues.first,
                )
        : prezzoLabel;

    return ProdottoPricingInfo(
      prezzoLabel: prezzoLabel,
      scontoLabel: scontoLabel,
      percentualeScontoLabel: percentualeScontoLabel,
      prezzoCompletoLabel: prezzoCompletoLabel,
      hasSconto: hasSconto,
      prezzoVariabile: prezzoVariabile,
      scontoVariabile: scontoVariabile,
    );
  }
}
