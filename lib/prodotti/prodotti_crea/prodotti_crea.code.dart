import 'package:flutter/material.dart';
import '../class_prodotti.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Controller per la creazione e gestione dei prodotti
/// Usa PlatformManager per supporto multi-piattaforma
class ProdottiCreaController {
  // Cache per evitare chiamate ripetute
  List<CategoriaProdotto>? _categoriesCache;
  List<TagProdotto>? _tagsCache;

  ProdottiCreaController();

  // =======================================================
  // == METODI PRINCIPALI                                 ==
  // =======================================================

  /// Carica i prodotti per l'autocompletamento
  Future<List<ProdottoWoo>> listProducts({int page = 1, int perPage = 100}) async {
    return await PlatformManager.prodotti.getProducts(
      page: page,
      perPage: perPage,
    );
  }

  /// Ottiene tutte le categorie con cache
  Future<List<CategoriaProdotto>> getCategories({bool forceRefresh = false}) async {
    if (_categoriesCache == null || forceRefresh) {
      _categoriesCache = await PlatformManager.categorie.getCategories(perPage: 100);
    }
    return _categoriesCache!;
  }

  /// Ottiene tutti i tag con cache
  Future<List<TagProdotto>> getTags({bool forceRefresh = false}) async {
    if (_tagsCache == null || forceRefresh) {
      _tagsCache = await PlatformManager.tag.getTags(perPage: 100);
    }
    return _tagsCache!;
  }

  /// Ottiene tutti gli attributi con cache
  Future<List<dynamic>> getAttributes({bool forceRefresh = false}) async {
    return await PlatformManager.attributi.getAttributes();
  }

  /// Ottiene i termini di un attributo specifico
  Future<List<dynamic>> getAttributeTerms(int attributeId, {bool forceRefresh = false}) async {
    return await PlatformManager.attributi.getAttributeTerms(attributeId);
  }

  /// Crea una nuova categoria se non esiste
  Future<CategoriaProdotto?> createCategoryIfNotExists(BuildContext context, String categoryName) async {
    final categories = await getCategories();
    final existing = categories.where((c) => c.nome.toLowerCase() == categoryName.toLowerCase()).firstOrNull;

    if (existing != null) {
      return existing;
    }

    final newCategoryData = await _showCreateDialog(context, 'Crea Nuova Categoria', {'Nome': categoryName, 'Slug': ''});
    if (newCategoryData != null) {
      final newCategory = await PlatformManager.categorie.createCategory(
        name: newCategoryData['Nome']!,
        slug: newCategoryData['Slug'],
        description: newCategoryData['Descrizione'],
      );
      _categoriesCache?.add(newCategory);
      return newCategory;
    }
    return null;
  }

  /// Crea un nuovo tag se non esiste
  Future<TagProdotto?> createTagIfNotExists(BuildContext context, String tagName) async {
    final tags = await getTags();
    final existing = tags.where((t) => t.nome.toLowerCase() == tagName.toLowerCase()).firstOrNull;

    if (existing != null) {
      return existing;
    }

    final newTagData = await _showCreateDialog(context, 'Crea Nuovo Tag', {'Nome': tagName, 'Slug': ''});
    if (newTagData != null) {
      final newTag = await PlatformManager.tag.createTag(
        name: newTagData['Nome']!,
        slug: newTagData['Slug'],
        description: newTagData['Descrizione'],
      );
      _tagsCache?.add(newTag);
      return newTag;
    }
    return null;
  }

  /// Crea un nuovo attributo se non esiste
  Future<dynamic> createAttributeIfNotExists(BuildContext context, String attributeName) async {
    final attributes = await getAttributes();
    final existing = attributes.firstWhere(
      (a) => a.name?.toLowerCase() == attributeName.toLowerCase(),
      orElse: () => null,
    );

    if (existing != null) {
      return existing;
    }

    // Crea nuovo attributo
    return await PlatformManager.attributi.createAttribute(
      name: attributeName,
      slug: attributeName.toLowerCase().replaceAll(' ', '-'),
      type: 'select',
      orderBy: 'menu_order',
      hasArchives: true,
    );
  }

  Future<Map<String, String>?> _showCreateDialog(BuildContext context, String title, Map<String, String> fields) async {
    final controllers = { for (var key in fields.keys) key: TextEditingController(text: fields[key]) };

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.keys.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(labelText: key),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = { for (var key in fields.keys) key: controllers[key]!.text };
                Navigator.of(context).pop(result);
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }

