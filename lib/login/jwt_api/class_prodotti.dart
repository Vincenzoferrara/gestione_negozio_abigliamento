import 'package:flutter/material.dart';

class Prodotto {
  final int id;
  final String nome;
  final String sku;
  final double prezzoNormale;
  final double? prezzoScontato;
  final String descrizioneBreve;
  final String? descrizioneCompleta;
  final String immagineUrl;
  final List<String> immaginiAggiuntive;
  final List<Variante> varianti;
  final String categoria;
  final List<String> tag;
  final bool inStock;
  final int? quantitaTotale;
  final String? peso;
  final Dimensioni? dimensioni;
  final String? marca;
  final DateTime? dataCreazione;
  final DateTime? dataModifica;
  final String status; // draft, publish, private
  final Map<String, dynamic>? metadatiCustom;

  Prodotto({
    required this.id,
    required this.nome,
    required this.sku,
    required this.prezzoNormale,
    this.prezzoScontato,
    required this.descrizioneBreve,
    this.descrizioneCompleta,
    required this.immagineUrl,
    List<String>? immaginiAggiuntive,
    required this.varianti,
    required this.categoria,
    List<String>? tag,
    required this.inStock,
    this.quantitaTotale,
    this.peso,
    this.dimensioni,
    this.marca,
    this.dataCreazione,
    this.dataModifica,
    this.status = 'draft',
    this.metadatiCustom,
  }) : immaginiAggiuntive = immaginiAggiuntive ?? [],
       tag = tag ?? [];

  Prodotto copyWith({
    int? id,
    String? nome,
    String? sku,
    double? prezzoNormale,
    double? prezzoScontato,
    String? descrizioneBreve,
    String? descrizioneCompleta,
    String? immagineUrl,
    List<String>? immaginiAggiuntive,
    List<Variante>? varianti,
    String? categoria,
    List<String>? tag,
    bool? inStock,
    int? quantitaTotale,
    String? peso,
    Dimensioni? dimensioni,
    String? marca,
    DateTime? dataCreazione,
    DateTime? dataModifica,
    String? status,
    Map<String, dynamic>? metadatiCustom,
  }) {
    return Prodotto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sku: sku ?? this.sku,
      prezzoNormale: prezzoNormale ?? this.prezzoNormale,
      prezzoScontato: prezzoScontato ?? this.prezzoScontato,
      descrizioneBreve: descrizioneBreve ?? this.descrizioneBreve,
      descrizioneCompleta: descrizioneCompleta ?? this.descrizioneCompleta,
      immagineUrl: immagineUrl ?? this.immagineUrl,
      immaginiAggiuntive: immaginiAggiuntive ?? this.immaginiAggiuntive,
      varianti: varianti ?? this.varianti,
      categoria: categoria ?? this.categoria,
      tag: tag ?? this.tag,
      inStock: inStock ?? this.inStock,
      quantitaTotale: quantitaTotale ?? this.quantitaTotale,
      peso: peso ?? this.peso,
      dimensioni: dimensioni ?? this.dimensioni,
      marca: marca ?? this.marca,
      dataCreazione: dataCreazione ?? this.dataCreazione,
      dataModifica: dataModifica ?? this.dataModifica,
      status: status ?? this.status,
      metadatiCustom: metadatiCustom ?? this.metadatiCustom,
    );
  }

  /// Calcola il prezzo effettivo (scontato se disponibile, altrimenti normale)
  double get prezzoEffettivo => prezzoScontato ?? prezzoNormale;
  
  double? get percentualeSconto {
    if (prezzoScontato == null || prezzoNormale == 0) return null;
    return ((prezzoNormale - prezzoScontato!) / prezzoNormale) * 100;
  }

  /// Verifica se il prodotto ha varianti
  bool get hasVarianti => varianti.isNotEmpty;

  /// Ottiene tutte le immagini del prodotto (principale + aggiuntive)
  List<String> get tutteLeImmagini => [immagineUrl, ...immaginiAggiuntive];
  
  int get quantitaTotaleVarianti {
    if (varianti.isEmpty) return quantitaTotale ?? 0;
    return varianti.fold(0, (sum, variante) => sum + variante.quantita);
  }

  /// Verifica se il prodotto è disponibile (ha stock)
  bool get isDisponibile {
    if (!hasVarianti) return inStock && (quantitaTotale ?? 0) > 0;
    return varianti.any((v) => v.quantita > 0);
  }
}

