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
    if (_varianteSelezionata == null && _variantiFiltrate.isNotEmpty) {
      _varianteSelezionata = _variantiFiltrate.first;
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () => _selezionaVariante(variante),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con immagine e info base
              Row(
                children: [
                  // Immagine variante
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: variante.immagineUrl != null && variante.immagineUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              variante.immagineUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image, color: Colors.grey);
                              },
                            ),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info base
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variante.nomeVisualizzabile,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${variante.prezzoEffettivo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Stock indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: variante.quantita > 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          variante.quantita > 0 ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          variante.quantita.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Attributi
              if (variante.attributi.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: variante.attributi.map((attributo) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${attributo.nome}: ${attributo.opzione}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // SKU e altre info
              if (variante.sku.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'SKU: ${variante.sku}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
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
            
            if (widget.prodotto.descrizioneBreve?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                widget.prodotto.descrizioneBreve!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Filtri
            _buildFiltri(),
            
            const SizedBox(height: 16),
            
            // Header varianti
            Row(
              children: [
                Text(
                  'Varianti (${_variantiFiltrate.length}):',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_filtriAttivi.isNotEmpty)
                  Chip(
                    label: Text('${_filtriAttivi.length} filtri attivi'),
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    deleteIcon: const Icon(Icons.clear, size: 18),
                    onDeleted: _cancellaFiltri,
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Lista varianti filtrate
            if (_variantiFiltrate.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna variante corrisponde ai filtri selezionati',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cancellaFiltri,
                      child: const Text('Cancella filtri'),
                    ),
                  ],
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
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _varianteSelezionata!.nomeVisualizzabile,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '€${_varianteSelezionata!.prezzoEffettivo.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('Quantità: ${_varianteSelezionata!.quantita}'),
                        const Spacer(),
                        Icon(_varianteSelezionata!.quantita > 0 ? Icons.check_circle : Icons.cancel, 
                             size: 16, 
                             color: _varianteSelezionata!.quantita > 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(_varianteSelezionata!.quantita > 0 ? 'Disponibile' : 'Esaurito'),
                      ],
                    ),
                    if (_varianteSelezionata!.sku.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.qr_code, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('SKU: ${_varianteSelezionata!.sku}'),
                        ],
                      ),
                    ],
                    if (_varianteSelezionata!.attributi.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Attributi:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _varianteSelezionata!.attributi.map((attr) => 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${attr.nome}: ${attr.opzione}'),
                          ),
                        ).toList(),
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