  /// Crea un nuovo prodotto
  Future<ProdottoWoo> creaProdotto(ProdottoWoo prodotto) async {
    try {
      // Usa PlatformManager per creare il prodotto
      return await PlatformManager.prodotti.createProduct(prodotto);
    } catch (e) {
      throw Exception('Errore durante la creazione del prodotto: $e');
    }
  }

  /// Aggiorna un prodotto esistente
  Future<ProdottoWoo> aggiornaProdotto(ProdottoWoo prodotto) async {
    try {
      // Usa PlatformManager per aggiornare il prodotto
      return await PlatformManager.prodotti.updateProduct(prodotto);
    } catch (e) {
      throw Exception('Errore durante l\'aggiornamento del prodotto: $e');
    }
  }


  /// Determina il tipo di attributo basandosi sul nome
  TipoAttributo determinaTipoAttributo(String nome) {
    const colorNames = ['colore', 'color', 'tonalità', 'tinta'];
    if (colorNames.contains(nome.toLowerCase())) {
      return TipoAttributo.color;
    }
    switch (nome.toLowerCase()) {
      case 'taglia':
      case 'size':
        return TipoAttributo.button;
      case 'materiale':
      case 'material':
        return TipoAttributo.label;
      default:
        return TipoAttributo.select;
    }
  }

  bool isColorAttribute(String attributeName) {
    return determinaTipoAttributo(attributeName) == TipoAttributo.color;
  }

  /// Utility per capitalizzare la prima lettera
  String capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  // =======================================================
  // == GESTIONE VARIANTI E ATTRIBUTI                     ==
  // =======================================================

  /// Processa gli attributi delle varianti, creandoli se non esistono
  Future<Map<String, dynamic>> processaAttributiVarianti(List<VarianteWoo> varianti) async {
    final attributiRichiesti = <String, Set<String>>{};
    final attributiEsistenti = <String, dynamic>{};

    // Raccoglie tutti gli attributi necessari dalle varianti
    for (final variante in varianti) {
      for (final attributo in variante.attributi) {
        final nomeKey = attributo.nome.toLowerCase();
        if (!attributiRichiesti.containsKey(nomeKey)) {
          attributiRichiesti[nomeKey] = <String>{};
        }
        attributiRichiesti[nomeKey]!.add(attributo.opzione);
      }
    }

    // Ottiene gli attributi esistenti
    final attributiWoo = await getAttributes();

    for (final attr in attributiWoo) {
      if (attr.name != null) {
        attributiEsistenti[attr.name!.toLowerCase()] = attr;
      }
    }

    // Crea gli attributi mancanti
    for (final entry in attributiRichiesti.entries) {
      final nomeAttributo = entry.key;
      final opzioni = entry.value;

      if (!attributiEsistenti.containsKey(nomeAttributo)) {
        // Crea il nuovo attributo
        final nuovoAttributo = await PlatformManager.attributi.createAttribute(
          name: capitalizeFirst(nomeAttributo),
          slug: nomeAttributo.replaceAll(' ', '-'),
          type: determinaTipoAttributo(nomeAttributo).toString().split('.').last,
          orderBy: 'menu_order',
          hasArchives: true,
        );
        attributiEsistenti[nomeAttributo] = nuovoAttributo;
      }

      // Gestisce i termini dell'attributo
      final attr = attributiEsistenti[nomeAttributo];
      if (attr.id != null) {
        await _gestisciTerminiAttributo(attr.id!, opzioni);
      }
    }

    return attributiEsistenti;
  }

  /// Gestisce i termini di un attributo (crea se non esistono)
  Future<void> _gestisciTerminiAttributo(int attributoId, Set<String> opzioni) async {
    final terminiEsistenti = await PlatformManager.attributi.getAttributeTerms(attributoId);
    final terminiEsistentiMap = {
      for (var t in terminiEsistenti)
        if (t.name != null) t.name!.toLowerCase(): t
    };

    for (final opzione in opzioni) {
      if (!terminiEsistentiMap.containsKey(opzione.toLowerCase())) {
        await PlatformManager.attributi.createAttributeTerm(
          attributeId: attributoId,
          name: opzione,
          slug: opzione.toLowerCase().replaceAll(' ', '-'),
        );
      }
    }
  }

