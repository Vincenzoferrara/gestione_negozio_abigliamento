import 'package:flutter/material.dart';

import '../class_prodotti.dart';
import '../../theme/theme.dart';
import 'prodotti_gestisci.code.dart';
import '../../log_viewer/app_logger.dart';

/// Widget per la visualizzazione dei dettagli di un prodotto
/// Questo widget può essere usato sia in modalità side-panel (desktop)
/// che come pagina separata (smartphone)
class ProdottoDettagliView extends StatefulWidget {
  final ProdottoGlobal prodotto;
  final VarianteProductGlobal? varianteSelezionata;
  final Function(VarianteProductGlobal?)? onVarianteSelezionata;
  final bool showCloseButton;
  final VoidCallback? onProductDeleted;
  final VoidCallback? onVariantDeleted;
  final bool requiresDeleteConfirmation;
  final ProdottiGestioneController? controller;

  const ProdottoDettagliView({
    super.key,
    required this.prodotto,
    this.varianteSelezionata,
    this.onVarianteSelezionata,
    this.showCloseButton = false,
    this.onProductDeleted,
    this.onVariantDeleted,
    this.requiresDeleteConfirmation = true,
    this.controller,
  });

  @override
  State<ProdottoDettagliView> createState() => _ProdottoDettagliViewState();
}

class _ProdottoDettagliViewState extends State<ProdottoDettagliView> {
  static const bool _debugVariantiFiltro = false;

  late VarianteProductGlobal? _varianteSelezionata;
  Map<String, String> _filtriVariantiAttivi = {};
  List<VarianteProductGlobal> _variantiFiltrate = [];
  bool _filtraSoloInStock = false;

  @override
  void initState() {
    super.initState();
    _varianteSelezionata = widget.varianteSelezionata;
    // Sincronizza filtri dal controller
    if (widget.controller != null) {
      _filtriVariantiAttivi = Map<String, String>.from(
        widget.controller!.filtriVariantiAttivi,
      );
      _filtraSoloInStock = widget.controller!.filtraSoloInStock;
    }
    _applicaFiltriVarianti();

    // Controlla periodicamente se le varianti sono state caricate
    _checkVariantiCaricate();
  }

