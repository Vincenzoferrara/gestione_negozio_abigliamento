// class_prodotti.dart

/// Rappresenta un singolo prodotto principale recuperato da WooCommerce.
class ProdottoWoo {
  final int id;
  final String nome;
  final String sku;
  final double prezzoNormale;
  final double? prezzoScontato;
  final String descrizioneBreve;
  final String immagineUrl;
  final List<VarianteWoo> varianti;
  final String categoria;
  final bool inStock;

  ProdottoWoo({
    required this.id,
    required this.nome,
    required this.sku,
    required this.prezzoNormale,
    this.prezzoScontato,
    required this.descrizioneBreve,
    required this.immagineUrl,
    required this.varianti,
    required this.categoria,
    required this.inStock,
  });
}

/// Rappresenta un singolo attributo di una variante.
/// Esempio: { nome: "Colore", opzione: "Rosso", valore: "#FF0000" }
/// Il campo 'valore' è opzionale e viene usato da plugin specifici (es. per i colori).
class AttributoVariante {
  final String nome;    // Es. "Colore"
  final String opzione; // Es. "Rosso"
  final String? valore; // Es. "#FF0000" (per i campioni di colore)

  AttributoVariante({
    required this.nome,
    required this.opzione,
    this.valore,
  });
}


/// Rappresenta una singola variante di un ProdottoWoo.
/// Una variante è definita da una combinazione di attributi (es. Colore + Taglia).
class VarianteWoo {
  final int id;
  final String nome;
  /// Lista degli attributi che definiscono questa specifica variante.
  final List<AttributoVariante> attributi;
  final String sku;
  final double prezzo;
  final int quantita;
  final String? immagineUrl;

  VarianteWoo({
    required this.id,
    required this.nome,
    required this.attributi,
    required this.sku,
    required this.prezzo,
    required this.quantita,
    this.immagineUrl,
  });

  /// Metodo Getter (proprietà calcolata) per creare un nome leggibile
  /// concatenando le opzioni degli attributi.
  /// Esempio: "Rosso - M"
  String get nomeVisualizzabile {
    // Se non ci sono attributi, restituisce una stringa vuota per sicurezza.
    if (attributi.isEmpty) {
      return '';
    }
    // Concatena tutte le 'opzioni' degli attributi, separate da " - ".
    return attributi.map((a) => a.opzione).join(' - ');
  }

  /// Metodo Getter (proprietà calcolata) per trovare l'attributo 'Colore'
  /// all'interno della lista di attributi della variante.
  /// Questo è cruciale per visualizzare i campioni di colore (swatches).
  AttributoVariante? get attributoColore {
    try {
      // Cerca nella lista il primo attributo che:
      // 1. Ha il nome 'colore' (ignorando maiuscole/minuscole).
      // 2. Ha un campo 'valore' che non è nullo e non è una stringa vuota.
      return attributi.firstWhere(
        (a) => a.nome.toLowerCase() == 'colore' && a.valore != null && a.valore!.isNotEmpty,
      );
    } catch (e) {
      // Il metodo 'firstWhere' lancia un errore se non trova elementi.
      // Noi intercettiamo l'errore e restituiamo 'null' per indicare che
      // questa variante non ha un attributo colore valido.
      return null;
    }
  }
}