import 'package:flutter/material.dart';
import 'utenti.code.dart';
import 'class_user_global.dart';

/// Pagina principale per la gestione degli utenti
class UtentiPage extends StatefulWidget {
  const UtentiPage({super.key});

  @override
  UtentiGestisciPageState createState() => UtentiGestisciPageState();
}

class UtentiGestisciPageState extends State<UtentiPage> {
  final UtentiGestioneController _controller = UtentiGestioneController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _capabilitiesSearchController =
      TextEditingController();
  final TextEditingController _roleFilterController = TextEditingController();
  DateTime? _dateFilter;
  List<dynamic> utentiFiltrati = [];
  dynamic utenteSelezionato;
  Map<String, bool> _capabilitiesModificate =
      {}; // Traccia modifiche capabilities

  @override
  void initState() {
    super.initState();
    _caricaUtenti();
    _searchController.addListener(_filtraUtenti);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _caricaUtenti() async {
    await _controller.caricaUtenti();
    if (mounted) {
      setState(() {
        utentiFiltrati = _controller.utenti;
      });
    }
  }

  void _filtraUtenti() {
    final query = _searchController.text.toLowerCase();
    final roleQuery = _roleFilterController.text.toLowerCase();
    setState(() {
      utentiFiltrati = _controller.utenti.where((utente) {
        if (utente is! Map<String, dynamic>) return false;

        // Filtro ricerca globale
        final matchesSearch =
            query.isEmpty ||
            (utente['name']?.toString().toLowerCase() ?? '').contains(query) ||
            (utente['email']?.toString().toLowerCase() ?? '').contains(query) ||
            (utente['username']?.toString().toLowerCase() ?? '').contains(
              query,
            );

        // Filtro ruolo
        final userRoles = utente['roles'] as List<dynamic>?;
        final matchesRole =
            roleQuery.isEmpty ||
            (userRoles?.any(
                  (role) => role.toString().toLowerCase().contains(roleQuery),
                ) ??
                false);

        // Filtro data (se selezionata, utenti registrati dopo quella data)
        final matchesDate =
            _dateFilter == null ||
            (utente['registered_date'] != null &&
                DateTime.tryParse(
                      utente['registered_date'],
                    )?.isAfter(_dateFilter!) ==
                    true);

        // Escludi clienti
        final roles = utente['roles'] as List<dynamic>?;
        final notCustomer = roles == null || !roles.contains('customer');

        return matchesSearch && matchesRole && matchesDate && notCustomer;
      }).toList();
    });
  }

  void _selezionaUtente(dynamic utente) {
    setState(() {
      utenteSelezionato = utente;
      _capabilitiesModificate.clear(); // Reset modifiche
    });
  }

  void _salvaModifiche(dynamic utente) {
    // TODO: Implementa salvataggio capabilities via API
    print(
      'Salvataggio modifiche per utente ${utente['id']}: $_capabilitiesModificate',
    );
    // Chiama API per aggiornare capabilities
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Utenti'), elevation: 2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildListaUtenti()),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 1,
                  child: utenteSelezionato != null
                      ? _buildDettagliUtente(utenteSelezionato!)
                      : _buildEmptyState(),
                ),
              ],
            );
          } else {
            return Column(children: [_buildListaUtenti()]);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        tooltip: 'Aggiungi Utente',
      ),
    );
  }

  Widget _buildListaUtenti() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cerca per nome o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),
        Expanded(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : utentiFiltrati.isEmpty
              ? const Center(child: Text('Nessun utente trovato'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: utentiFiltrati.length,
                  itemBuilder: (context, index) {
                    final utente = utentiFiltrati[index];
                    final isSelected = utente == utenteSelezionato;
                    return _UtenteCard(
                      utente: utente,
                      isSelected: isSelected,
                      onTap: () => _selezionaUtente(utente),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDettagliUtente(dynamic utente) {
    if (utente is! Map<String, dynamic>) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Errore: Dati utente non validi',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = utente['name'] ?? 'N/D';
    final email = utente['email'] ?? 'N/D';
    final roles = utente['roles'] is List
        ? (utente['roles'] as List).join(', ')
        : 'N/D';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header con avatar e info base
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ruoli: $roles',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                  ),
                ),
                SizedBox(height: 20),
                // Pulsante salva
                ElevatedButton.icon(
                  onPressed: _controller.isSaving
                      ? null
                      : () => _salvaModifiche(utente),
                  icon: _controller.isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.save),
                  label: Text(
                    _controller.isSaving ? 'Salvando...' : 'Salva Modifiche',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Sezioni espandibili
                Expanded(
                  child: ListView(
                    children: [
                      _buildExpandableSection(
                        title: 'Informazioni Base',
                        icon: Icons.info,
                        children: [
                          _buildInfoRowWithIcon(
                            Icons.person,
                            'ID',
                            utente['id']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.account_circle,
                            'Username',
                            utente['username']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.badge,
                            'First Name',
                            utente['first_name']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.badge,
                            'Last Name',
                            utente['last_name']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.face,
                            'Nickname',
                            utente['nickname']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.link,
                            'URL',
                            utente['url']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.description,
                            'Description',
                            utente['description']?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.calendar_today,
                            'Registered Date',
                            utente['registered_date']?.toString() ?? 'N/D',
                          ),
                        ],
                      ),
                      _buildCapabilitiesSectionEditable(
                        utente,
                        true,
                      ), // Assume admin
                      _buildMetaSection(utente),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue.shade600),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        children: children,
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSectionEditable(dynamic utente, bool isAdmin) {
    if (utente is! Map<String, dynamic>) return SizedBox.shrink();
    final capabilitiesRaw = utente['capabilities'];
    if (capabilitiesRaw is! Map<String, dynamic>) return SizedBox.shrink();
    final capabilities = capabilitiesRaw as Map<String, dynamic>;

    // Filtro per ricerca
    final searchQuery = _capabilitiesSearchController.text.toLowerCase();
    final filteredCapabilities = capabilities.entries
        .where((entry) => entry.key.toLowerCase().contains(searchQuery))
        .toList();

    // Raggruppa capabilities filtrate per sezione
    final inventario = <MapEntry<String, dynamic>>[];
    final woocommerce = <MapEntry<String, dynamic>>[];
    final wordpress = <MapEntry<String, dynamic>>[];

    for (final entry in filteredCapabilities) {
      final key = entry.key.toLowerCase();
      if (key.contains('atum')) {
        inventario.add(entry);
      } else if (key.contains('prodotto') ||
          key.contains('woocommerce') ||
          key.contains('shop')) {
        woocommerce.add(entry);
      } else {
        wordpress.add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _capabilitiesSearchController,
            decoration: InputDecoration(
              hintText: 'Cerca capabilities...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) => setState(() {}), // Ricarica la UI
          ),
        ),
        if (inventario.isNotEmpty)
          _buildCapabilitySection('Inventario', inventario, isAdmin),
        if (woocommerce.isNotEmpty)
          _buildCapabilitySection('WooCommerce', woocommerce, isAdmin),
        if (wordpress.isNotEmpty)
          _buildCapabilitySection('WordPress', wordpress, isAdmin),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCapabilitySection(
    String title,
    List<MapEntry<String, dynamic>> entries,
    bool isAdmin,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  if (isAdmin)
                    Switch(
                      value:
                          _capabilitiesModificate[entry.key] ??
                          (entry.value == true),
                      onChanged: (value) async {
                        // Controllo conferma per super admin
                        if (entry.key.toLowerCase().contains('super') &&
                            value) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Conferma'),
                              content: Text(
                                'Sei sicuro di voler rendere questo utente Super Admin?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('Annulla'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text('Conferma'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }

                        setState(() {
                          _capabilitiesModificate[entry.key] = value;
                        });
                      },
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCapabilitiesSection(dynamic utente) {
    if (utente is! Map<String, dynamic>) return SizedBox.shrink();
    final capabilitiesRaw = utente['capabilities'];
    if (capabilitiesRaw is! List<dynamic> || capabilitiesRaw.isEmpty)
      return SizedBox.shrink();
    final capabilities = capabilitiesRaw as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...capabilities.map(
          (cap) => Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Text('• $cap'),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMetaSection(dynamic utente) {
    if (utente is! Map<String, dynamic>) return SizedBox.shrink();
    final metaRaw = utente['meta'];
    if (metaRaw is! Map<String, dynamic> || metaRaw.isEmpty)
      return SizedBox.shrink();
    final meta = metaRaw as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meta Dati:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...meta.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Text('${entry.key}: ${entry.value}'),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Seleziona un utente'),
        ],
      ),
    );
  }
}

class _UtenteCard extends StatelessWidget {
  final dynamic utente;
  final bool isSelected;
  final VoidCallback onTap;

  const _UtenteCard({
    required this.utente,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (utente is Map<String, dynamic> ? utente['name'] ?? 'N' : 'N')
                      .toString()
                      .split(' ')
                      .map((e) => e[0])
                      .join('')
                      .toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      utente is Map<String, dynamic>
                          ? utente['name'] ?? 'N/D'
                          : 'N/D',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    Text(
                      utente is Map<String, dynamic>
                          ? utente['email'] ?? 'N/D'
                          : 'N/D',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'ID: ${utente is Map<String, dynamic> ? utente['id'] ?? 'N/D' : 'N/D'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