  /// Gestisce le varianti di un prodotto (create/update/delete)
  Future<void> gestisciVariantiProdotto(
    int productId,
    List<VarianteWoo> nuoveVarianti,
  ) async {
    // Ottiene le varianti esistenti
    final variantiEsistenti = await PlatformManager.varianti.getProductVariations(productId);
    final variantiEsistentiMap = {for (var v in variantiEsistenti) v.id: v};

    // Liste per operazioni batch
    final variantiDaCreare = <VarianteWoo>[];
    final variantiDaAggiornare = <VarianteWoo>[];
    final variantiDaEliminare = <int>[];

    // Identifica operazioni necessarie
    for (final nuovaVariante in nuoveVarianti) {
      if (nuovaVariante.id == 0 || !variantiEsistentiMap.containsKey(nuovaVariante.id)) {
        // Variante nuova da creare
        variantiDaCreare.add(nuovaVariante);
      } else {
        // Variante esistente da aggiornare
        variantiDaAggiornare.add(nuovaVariante);
        variantiEsistentiMap.remove(nuovaVariante.id);
      }
    }

    // Le varianti rimaste in variantiEsistentiMap devono essere eliminate
    variantiDaEliminare.addAll(variantiEsistentiMap.keys.cast<int>());

    // Esegue le operazioni
    print('🔵 Gestione varianti: ${variantiDaCreare.length} da creare, ${variantiDaAggiornare.length} da aggiornare, ${variantiDaEliminare.length} da eliminare');

    // Crea nuove varianti
    for (final variante in variantiDaCreare) {
      try {
        await PlatformManager.varianti.createVariation(
          productId: productId,
          variante: variante,
        );
        print('✅ Variante creata: ${variante.sku}');
      } catch (e) {
        print('❌ Errore creazione variante ${variante.sku}: $e');
        rethrow;
      }
    }

    // Aggiorna varianti esistenti
    for (final variante in variantiDaAggiornare) {
      try {
        await PlatformManager.varianti.updateVariation(
          productId: productId,
          variante: variante,
        );
        print('✅ Variante aggiornata: ${variante.sku}');
      } catch (e) {
        print('❌ Errore aggiornamento variante ${variante.sku}: $e');
        rethrow;
      }
    }

    // Elimina varianti obsolete
    for (final varianteId in variantiDaEliminare) {
      try {
        await PlatformManager.varianti.deleteVariation(
          productId: productId,
          variationId: varianteId,
        );
        print('✅ Variante eliminata: ID $varianteId');
      } catch (e) {
        print('❌ Errore eliminazione variante ID $varianteId: $e');
        // Non rilancia l'errore per l'eliminazione, continua con le altre
      }
    }
  }

  /// Crea o aggiorna un prodotto completo con le sue varianti
  Future<ProdottoWoo> salvaProductoConVarianti(ProdottoWoo prodotto) async {
    try {
      // Step 1: Processa gli attributi se ci sono varianti
      if (prodotto.varianti.isNotEmpty) {
        print('🔵 Processamento attributi per ${prodotto.varianti.length} varianti...');
        await processaAttributiVarianti(prodotto.varianti);
      }

      // Step 2: Crea o aggiorna il prodotto principale
      print('🔵 ${prodotto.id == 0 ? 'Creazione' : 'Aggiornamento'} prodotto: ${prodotto.nome}');
      final ProdottoWoo prodottoSalvato;

      if (prodotto.id == 0) {
        // Crea prodotto nuovo
        prodottoSalvato = await creaProdotto(prodotto);
      } else {
        // Aggiorna prodotto esistente
        prodottoSalvato = await aggiornaProdotto(prodotto);
      }

      // Step 3: Gestisci le varianti se presenti
      if (prodotto.varianti.isNotEmpty) {
        print('🔵 Gestione varianti per prodotto ID ${prodottoSalvato.id}...');
        await gestisciVariantiProdotto(prodottoSalvato.id, prodotto.varianti);
      }

      print('✅ Prodotto salvato con successo: ${prodottoSalvato.nome}');
      return prodottoSalvato;
    } catch (e) {
      print('❌ Errore salvataggio prodotto con varianti: $e');
      rethrow;
    }
  }

  /// Mostra un dialog per selezionare un colore
  Future<Color?> showColorPickerDialog(BuildContext context, {Color? initialColor}) async {
    Color selectedColor = initialColor ?? Colors.red;

    return await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleziona un colore'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Seleziona'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );
  }

  /// Converte un colore in formato esadecimale (es: #FF5733)
  String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Converte una stringa esadecimale in Color
  Color? hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Pulisce la cache
  void clearCache() {
    _categoriesCache = null;
    _tagsCache = null;
  }
}

// Extension per gestire valori null nelle liste
extension ListExtensions<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }
}