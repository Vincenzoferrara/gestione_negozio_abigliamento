import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'cassa.code.dart';
import 'class_scontrino.dart';
import 'storico_cassa.code.dart';

/// Voce "Storico cassa" dentro il modulo Cassa.
///
/// Storico scontrini POS separato dagli ordini WooCommerce: mostra solo il
/// canale `pos`, con righe, pagamenti, operatore, cassa, totali, resi
/// collegati e riferimento all'ordine creato da MGWS. I resi partono sempre
/// da una riga venduta con controllo sul residuo rendibile.
class StoricoCassaPage extends StatefulWidget {
  final CassaController controller;
  final VoidCallback onVaiAllaVendita;

  const StoricoCassaPage({
    super.key,
    required this.controller,
    required this.onVaiAllaVendita,
  });

  @override
  State<StoricoCassaPage> createState() => _StoricoCassaPageState();
}

class _StoricoCassaPageState extends State<StoricoCassaPage> {
  final _searchController = TextEditingController();
  final _cassaFiltroController = TextEditingController();
  String? _metodoFiltro;
  bool _soloResi = false;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cassaFiltroController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.controller.storicoStore.init();
    if (mounted) setState(() => _loading = false);
  }

  List<Scontrino> get _filtrati {
    return widget.controller.storicoStore.filtra(
      queryCliente: _query,
      cassaNome: _cassaFiltroController.text.trim().isEmpty
          ? null
          : _cassaFiltroController.text.trim(),
      metodoPagamento: _metodoFiltro,
      soloResi: _soloResi ? true : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtrati = _filtrati;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca cliente, numero, ordine, id',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cassaFiltroController,
                      decoration: const InputDecoration(
                        labelText: 'Cassa (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _metodoFiltro,
                      decoration: const InputDecoration(
                        labelText: 'Metodo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tutti')),
                        DropdownMenuItem(
                          value: 'contanti',
                          child: Text('Contanti'),
                        ),
                        DropdownMenuItem(value: 'carta', child: Text('Carta')),
                        DropdownMenuItem(
                          value: 'bancomat',
                          child: Text('Bancomat'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _metodoFiltro = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Resi'),
                    selected: _soloResi,
                    onSelected: (v) => setState(() => _soloResi = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filtrati.length} scontrini POS (canale pos, separati dagli ordini Woo)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna'),
                  ),
                  TextButton.icon(
                    onPressed: () => _dialogChiusura(context),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('Chiusura'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtrati.isEmpty
              ? Center(
                  child: Text(
                    'Nessuno scontrino POS archiviato con questi filtri.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtrati.length,
                  itemBuilder: (context, i) =>
                      _cardScontrino(context, filtrati[i]),
                ),
        ),
      ],
    );
  }

  Widget _cardScontrino(BuildContext context, Scontrino s) {
    final theme = Theme.of(context);
    final custom = theme.extension<AppColorExtension>();
    final numero = s.numeroProgressivo != null
        ? '#${s.numeroProgressivo}'
        : '#${s.id.substring(0, s.id.length > 6 ? 6 : s.id.length)}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          s.hasResi ? Icons.assignment_return : Icons.receipt_long,
          color: s.totale < 0
              ? (custom?.errorColorStatus ?? Colors.red)
              : (custom?.successColor ?? Colors.green),
        ),
        title: Text(
          '$numero - €${s.totale.toStringAsFixed(2)} - ${s.metodoPagamento}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${s.data} · ${s.operatoreLabel}'
          '${s.cassaNome != null ? ' · ${s.cassaNome}' : ''}'
          '${s.wooOrderId != null ? ' · ordine ${s.wooOrderId}' : ''}'
          '${s.clienteNome != null ? ' · ${s.clienteNome}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _dialogDettaglio(context, s),
      ),
    );
  }

  Future<void> _dialogDettaglio(BuildContext context, Scontrino s) async {
    final theme = Theme.of(context);
    final rendibili = widget.controller.storicoStore.righeRendibili(s.id);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Scontrino ${s.numeroProgressivo != null ? '#${s.numeroProgressivo}' : s.id}',
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'POS · ${s.data} · ${s.metodoPagamento} · €${s.totale.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Operatore: ${s.operatoreLabel}'
                  '${s.cassaNome != null ? ' · Cassa ${s.cassaNome}' : ''}'
                  '${s.sede != null ? ' · ${s.sede}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (s.wooOrderId != null)
                  Text(
                    'Ordine Woo/MGWS collegato: ${s.wooOrderId} (solo riferimento, ciclo separato)',
                    style: theme.textTheme.bodySmall,
                  ),
                const Divider(),
                Text(
                  'Righe vendute e residuo rendibile',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (rendibili.isEmpty)
                  const Text('Nessuna riga vendita in questo scontrino.'),
                for (final r in rendibili)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${r.nome} - €${r.prezzoUnitario.toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      'Barcode interno ${r.barcodeInterno} · venduti ${r.quantitaVenduta} · '
                      'gia resi ${r.quantitaGiaResa} · '
                      'rendibili ${r.quantitaRendibile}',
                    ),
                    trailing: r.isEsaurita
                        ? const Chip(label: Text('Esaurita'))
                        : TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _dialogNuovoReso(context, s.id, r);
                            },
                            child: const Text('Reso'),
                          ),
                  ),
                const Divider(),
                Text(
                  'Righe registrate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final riga in s.righe)
                  Text(
                    '${riga.isReso ? '[RESO] ' : ''}${riga.nomeCompleto} x${riga.quantita} '
                    '- €${riga.subtotale.toStringAsFixed(2)}'
                    '${riga.motivoReso != null ? ' (${riga.motivoReso})' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _dialogNuovoReso(
    BuildContext context,
    String scontrinoId,
    RigaRendibile riga,
  ) async {
    final qtyController = TextEditingController(text: '1');
    final motivoController = TextEditingController();
    String esito = 'reintegro';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Reso vincolato - ${riga.nome}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rendibili: ${riga.quantitaRendibile} '
                  '(venduti ${riga.quantitaVenduta}, gia resi ${riga.quantitaGiaResa}). '
                  'Il prezzo resta quello pagato: €${riga.prezzoUnitario.toStringAsFixed(2)}.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantita da rendere',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo reso (obbligatorio)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: esito,
                  decoration: const InputDecoration(
                    labelText: 'Esito merce',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'reintegro',
                      child: Text('Reintegro in magazzino'),
                    ),
                    DropdownMenuItem(
                      value: 'difettoso',
                      child: Text('Difettoso / non vendibile'),
                    ),
                    DropdownMenuItem(
                      value: 'buono',
                      child: Text('Buono / credito cliente'),
                    ),
                    DropdownMenuItem(
                      value: 'sostituzione',
                      child: Text('Sostituzione'),
                    ),
                    DropdownMenuItem(
                      value: 'rimborso',
                      child: Text('Rimborso'),
                    ),
                  ],
                  onChanged: (v) => setState(() => esito = v ?? 'reintegro'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Prepara reso'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    final errore = await widget.controller.preparaResoVincolato(
      scontrinoOrigineId: scontrinoId,
      chiaveRiga: riga.chiaveRiga,
      quantita: qty,
      motivo: motivoController.text,
      esitoMerce: esito,
    );
    if (!context.mounted) return;
    if (errore != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errore)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reso preparato nel carrello: completa il checkout per registrarlo.',
        ),
      ),
    );
    widget.onVaiAllaVendita();
  }

  Future<void> _dialogChiusura(BuildContext context) async {
    final store = widget.controller.storicoStore;
    await store.init();
    final turno = widget.controller.turnoCorrente;
    if (!context.mounted) return;
    if (turno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun turno aperto da chiudere.')),
      );
      return;
    }
    final totali = store.totaliGiornata(turno.giornataId, turnoId: turno.id);
    final esistente = store.cercaChiusuraTurno(turno.id);
    if (esistente != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Turno gia chiuso'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Giornata: ${esistente.giornataId}'),
                if (esistente.turnoId != null)
                  Text('Turno: ${esistente.turnoId}'),
                Text(
                  'Contante atteso €${esistente.contanteAtteso.toStringAsFixed(2)} · '
                  'contato €${esistente.contanteContato.toStringAsFixed(2)} · '
                  'differenza €${esistente.differenzaContanti.toStringAsFixed(2)}',
                ),
                Text(
                  'Carta attesa €${esistente.cartaAttesa.toStringAsFixed(2)} · '
                  'contattata €${esistente.cartaContato.toStringAsFixed(2)} · '
                  'differenza €${esistente.differenzaCarta.toStringAsFixed(2)}',
                ),
                if ((esistente.causaleDifferenza ?? '').isNotEmpty)
                  Text('Causale: ${esistente.causaleDifferenza}'),
                if ((esistente.note ?? '').isNotEmpty)
                  Text('Note: ${esistente.note}'),
                for (final r in esistente.rettifiche) Text('- $r'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
            TextButton(
              onPressed: () async {
                final notaController = TextEditingController();
                final nota = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Nota di rettifica'),
                    content: TextField(
                      controller: notaController,
                      decoration: const InputDecoration(
                        labelText: 'Rettifica (non modifica la chiusura)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, notaController.text),
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                );
                if (nota != null && nota.trim().isNotEmpty) {
                  await store.aggiungiRettifica(esistente.id, nota.trim());
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Aggiungi rettifica'),
            ),
          ],
        ),
      );
      return;
    }

    final contantiController = TextEditingController();
    final cartaController = TextEditingController();
    final causaleController = TextEditingController();
    final noteController = TextEditingController();
    final registrata = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chiusura turno ${turno.id}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incassi turno - contanti €${(totali['contanti'] ?? 0).toStringAsFixed(2)} · '
                  'carta €${(totali['carta'] ?? 0).toStringAsFixed(2)} · '
                  'altri €${(totali['altri'] ?? 0).toStringAsFixed(2)} · '
                  'rimborsi €${(totali['rimborsi'] ?? 0).toStringAsFixed(2)}',
                ),
                Text(
                  'Turno: ${turno.id} · Operatore: ${turno.operatoreLabel} · '
                  'Fondo iniziale €${turno.fondoIniziale.toStringAsFixed(2)}.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contantiController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Contanti contati',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cartaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Carta/POS contato',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: causaleController,
                  decoration: const InputDecoration(
                    labelText: 'Causale differenza (obbligatoria se diversa)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Registra chiusura'),
          ),
        ],
      ),
    );
    if (registrata != true || !context.mounted) return;
    double parse(String v) =>
        double.tryParse(v.replaceAll(',', '.').trim()) ?? 0;
    final esito = await widget.controller.chiudiTurno(
      contanteContato: parse(contantiController.text),
      cartaContato: parse(cartaController.text),
      causaleDifferenza: causaleController.text.trim().isEmpty
          ? null
          : causaleController.text.trim(),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );
    if (!context.mounted) return;
    final chiusura = store.cercaChiusuraTurno(turno.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esito.ok
              ? 'Chiusura registrata. Differenza contanti €${(chiusura?.differenzaContanti ?? 0).toStringAsFixed(2)}, carta €${(chiusura?.differenzaCarta ?? 0).toStringAsFixed(2)}.'
              : (esito.errore ?? 'Chiusura non registrata.'),
        ),
      ),
    );
  }
}