class ColorUtils {
  /// Converte una stringa esadecimale in un oggetto Color.
  static Color colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  /// Converte un oggetto Color in una stringa esadecimale nel formato #RRGGBB.
  static String colorToHex(Color color, {bool leadingHashSign = true}) {
    return '${leadingHashSign ? '#' : ''}'
        '${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
  }
}

/// Rappresenta le dimensioni di un prodotto
class Dimensioni {
  final double lunghezza;
  final double larghezza;
  final double altezza;
  final String unita; // cm, mm, in, etc.

  Dimensioni({
    required this.lunghezza,
    required this.larghezza,
    required this.altezza,
    this.unita = 'cm',
  });

  /// Calcola il volume
  double get volume => lunghezza * larghezza * altezza;

  @override
  String toString() => '${lunghezza}x${larghezza}x$altezza $unita';
}

/// Rappresenta un singolo attributo di una variante.
class Attributo {
  final int? id;
  final String nome;
  final String opzione;
  final String? valore;
  final String? slug;
  final TipoAttributo tipo;
  final bool visibile;
  final bool usatoPerVariazioni;

  Attributo({
    this.id,
    required this.nome,
    required this.opzione,
    this.valore,
    this.slug,
    this.tipo = TipoAttributo.select,
    this.visibile = true,
    this.usatoPerVariazioni = true,
  });

  /// Crea una copia dell'attributo con i campi specificati modificati
  Attributo copyWith({
    int? id,
    String? nome,
    String? opzione,
    String? valore,
    String? slug,
    TipoAttributo? tipo,
    bool? visibile,
    bool? usatoPerVariazioni,
  }) {
    return Attributo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      opzione: opzione ?? this.opzione,
      valore: valore ?? this.valore,
      slug: slug ?? this.slug,
      tipo: tipo ?? this.tipo,
      visibile: visibile ?? this.visibile,
      usatoPerVariazioni: usatoPerVariazioni ?? this.usatoPerVariazioni,
    );
  }

  /// Verifica se l'attributo ha un valore specifico (per colori, immagini, etc.)
  bool get hasValore => valore != null && valore!.isNotEmpty;

  @override
  String toString() => '$nome: $opzione${hasValore ? ' ($valore)' : ''}';
}

/// Enum per i tipi di attributo supportati
enum TipoAttributo {
  select,
  color,
  image,
  label,
  button,
  radio,
  text,
}

/// Extension per convertire TipoAttributo in stringa e viceversa
extension TipoAttributoExtension on TipoAttributo {
  String get value {
    switch (this) {
      case TipoAttributo.select: return 'select';
      case TipoAttributo.color: return 'color';
      case TipoAttributo.image: return 'image';
      case TipoAttributo.label: return 'label';
      case TipoAttributo.button: return 'button';
      case TipoAttributo.radio: return 'radio';
      case TipoAttributo.text: return 'text';
    }
  }

  static TipoAttributo fromString(String value) {
    switch (value.toLowerCase()) {
      case 'color': return TipoAttributo.color;
      case 'image': return TipoAttributo.image;
      case 'label': return TipoAttributo.label;
      case 'button': return TipoAttributo.button;
      case 'radio': return TipoAttributo.radio;
      case 'text': return TipoAttributo.text;
      default: return TipoAttributo.select;
    }
  }
}

/// Rappresenta una singola variante di un Prodotto.
class Variante {
  final int id;
  final String nome;
  final List<Attributo> attributi;
  final String sku;
  final double prezzo;
  final double? prezzoScontato;
  final int quantita;
  final String? immagineUrl;
  final List<String> immaginiAggiuntive;
  final String? peso;
  final Dimensioni? dimensioni;
  final bool attiva;
  final Map<String, dynamic>? metadatiCustom;

  Variante({
    required this.id,
    required this.nome,
    required this.attributi,
    required this.sku,
    required this.prezzo,
    this.prezzoScontato,
    required this.quantita,
    this.immagineUrl,
    List<String>? immaginiAggiuntive,
    this.peso,
    this.dimensioni,
    this.attiva = true,
    this.metadatiCustom,
  }) : immaginiAggiuntive = immaginiAggiuntive ?? [];

