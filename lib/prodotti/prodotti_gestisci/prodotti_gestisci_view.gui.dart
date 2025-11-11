import 'package:flutter/material.dart';
import '../class_prodotti.dart';
import 'prodotti_gestisci.code.dart';

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
  final ProdottiGestisciModel? controller;

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
  late VarianteProductGlobal? _varianteSelezionata;
  Map<String, String> _filtriAttivi = {};
  List<VarianteProductGlobal> _variantiFiltrate = [];

  @override
  void initState() {
    super.initState();
    _varianteSelezionata = widget.varianteSelezionata;
    _applicaFiltri();
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

  /// Estrae tutti i valori unici per ogni attributo dal prodotto
  Map<String, List<String>> _getOpzioniFiltro() {
    final opzioni = <String, Set<String>>{};
    
    for (final variante in widget.prodotto.varianti ?? []) {
      for (final attributo in variante.attributi) {
        opzioni[attributo.nome] ??= {};
        opzioni[attributo.nome]!.add(attributo.opzione);
      }
    }
    
    return opzioni.map((key, value) => MapEntry(key, value.toList()));
  }

  void _setFiltro(String nomeAttributo, String valore) {
    setState(() {
      if (_filtriAttivi[nomeAttributo] == valore) {
        _filtriAttivi.remove(nomeAttributo);
      } else {
        _filtriAttivi[nomeAttributo] = valore;
      }
      _applicaFiltri();
    });
  }

  void _cancellaFiltri() {
    setState(() {
      _filtriAttivi.clear();
      _applicaFiltri();
    });
  }

  void _applicaFiltri() {
    final tutteVarianti = widget.prodotto.varianti ?? [];
    
    if (_filtriAttivi.isEmpty) {
      _variantiFiltrate = tutteVarianti;
    } else {
      _variantiFiltrate = tutteVarianti.where((variante) {
        // Verifica che la variante soddisfi tutti i filtri attivi
        for (final entry in _filtriAttivi.entries) {
          final nomeAttributo = entry.key;
          final valoreDesiderato = entry.value;
          
          final haAttributoCorretto = variante.attributi.any((attributo) =>
              attributo.nome == nomeAttributo && attributo.opzione == valoreDesiderato);
          
          if (!haAttributoCorretto) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Auto-seleziona la prima variante disponibile se nessuna è selezionata
    // o se la variante selezionata non è più tra quelle filtrate
    if (_varianteSelezionata == null || 
        !_variantiFiltrate.any((v) => v.id == _varianteSelezionata?.id)) {
      if (_variantiFiltrate.isNotEmpty) {
        _varianteSelezionata = _variantiFiltrate.first;
        // Notifica il parent della nuova selezione
        widget.onVarianteSelezionata?.call(_varianteSelezionata);
      } else {
        _varianteSelezionata = null;
        widget.onVarianteSelezionata?.call(null);
      }
    }
  }

  Widget _buildFiltri() {
    final opzioniFiltro = _getOpzioniFiltro();
    
    if (opzioniFiltro.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Filtra varianti:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opzioniFiltro.entries.map((entry) {
            final nomeAttributo = entry.key;
            final valori = entry.value;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nomeAttributo:',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: valori.map((valore) {
                    final isSelected = _filtriAttivi[nomeAttributo] == valore;
                    return FilterChip(
                      label: Text(
                        valore,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        _setFiltro(nomeAttributo, valore);
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
        if (_filtriAttivi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _cancellaFiltri,
              child: const Text('Cancella filtri'),
            ),
          ),
      ],
    );
  }

  Widget _buildVarianteCard(VarianteProductGlobal variante) {
    final isSelected = _varianteSelezionata?.id == variante.id;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: variante.quantita > 0 
              ? Colors.green 
              : Colors.red,
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
          'Prezzo: €${variante.prezzoEffettivo.toStringAsFixed(2)} | Qty: ${variante.quantita}',
        ),
        trailing: variante.attributi.isNotEmpty
            ? Wrap(
                children: variante.attributi.map((attr) => Chip(
                  label: Text(
                    '${attr.nome}: ${attr.opzione}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              )
            : null,
        onTap: () => _selezionaVariante(variante),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showCloseButton ? AppBar(
        title: Text(widget.prodotto.nome ?? 'Prodotto'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ) : null,
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
              widget.prodotto.nome ?? 'Prodotto',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            if (widget.prodotto.descrizioneBreve?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                widget.prodotto.descrizioneBreve!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Filtri varianti
            _buildFiltri(),
            
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
                  child: Text('Nessuna variante corrisponde ai filtri selezionati'),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                    Text('Prezzo: €${_varianteSelezionata!.prezzoEffettivo.toStringAsFixed(2)}'),
                    Text('Quantità: ${_varianteSelezionata!.quantita}'),
                    if (_varianteSelezionata!.sku.isNotEmpty)
                      Text('SKU: ${_varianteSelezionata!.sku}'),
                    if (_varianteSelezionata!.attributi.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Attributi:', style: TextStyle(fontWeight: FontWeight.w500)),
                      ..._varianteSelezionata!.attributi.map((attr) => 
                        Text('• ${attr.nome}: ${attr.opzione}')),
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