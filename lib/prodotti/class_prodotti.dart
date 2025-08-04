// Esempio di come dovrebbe essere la classe in class_prodotti.dart

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

class VarianteWoo {
  final int id;
  final String nome;
  final String sku;
  final double prezzo;
  final int quantita;
  final String? immagineUrl; // QUESTO CAMPO È IMPORTANTE!

  VarianteWoo({
    required this.id,
    required this.nome,
    required this.sku,
    required this.prezzo,
    required this.quantita,
    this.immagineUrl, // Campo opzionale per l'immagine della variante
  });
}