  /// Crea una copia della variante con i campi specificati modificati
  Variante copyWith({
    int? id,
    String? nome,
    List<Attributo>? attributi,
    String? sku,
    double? prezzo,
    double? prezzoScontato,
    int? quantita,
    String? immagineUrl,
    List<String>? immaginiAggiuntive,
    String? peso,
    Dimensioni? dimensioni,
    bool? attiva,
    Map<String, dynamic>? metadatiCustom,
  }) {
    return Variante(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      attributi: attributi ?? this.attributi,
      sku: sku ?? this.sku,
      prezzo: prezzo ?? this.prezzo,
      prezzoScontato: prezzoScontato ?? this.prezzoScontato,
      quantita: quantita ?? this.quantita,
      immagineUrl: immagineUrl ?? this.immagineUrl,
      immaginiAggiuntive: immaginiAggiuntive ?? this.immaginiAggiuntive,
      peso: peso ?? this.peso,
      dimensioni: dimensioni ?? this.dimensioni,
      attiva: attiva ?? this.attiva,
      metadatiCustom: metadatiCustom ?? this.metadatiCustom,
    );
  }

  /// Calcola il prezzo effettivo (scontato se disponibile, altrimenti normale)
  double get prezzoEffettivo => prezzoScontato ?? prezzo;

  /// Nome visualizzabile basato sugli attributi
  String get nomeVisualizzabile {
    if (attributi.isEmpty) return nome.isEmpty ? 'Variante' : nome;
    return attributi.map((a) => a.opzione).join(' - ');
  }

