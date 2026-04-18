import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';
import 'clienti_gestisci.code.dart';

/// Pagina principale per la gestione dei clienti
class ClientiGestisciPage extends StatefulWidget {
  const ClientiGestisciPage({super.key});

  @override
  ClientiGestisciPageState createState() => ClientiGestisciPageState();
}

class ClientiGestisciPageState extends State<ClientiGestisciPage> with AutomaticKeepAliveClientMixin {
  final ClientiGestioneController _controller = ClientiGestioneController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _caricaClienti();
  }

  Future<void> _caricaClienti() async {
    await _controller.caricaClienti();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario per AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 800;
          if (isSmallScreen) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _FiltriWidget(
          controller: _controller,
          onStateChanged: _updateState,
          onRefresh: _caricaClienti,
        ),
        Expanded(child: _buildListaClienti()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _FiltriWidget(
                controller: _controller,
                onStateChanged: _updateState,
                onRefresh: _caricaClienti,
              ),
              Expanded(child: _buildListaClienti()),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 2,
          child: _controller.hasClienteSelezionato
              ? _ClienteDettagli(cliente: _controller.clienteSelezionato!)
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un cliente',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaClienti() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_controller.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _caricaClienti,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_controller.clienti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun cliente trovato',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _controller.clienti.length,
      itemBuilder: (context, index) {
        final cliente = _controller.clienti[index];
        final isSelected = _controller.isClienteSelezionato(cliente);

        return _ClienteListItem(
          cliente: cliente,
          isSelected: isSelected,
          onTap: () {
            _controller.selezionaCliente(cliente);
            _updateState();
          },
        );
      },
    );
  }
}

/// Widget per i filtri e la ricerca
class _FiltriWidget extends StatefulWidget {
  final ClientiGestioneController controller;
  final VoidCallback onStateChanged;
  final VoidCallback onRefresh;

  const _FiltriWidget({
    required this.controller,
    required this.onStateChanged,
    required this.onRefresh,
  });

  @override
  _FiltriWidgetState createState() => _FiltriWidgetState();
}

class _FiltriWidgetState extends State<_FiltriWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca per nome, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.controller.setSearchQuery('');
                          widget.onStateChanged();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                widget.controller.setSearchQuery(value);
                widget.onStateChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per ogni elemento della lista clienti
class _ClienteListItem extends StatelessWidget {
  final dynamic cliente;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClienteListItem({
    required this.cliente,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final dataRegistrazione = cliente.dateCreated != null
        ? dateFormat.format(cliente.dateCreated!)
        : 'N/D';

    final nomeCompleto = '${cliente.firstName ?? ''} ${cliente.lastName ?? ''}'.trim();
    final displayName = nomeCompleto.isNotEmpty ? nomeCompleto : cliente.username ?? 'N/D';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? theme.primaryColor.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? customColors.selectedCardBackground : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.primaryColor : null,
                          ),
                        ),
                        Text(
                          cliente.email ?? 'N/D',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: customColors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Registrato: $dataRegistrazione', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  if (cliente.isPayingCustomer == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: customColors.successColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cliente pagante',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget per visualizzare i dettagli di un cliente
class _ClienteDettagli extends StatelessWidget {
  final dynamic cliente;

  const _ClienteDettagli({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final nomeCompleto = '${cliente.firstName ?? ''} ${cliente.lastName ?? ''}'.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              nomeCompleto.isNotEmpty ? nomeCompleto : cliente.username ?? 'N/D',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              cliente.email ?? 'N/D',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
          const Divider(height: 32),

          // Informazioni personali
          _buildSezione(
            context,
            'Informazioni Personali',
            Icons.person,
            [
              _buildInfoRow('Username', cliente.username ?? 'N/D'),
              _buildInfoRow('Nome', cliente.firstName ?? 'N/D'),
              _buildInfoRow('Cognome', cliente.lastName ?? 'N/D'),
              _buildInfoRow('Email', cliente.email ?? 'N/D'),
              _buildInfoRow('Ruolo', cliente.role ?? 'N/D'),
              _buildInfoRow(
                'Cliente pagante',
                cliente.isPayingCustomer == true ? 'Sì' : 'No',
              ),
              _buildInfoRow(
                'Registrato',
                cliente.dateCreated != null
                    ? dateFormat.format(cliente.dateCreated!)
                    : 'N/D',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Indirizzo di fatturazione
          if (cliente.billing != null)
            _buildSezione(
              context,
              'Indirizzo Fatturazione',
              Icons.receipt,
              [
                _buildInfoRow('Nome', '${cliente.billing?.firstName ?? ''} ${cliente.billing?.lastName ?? ''}'.trim()),
                _buildInfoRow('Azienda', cliente.billing?.company ?? 'N/D'),
                _buildInfoRow('Indirizzo', cliente.billing?.address1 ?? 'N/D'),
                if (cliente.billing?.address2?.isNotEmpty ?? false)
                  _buildInfoRow('Indirizzo 2', cliente.billing?.address2 ?? ''),
                _buildInfoRow('Città', cliente.billing?.city ?? 'N/D'),
                _buildInfoRow('CAP', cliente.billing?.postcode ?? 'N/D'),
                _buildInfoRow('Provincia', cliente.billing?.state ?? 'N/D'),
                _buildInfoRow('Paese', cliente.billing?.country ?? 'N/D'),
                _buildInfoRow('Telefono', cliente.billing?.phone ?? 'N/D'),
                _buildInfoRow('Email', cliente.billing?.email ?? 'N/D'),
              ],
            ),
          const SizedBox(height: 16),

          // Indirizzo di spedizione
          if (cliente.shipping != null)
            _buildSezione(
              context,
              'Indirizzo Spedizione',
              Icons.local_shipping,
              [
                _buildInfoRow('Nome', '${cliente.shipping?.firstName ?? ''} ${cliente.shipping?.lastName ?? ''}'.trim()),
                _buildInfoRow('Azienda', cliente.shipping?.company ?? 'N/D'),
                _buildInfoRow('Indirizzo', cliente.shipping?.address1 ?? 'N/D'),
                if (cliente.shipping?.address2?.isNotEmpty ?? false)
                  _buildInfoRow('Indirizzo 2', cliente.shipping?.address2 ?? ''),
                _buildInfoRow('Città', cliente.shipping?.city ?? 'N/D'),
                _buildInfoRow('CAP', cliente.shipping?.postcode ?? 'N/D'),
                _buildInfoRow('Provincia', cliente.shipping?.state ?? 'N/D'),
                _buildInfoRow('Paese', cliente.shipping?.country ?? 'N/D'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSezione(BuildContext context, String titolo, IconData icona, List<Widget> contenuto) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icona, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  titolo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...contenuto,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