  void _checkVariantiCaricate() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.controller != null) {
        final nuoveVarianti = widget.controller!.variantiFiltrate;
        if (nuoveVarianti.length != _variantiFiltrate.length) {
          setState(() {
            _variantiFiltrate = nuoveVarianti;
            _filtriVariantiAttivi = Map<String, String>.from(
              widget.controller!.filtriVariantiAttivi,
            );
          });
        }
        // Continua a controllare se necessario
        if (_variantiFiltrate.isEmpty &&
            widget.controller!.prodottoSelezionato?.variations?.isNotEmpty ==
                true) {
          _checkVariantiCaricate();
        }
      }
    });
  }

  void _selezionaVariante(VarianteProductGlobal? variante) {
    setState(() {
      _varianteSelezionata = variante;
    });
    widget.onVarianteSelezionata?.call(variante);
  }

  String _getCurrentImageUrl() {
    if (_varianteSelezionata?.immagineUrl != null &&
        _varianteSelezionata!.immagineUrl!.isNotEmpty) {
      return _varianteSelezionata!.immagineUrl!;
    }
    return widget.prodotto.immagineUrl ?? '';
  }

  Map<String, List<AttributoVariante>> _getOpzioniFiltroDisponibili() {
    // Se c'è un controller, usa il suo metodo
    if (widget.controller != null) {
      return widget.controller!.getOpzioniFiltroDisponibili();
    }

    // Altrimenti, calcola localmente
    final opzioniUniche = <String, Map<String, AttributoVariante>>{};

    // DEBUG (opzionale): informazioni su varianti/attributi
    if (_debugVariantiFiltro) {
      log.d(
        'DEBUG varianti disponibili: ${widget.prodotto.varianti?.length ?? 0} (prodotto id=${widget.prodotto.id} sku=${widget.prodotto.sku})',
      );
    }
    for (final variante in widget.prodotto.varianti ?? []) {
      if (_debugVariantiFiltro) {
        log.d(
          'DEBUG variante: ${variante.nome} attributi=${variante.attributi.length}',
        );
      }
      for (final attributo in variante.attributi) {
        if (_debugVariantiFiltro) {
          log.d('DEBUG attributo: ${attributo.nome}=${attributo.opzione}');
        }
        opzioniUniche[attributo.nome] ??= {};
        opzioniUniche[attributo.nome]![attributo.opzione] = attributo;
      }
    }

    final risultato = <String, List<AttributoVariante>>{};
    opzioniUniche.forEach((nomeAttributo, mappaOpzioni) {
      risultato[nomeAttributo] = mappaOpzioni.values.toList();
      if (_debugVariantiFiltro) {
        log.d(
          'DEBUG filtro disponibile: $nomeAttributo opzioni=${mappaOpzioni.length}',
        );
      }
    });

    return risultato;
  }

  void _setFiltroVariante(String nomeAttributo, String opzione) {
    widget.controller?.setFiltroVariante(nomeAttributo, opzione);
    // Aggiorna stato locale per UI reattiva
    setState(() {
      if (_filtriVariantiAttivi[nomeAttributo] == opzione) {
        _filtriVariantiAttivi.remove(nomeAttributo);
      } else {
        _filtriVariantiAttivi[nomeAttributo] = opzione;
      }
      _applicaFiltriVarianti();
    });
  }

  void _cancellaFiltriVarianti() {
    widget.controller?.cancellaFiltriVarianti();
    // Aggiorna stato locale per UI reattiva
    setState(() {
      _filtriVariantiAttivi.clear();
      _applicaFiltriVarianti();
    });
  }

  bool _isFiltroVarianteSelezionato(String nomeAttributo, String opzione) {
    return _filtriVariantiAttivi[nomeAttributo] == opzione;
  }

  void _applicaFiltriVarianti() {
    final varianti = widget.prodotto.varianti ?? [];

    if (_filtriVariantiAttivi.isEmpty) {
      _variantiFiltrate = varianti;
    } else {
      _variantiFiltrate = varianti.where((variante) {
        // Verifica che la variante soddisfi tutti i filtri attivi
        for (final entry in _filtriVariantiAttivi.entries) {
          final nomeAttributo = entry.key;
          final opzioneDesiderata = entry.value;

          final haAttributoCorretto = variante.attributi.any(
            (attributo) =>
                attributo.nome == nomeAttributo &&
                attributo.opzione == opzioneDesiderata,
          );

          if (!haAttributoCorretto) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Applica filtro stock se necessario
    if (_filtraSoloInStock) {
      _variantiFiltrate = _variantiFiltrate
          .where((v) => v.quantita > 0)
          .toList();
    }

    // Auto-seleziona la prima variante disponibile se nessuna è selezionata
    if (_varianteSelezionata == null && _variantiFiltrate.isNotEmpty) {
      _varianteSelezionata = _variantiFiltrate.first;
    }
  }

  Widget _buildVariantiChip() {
    final opzioniDisponibili = _getOpzioniFiltroDisponibili();

    if (opzioniDisponibili.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Filtra varianti:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: opzioniDisponibili.entries.map((entry) {
            final nomeAttributo = entry.key;
            final opzioni = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nomeAttributo:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: opzioni.map((opzione) {
                    final isSelected = _isFiltroVarianteSelezionato(
                      nomeAttributo,
                      opzione.opzione,
                    );
                    return FilterChip(
                      label: Text(
                        opzione.opzione,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        _setFiltroVariante(nomeAttributo, opzione.opzione);
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],
            );
          }).toList(),
        ),
        if (_filtriVariantiAttivi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _cancellaFiltriVarianti,
              child: const Text('Cancella filtri'),
            ),
          ),
      ],
    );
  }

  Widget _buildVarianteCard(VarianteProductGlobal variante) {
    final isSelected = _varianteSelezionata?.id == variante.id;
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: variante.quantita > 0
              ? customColors.successColor
              : customColors.stockUnavailable,
          child: Icon(
            variante.quantita > 0 ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          variante.nomeVisualizzabile,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Prezzo: €${variante.prezzo.toStringAsFixed(2)} | Qty: ${variante.quantita}',
        ),
        trailing: variante.attributi.isNotEmpty
            ? Wrap(
                children: variante.attributi
                    .map(
                      (attr) => Chip(
                        label: Text(
                          '${attr.nome}: ${attr.opzione}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              )
            : null,
        onTap: () => _selezionaVariante(variante),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showCloseButton
          ? AppBar(
              title: Text(widget.prodotto.nome ?? ''),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine prodotto
            if (_getCurrentImageUrl().isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_getCurrentImageUrl()),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Immagine non disponibile, mostra placeholder
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Nome prodotto
            Text(
              widget.prodotto.nome ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            if ((widget.prodotto.descrizioneBreve ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.prodotto.descrizioneBreve ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            const SizedBox(height: 16),

            // Filtri varianti
            _buildVariantiChip(),

            const SizedBox(height: 16),

            // Lista varianti filtrate
            Text(
              'Varianti disponibili (${_variantiFiltrate.length}):',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            if (_variantiFiltrate.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nessuna variante corrisponde ai filtri selezionati',
                  ),
                ),
              )
            else
              ..._variantiFiltrate.map(_buildVarianteCard),

            const SizedBox(height: 16),

            // Dettagli variante selezionata
            if (_varianteSelezionata != null) ...[
              const Divider(),
              Text(
                'Dettagli variante selezionata:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _varianteSelezionata!.nomeVisualizzabile,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prezzo: €${_varianteSelezionata!.prezzo.toStringAsFixed(2)}',
                    ),
                    Text('Quantità: ${_varianteSelezionata!.quantita}'),
                    if (_varianteSelezionata!.sku.isNotEmpty)
                      Text('SKU: ${_varianteSelezionata!.sku}'),
                    if (_varianteSelezionata!.attributi.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Attributi:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      ..._varianteSelezionata!.attributi.map(
                        (attr) => Text('• ${attr.nome}: ${attr.opzione}'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