  /// Trova l'attributo colore nella variante
  Attributo? get attributoColore {
    try {
      return attributi.firstWhere(
        (a) => a.tipo == TipoAttributo.color && a.hasValore,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica se la variante è disponibile
  bool get isDisponibile => attiva && quantita > 0;

  /// Ottiene tutte le immagini della variante
  List<String> get tutteLeImmagini {
    if (immagineUrl == null) return immaginiAggiuntive;
    return [immagineUrl!, ...immaginiAggiuntive];
  }

  /// Calcola la percentuale di sconto se presente
  double? get percentualeSconto {
    if (prezzoScontato == null || prezzo == 0) return null;
    return ((prezzo - prezzoScontato!) / prezzo) * 100;
  }

  @override
  String toString() => '$nomeVisualizzabile (SKU: $sku, Prezzo: €${prezzoEffettivo.toStringAsFixed(2)})';
}

/// Classe per rappresentare una categoria di prodotti
class Categoria {
  final int id;
  final String nome;
  final String slug;
  final String? descrizione;
  final String? immagine;
  final int? parentId;
  final int count;
  final bool visibile;

  Categoria({
    required this.id,
    required this.nome,
    required this.slug,
    this.descrizione,
    this.immagine,
    this.parentId,
    this.count = 0,
    this.visibile = true,
  });

  /// Verifica se è una categoria principale (senza parent)
  bool get isPrincipale => parentId == null;

  @override
  String toString() => nome;
}

/// Classe per rappresentare un tag di prodotto
class Tag {
  final int id;
  final String nome;
  final String slug;
  final String? descrizione;
  final int count;

  Tag({
    required this.id,
    required this.nome,
    required this.slug,
    this.descrizione,
    this.count = 0,
  });

  @override
  String toString() => nome;
}

/// Classe per rappresentare un ordine
class Ordine {
  final int id;
  final String numero;
  final String status;
  final String valuta;
  final double totale;
  final double subtotale;
  final double totaleTasse;
  final double totaleSpedizione;
  final List<RigaOrdine> righe;
  final IndirizzoSpedizione? indirizzoSpedizione;
  final IndirizzoFatturazione? indirizzoFatturazione;
  final Cliente? cliente;
  final DateTime dataCreazione;
  final DateTime? dataCompletamento;
  final String? note;
  final String metodoPagamento;
  final String? metodoSpedizione;
  final Map<String, dynamic>? metadati;

  Ordine({
    required this.id,
    required this.numero,
    required this.status,
    required this.valuta,
    required this.totale,
    required this.subtotale,
    required this.totaleTasse,
    required this.totaleSpedizione,
    required this.righe,
    this.indirizzoSpedizione,
    this.indirizzoFatturazione,
    this.cliente,
    required this.dataCreazione,
    this.dataCompletamento,
    this.note,
    required this.metodoPagamento,
    this.metodoSpedizione,
    this.metadati,
  });

  /// Calcola il numero totale di articoli nell'ordine
  int get totalePezzi => righe.fold(0, (sum, riga) => sum + riga.quantita);

  /// Verifica se l'ordine è completato
  bool get isCompletato => status == 'completed';

  /// Verifica se l'ordine è in elaborazione
  bool get isInElaborazione => status == 'processing';
}

/// Rappresenta una riga dell'ordine
class RigaOrdine {
  final int id;
  final int prodottoId;
  final int? varianteId;
  final String nome;
  final String sku;
  final int quantita;
  final double prezzo;
  final double totale;
  final Map<String, String>? attributi;

  RigaOrdine({
    required this.id,
    required this.prodottoId,
    this.varianteId,
    required this.nome,
    required this.sku,
    required this.quantita,
    required this.prezzo,
    required this.totale,
    this.attributi,
  });
}

/// Rappresenta un cliente
class Cliente {
  final int id;
  final String email;
  final String? nome;
  final String? cognome;
  final String? username;
  final DateTime? dataRegistrazione;
  final int totaleOrdini;
  final double totaleSpeso;
  final IndirizzoFatturazione? indirizzoFatturazione;
  final IndirizzoSpedizione? indirizzoSpedizione;

  Cliente({
    required this.id,
    required this.email,
    this.nome,
    this.cognome,
    this.username,
    this.dataRegistrazione,
    this.totaleOrdini = 0,
    this.totaleSpeso = 0.0,
    this.indirizzoFatturazione,
    this.indirizzoSpedizione,
  });

  String get nomeCompleto {
    if (nome != null && cognome != null) {
      return '$nome $cognome';
    }
    return username ?? email;
  }
}

/// Indirizzo di spedizione
class IndirizzoSpedizione {
  final String? nome;
  final String? cognome;
  final String? azienda;
  final String indirizzo1;
  final String? indirizzo2;
  final String citta;
  final String? provincia;
  final String cap;
  final String paese;

  IndirizzoSpedizione({
    this.nome,
    this.cognome,
    this.azienda,
    required this.indirizzo1,
    this.indirizzo2,
    required this.citta,
    this.provincia,
    required this.cap,
    required this.paese,
  });
}

/// Indirizzo di fatturazione
class IndirizzoFatturazione {
  final String? nome;
  final String? cognome;
  final String? azienda;
  final String indirizzo1;
  final String? indirizzo2;
  final String citta;
  final String? provincia;
  final String cap;
  final String paese;
  final String? email;
  final String? telefono;

  IndirizzoFatturazione({
    this.nome,
    this.cognome,
    this.azienda,
    required this.indirizzo1,
    this.indirizzo2,
    required this.citta,
    this.provincia,
    required this.cap,
    required this.paese,
    this.email,
    this.telefono,
  });
}

/// Rappresenta un coupon/buono sconto
class Coupon {
  final int id;
  final String codice;
  final String tipo; // 'percent', 'fixed_cart', 'fixed_product'
  final double importo;
  final String? descrizione;
  final DateTime? dataScadenza;
  final double? importoMinimoOrdine;
  final double? importoMassimoOrdine;
  final int? limiteUtilizzo;
  final int utilizziTotali;
  final bool attivo;
  final List<int>? prodottiInclusi;
  final List<int>? prodottiEsclusi;
  final List<int>? categorieIncluse;
  final List<int>? categorieEscluse;

  Coupon({
    required this.id,
    required this.codice,
    required this.tipo,
    required this.importo,
    this.descrizione,
    this.dataScadenza,
    this.importoMinimoOrdine,
    this.importoMassimoOrdine,
    this.limiteUtilizzo,
    this.utilizziTotali = 0,
    this.attivo = true,
    this.prodottiInclusi,
    this.prodottiEsclusi,
    this.categorieIncluse,
    this.categorieEscluse,
  });

  /// Verifica se il coupon è scaduto
  bool get isScaduto => dataScadenza != null && DateTime.now().isAfter(dataScadenza!);

  /// Verifica se il coupon ha raggiunto il limite di utilizzi
  bool get hasRaggiuntoLimite => limiteUtilizzo != null && utilizziTotali >= limiteUtilizzo!;

  /// Verifica se il coupon è utilizzabile
  bool get isUtilizzabile => attivo && !isScaduto && !hasRaggiuntoLimite;
}

/// Classe per la gestione dei filtri di ricerca
class Filtri {
  final String? search;
  final List<int>? categorieIds;
  final List<int>? tagIds;
  final double? prezzoMin;
  final double? prezzoMax;
  final bool? inStock;
  final String? status;
  final List<String>? skus;
  final String? orderBy;
  final String? order;
  final int page;
  final int perPage;
  final Map<String, List<String>>? attributi;

  Filtri({
    this.search,
    this.categorieIds,
    this.tagIds,
    this.prezzoMin,
    this.prezzoMax,
    this.inStock,
    this.status,
    this.skus,
    this.orderBy = 'date',
    this.order = 'desc',
    this.page = 1,
    this.perPage = 10,
    this.attributi,
  });

  /// Crea una copia del filtro con i parametri modificati
  Filtri copyWith({
    String? search,
    List<int>? categorieIds,
    List<int>? tagIds,
    double? prezzoMin,
    double? prezzoMax,
    bool? inStock,
    String? status,
    List<String>? skus,
    String? orderBy,
    String? order,
    int? page,
    int? perPage,
    Map<String, List<String>>? attributi,
  }) {
    return Filtri(
      search: search ?? this.search,
      categorieIds: categorieIds ?? this.categorieIds,
      tagIds: tagIds ?? this.tagIds,
      prezzoMin: prezzoMin ?? this.prezzoMin,
      prezzoMax: prezzoMax ?? this.prezzoMax,
      inStock: inStock ?? this.inStock,
      status: status ?? this.status,
      skus: skus ?? this.skus,
      orderBy: orderBy ?? this.orderBy,
      order: order ?? this.order,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      attributi: attributi ?? this.attributi,
    );
  }
}

/// Classe per il risultato di una ricerca paginata
class RisultatoPaginato<T> {
  final List<T> dati;
  final int totaleElementi;
  final int totalePagine;
  final int paginaCorrente;
  final int elementiPerPagina;
  final bool hasPaginaPrecedente;
  final bool hasPaginaSuccessiva;

  RisultatoPaginato({
    required this.dati,
    required this.totaleElementi,
    required this.totalePagine,
    required this.paginaCorrente,
    required this.elementiPerPagina,
  }) : hasPaginaPrecedente = paginaCorrente > 1,
       hasPaginaSuccessiva = paginaCorrente < totalePagine;
}

/// Classe per le statistiche
class Statistiche {
  final int totaleProdotti;
  final int prodottiPubblicati;
  final int prodottiBozza;
  final int prodottiConVarianti;
  final int prodottiInStock;
  final int prodottiOutOfStock;
  final double valoreInventarioTotale;
  final Map<String, int> prodottiPerCategoria;
  final Map<String, int> prodottiPerTag;

  Statistiche({
    required this.totaleProdotti,
    required this.prodottiPubblicati,
    required this.prodottiBozza,
    required this.prodottiConVarianti,
    required this.prodottiInStock,
    required this.prodottiOutOfStock,
    required this.valoreInventarioTotale,
    required this.prodottiPerCategoria,
    required this.prodottiPerTag,
  });
}

/// Classe per rappresentare un'operazione batch
class OperazioneBatch<T> {
  final List<T> create;
  final List<T> update;
  final List<int> delete;

  OperazioneBatch({
    List<T>? create,
    List<T>? update,
    List<int>? delete,
  }) : create = create ?? [],
       update = update ?? [],
       delete = delete ?? [];

  bool get isEmpty => create.isEmpty && update.isEmpty && delete.isEmpty;
  bool get hasOperazioni => !isEmpty;
  int get totaleOperazioni => create.length + update.length + delete.length;
}

/// Risultato di un'operazione batch
class RisultatoBatch<T> {
  final List<T> created;
  final List<T> updated;
  final List<T> deleted;
  final List<String> errori;
  final bool success;

  RisultatoBatch({
    List<T>? created,
    List<T>? updated,
    List<T>? deleted,
    List<String>? errori,
  }) : created = created ?? [],
       updated = updated ?? [],
       deleted = deleted ?? [],
       errori = errori ?? [],
       success = (errori ?? []).isEmpty;

  int get totaleSuccessi => created.length + updated.length + deleted.length;
  bool get hasErrori => errori.isNotEmpty;
}

/// Classe per la validazione
class ValidatoreProdotti {
  static List<String> valida(Prodotto prodotto) {
    final errori = <String>[];

    if (prodotto.nome.trim().isEmpty) {
      errori.add('Il nome del prodotto è obbligatorio');
    }
    if (prodotto.sku.trim().isEmpty) {
      errori.add('Il SKU è obbligatorio');
    }
    if (prodotto.prezzoNormale <= 0) {
      errori.add('Il prezzo normale deve essere maggiore di 0');
    }
    if (prodotto.prezzoScontato != null && prodotto.prezzoScontato! >= prodotto.prezzoNormale) {
      errori.add('Il prezzo scontato deve essere minore del prezzo normale');
    }
    if (prodotto.descrizioneBreve.trim().isEmpty) {
      errori.add('La descrizione breve è obbligatoria');
    }
    if (prodotto.categoria.trim().isEmpty) {
      errori.add('La categoria è obbligatoria');
    }

    // Validazione URL immagine
    if (prodotto.immagineUrl.isNotEmpty && !_isValidUrl(prodotto.immagineUrl)) {
      errori.add('URL dell\'immagine principale non valido');
    }

    // Validazione varianti
    if (prodotto.varianti.isNotEmpty) {
      errori.addAll(_validaVarianti(prodotto.varianti));
    }

    return errori;
  }

  static List<String> _validaVarianti(List<Variante> varianti) {
    final errori = <String>[];
    final skusUsati = <String>{};

    for (int i = 0; i < varianti.length; i++) {
      final variante = varianti[i];
      final prefisso = 'Variante ${i + 1}: ';

      if (variante.sku.trim().isEmpty) {
        errori.add('${prefisso}SKU obbligatorio');
      } else if (skusUsati.contains(variante.sku)) {
        errori.add('${prefisso}SKU duplicato');
      } else {
        skusUsati.add(variante.sku);
      }

      if (variante.prezzo <= 0) {
        errori.add('${prefisso}Il prezzo deve essere maggiore di 0');
      }
      if (variante.quantita < 0) {
        errori.add('${prefisso}La quantità non può essere negativa');
      }
      if (variante.attributi.isEmpty) {
        errori.add('${prefisso}Almeno un attributo è richiesto');
      }

      // Validazione attributi
      for (final attributo in variante.attributi) {
        if (attributo.nome.trim().isEmpty) {
          errori.add('${prefisso}Nome attributo obbligatorio');
        }
        if (attributo.opzione.trim().isEmpty) {
          errori.add('${prefisso}Opzione attributo obbligatoria');
        }
      }

      // Validazione URL immagine variante
      if (variante.immagineUrl != null &&
          variante.immagineUrl!.isNotEmpty &&
          !_isValidUrl(variante.immagineUrl!)) {
        errori.add('${prefisso}URL dell\'immagine non valido');
      }
    }

    return errori;
  }

  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}

/// Interfaccia per l'export/import dei prodotti
abstract class ProdottoExportImport {
  /// Esporta i prodotti in formato CSV
  Future<String> esportaCSV(List<Prodotto> prodotti);

  /// Esporta i prodotti in formato JSON
  Future<String> esportaJSON(List<Prodotto> prodotti);

  /// Importa prodotti da CSV
  Future<List<Prodotto>> importaCSV(String csvData);

  /// Importa prodotti da JSON
  Future<List<Prodotto>> importaJSON(String jsonData);
}

/// Formatter per prezzi
class PrezzoFormatter {
  static String formatPrezzo(double prezzo) {
    return '€${prezzo.toStringAsFixed(2)}';
  }
  
  static String formatPrezzoConSconto(double prezzoNormale, double? prezzoScontato) {
    if (prezzoScontato != null) {
      return '${formatPrezzo(prezzoScontato)} (era ${formatPrezzo(prezzoNormale)})';
    }
    return formatPrezzo(prezzoNormale);
  }
}

/// Utility per prodotti
class ProdottoUtils {
  static String getDisponibilitaText(bool inStock) {
    return inStock ? 'Disponibile' : 'Esaurito';
  }
  
  static String getVariantiCountText(int count) {
    return count == 1 ? '1 variante' : '$count varianti';
  }
  
  static String getVariantiCountShort(int count) {
    return '$count var.';
  }
}

/// Classe per informazioni display prodotto
class ProdottoDisplayInfo {
  final String id;
  final String nome;
  final String sku;
  final String categoria;
  final String prezzo;
  final String disponibilita;
  final String variantiCount;
  final bool inStock;
  final bool hasSconto;

  ProdottoDisplayInfo({
    required this.id,
    required this.nome,
    required this.sku,
    required this.categoria,
    required this.prezzo,
    required this.disponibilita,
    required this.variantiCount,
    required this.inStock,
    required this.hasSconto,
  });

  factory ProdottoDisplayInfo.fromProdotto(Prodotto prodotto) {
    return ProdottoDisplayInfo(
      id: prodotto.id.toString(),
      nome: prodotto.nome,
      sku: prodotto.sku,
      categoria: prodotto.categoria,
      prezzo: PrezzoFormatter.formatPrezzoConSconto(
        prodotto.prezzoNormale,
        prodotto.prezzoScontato,
      ),
      disponibilita: ProdottoUtils.getDisponibilitaText(prodotto.inStock),
      variantiCount: ProdottoUtils.getVariantiCountText(prodotto.varianti.length),
      inStock: prodotto.inStock,
      hasSconto: prodotto.prezzoScontato != null,
    );
  }
}

/// Enum per tipi di ordinamento
enum TipoOrdinamento {
  nessuno,
  nomeCrescente,
  nomeDecrescente,
  prezzoCrescente,
  prezzoDecrescente,
}

/// Enum per piattaforme supportate
enum PlatformType {
  woocommerce,
  shopify,
  prestashop,
}

/// Enum per stati ordine
enum StatoOrdine {
  pending,
  processing,
  onHold,
  completed,
  cancelled,
  refunded,
  failed,
}

/// Extension per StatoOrdine
extension StatoOrdineExtension on StatoOrdine {
  String get value {
    switch (this) {
      case StatoOrdine.pending: return 'pending';
      case StatoOrdine.processing: return 'processing';
      case StatoOrdine.onHold: return 'on-hold';
      case StatoOrdine.completed: return 'completed';
      case StatoOrdine.cancelled: return 'cancelled';
      case StatoOrdine.refunded: return 'refunded';
      case StatoOrdine.failed: return 'failed';
    }
  }

  String get displayName {
    switch (this) {
      case StatoOrdine.pending: return 'In Attesa';
      case StatoOrdine.processing: return 'In Elaborazione';
      case StatoOrdine.onHold: return 'In Sospeso';
      case StatoOrdine.completed: return 'Completato';
      case StatoOrdine.cancelled: return 'Annullato';
      case StatoOrdine.refunded: return 'Rimborsato';
      case StatoOrdine.failed: return 'Fallito';
    }
  }

  static StatoOrdine fromString(String value) {
    switch (value.toLowerCase()) {
      case 'processing': return StatoOrdine.processing;
      case 'on-hold': return StatoOrdine.onHold;
      case 'completed': return StatoOrdine.completed;
      case 'cancelled': return StatoOrdine.cancelled;
      case 'refunded': return StatoOrdine.refunded;
      case 'failed': return StatoOrdine.failed;
      default: return StatoOrdine.pending;
    }
  }
}

/// Report vendite
class ReportVendite {
  final DateTime periodo;
  final double totaleVendite;
  final int numeroOrdini;
  final double ticketMedio;
  final Map<String, double> venditePerCategoria;
  final Map<String, int> prodottiPiuVenduti;
  final List<VenditaGiornaliera> venditeGiornaliere;

  ReportVendite({
    required this.periodo,
    required this.totaleVendite,
    required this.numeroOrdini,
    required this.ticketMedio,
    required this.venditePerCategoria,
    required this.prodottiPiuVenduti,
    required this.venditeGiornaliere,
  });
}

/// Vendita giornaliera per grafici
class VenditaGiornaliera {
  final DateTime data;
  final double totale;
  final int ordini;

  VenditaGiornaliera({
    required this.data,
    required this.totale,
    required this.ordini,
  });
}

/// Media/File upload
class MediaFile {
  final int id;
  final String url;
  final String? title;
  final String? altText;
  final String? caption;
  final String mimeType;
  final int? width;
  final int? height;
  final int? fileSize;
  final DateTime? dataCreazione;

  MediaFile({
    required this.id,
    required this.url,
    this.title,
    this.altText,
    this.caption,
    required this.mimeType,
    this.width,
    this.height,
    this.fileSize,
    this.dataCreazione,
  });

  /// Verifica se è un'immagine
  bool get isImmagine => mimeType.startsWith('image/');

  /// Dimensione formattata
  String get dimensioneFormattata {
    if (fileSize == null) return 'N/A';
    final size = fileSize!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Backward compatibility getters
  String get nome => title ?? '';
  int get dimensione => fileSize ?? 0;
  DateTime get dataUpload => dataCreazione ?? DateTime.now();
  String? get didascalia => caption;
}