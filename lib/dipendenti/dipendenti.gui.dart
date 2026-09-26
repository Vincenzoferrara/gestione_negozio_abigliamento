import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dipendenti.code.dart'; // Import the code file for logic
import '../login/jwt_api/query_wordpress/query_user_wordpress.dart';

class DipendentiGui extends StatefulWidget {
  const DipendentiGui({super.key});

  @override
  _DipendentiGuiState createState() => _DipendentiGuiState();
}

class _DipendentiGuiState extends State<DipendentiGui> {
  final DipendentiService _service = DipendentiService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.loadDipendenti();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Dipendenti'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDipendente,
        tooltip: 'Aggiungi Dipendente',
        child: const Icon(Icons.add),
      ),
      body: ChangeNotifierProvider.value(
        value: _service,
        child: Consumer<DipendentiService>(
          builder: (context, service, child) {
            if (service.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                if (service.errore != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MaterialBanner(
                      content: Text(service.errore!),
                      leading: const Icon(Icons.warning_amber),
                      actions: [
                        TextButton(
                          onPressed: service.loadDipendenti,
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca dipendenti...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: service.dipendenti
                        .where(
                          (d) =>
                              '${d.nome} ${d.cognome}'.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              d.email.toLowerCase().contains(_searchQuery) ||
                              d.ruolo.toLowerCase().contains(_searchQuery),
                        )
                        .toList()
                        .length,
                    itemBuilder: (context, index) {
                      final filteredDipendenti = service.dipendenti
                          .where(
                            (d) =>
                                '${d.nome} ${d.cognome}'.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                d.email.toLowerCase().contains(_searchQuery) ||
                                d.ruolo.toLowerCase().contains(_searchQuery),
                          )
                          .toList();
                      final dipendente = filteredDipendenti[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(51),
                                child: Text(
                                  '${dipendente.nome.isNotEmpty ? dipendente.nome[0] : '?'}${dipendente.cognome.isNotEmpty ? dipendente.cognome[0] : '?'}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dipendente.nome} ${dipendente.cognome}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ruolo: ${dipendente.ruolo}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'Email: ${dipendente.email}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'Stipendio: €${dipendente.stipendio.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    if (dipendente.venditeTotali != null)
                                      Text(
                                        'Vendite Totali: €${dipendente.venditeTotali!.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    if (dipendente.produzioneTotale != null)
                                      Text(
                                        'Produzione Totale: ${dipendente.produzioneTotale} unità',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _viewDipendenteDetails(dipendente),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _editDipendente(dipendente),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteDipendente(dipendente.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addDipendente() {
    // Navigate to add/edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DipendenteFormScreen(isEdit: false, service: _service),
      ),
    ).then((_) => _service.loadDipendenti());
  }

  void _viewDipendenteDetails(Dipendente dipendente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DipendenteDetailScreen(dipendente: dipendente),
      ),
    );
  }

  void _editDipendente(Dipendente dipendente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DipendenteFormScreen(
          isEdit: true,
          dipendente: dipendente,
          service: _service,
        ),
      ),
    ).then((_) => _service.loadDipendenti());
  }

  void _deleteDipendente(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Vuoi eliminare questo dipendente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _service.deleteDipendente(id);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class DipendenteFormScreen extends StatefulWidget {
  final bool isEdit;
  final Dipendente? dipendente;
  final DipendentiService service;

  const DipendenteFormScreen({
    super.key,
    required this.isEdit,
    required this.service,
    this.dipendente,
  });

  @override
  _DipendenteFormScreenState createState() => _DipendenteFormScreenState();
}

class _DipendenteFormScreenState extends State<DipendenteFormScreen> {
  static final NumberFormat _salaryFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '',
    decimalDigits: 2,
  );

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _wpUserIdController = TextEditingController();
  final _ruoloController = TextEditingController();
  final _stipendioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.dipendente != null) {
      _nomeController.text = widget.dipendente!.nome;
      _cognomeController.text = widget.dipendente!.cognome;
      _emailController.text = widget.dipendente!.email;
      if (widget.dipendente!.wpUserId > 0) {
        _wpUserIdController.text = widget.dipendente!.wpUserId.toString();
      }
      _ruoloController.text = widget.dipendente!.ruolo;
      _stipendioController.text = _salaryFormat.format(
        widget.dipendente!.stipendio,
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _wpUserIdController.dispose();
    _ruoloController.dispose();
    _stipendioController.dispose();
    super.dispose();
  }

  double? _parseStipendio(String input) {
    var value = input.trim().replaceAll('€', '').replaceAll(' ', '');
    if (value.isEmpty) return null;

    final hasComma = value.contains(',');
    final hasDot = value.contains('.');
    if (hasComma && hasDot) {
      final comma = value.lastIndexOf(',');
      final dot = value.lastIndexOf('.');
      if (comma > dot) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (hasComma) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasDot && '.'.allMatches(value).length > 1) {
      value = value.replaceAll('.', '');
    }

    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  String? _validateStipendio(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci stipendio';
    if (_parseStipendio(value) == null) {
      return 'Inserisci un importo valido (es. 1500,00)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Modifica Dipendente' : 'Aggiungi Dipendente',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Inserisci nome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cognomeController,
                        decoration: InputDecoration(
                          labelText: 'Cognome',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Inserisci cognome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            !value!.contains('@') ? 'Email non valida' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _wpUserIdController,
                        decoration: InputDecoration(
                          labelText: 'ID utente WordPress (opzionale)',
                          helperText:
                              'Collega il dipendente a un account WordPress per gestire ruoli e capability.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.account_circle),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return null;
                          final parsed = int.tryParse(trimmed);
                          if (parsed == null || parsed <= 0) {
                            return 'Inserisci un ID utente WordPress valido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ruoloController,
                        decoration: InputDecoration(
                          labelText: 'Ruolo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.work),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Inserisci ruolo' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stipendioController,
                        decoration: InputDecoration(
                          labelText: 'Stipendio (€)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.euro),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateStipendio,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDipendente,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.isEdit ? 'Salva Modifiche' : 'Aggiungi Dipendente',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDipendente() async {
    if (_formKey.currentState!.validate()) {
      final stipendio = _parseStipendio(_stipendioController.text)!;
      final wpUserId = int.tryParse(_wpUserIdController.text.trim()) ?? 0;
      final dipendente = Dipendente(
        id: widget.isEdit ? widget.dipendente!.id : 0,
        wpUserId: wpUserId,
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        email: _emailController.text,
        ruolo: _ruoloController.text,
        stipendio: stipendio,
        // Per ora non aggiungiamo i nuovi campi nella form, solo nel modello
      );
      final ok = widget.isEdit
          ? await widget.service.updateDipendente(dipendente)
          : await widget.service.addDipendente(dipendente);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service.errore ?? 'Operazione dipendente non riuscita',
            ),
          ),
        );
        return;
      }
      Navigator.pop(context);
    }
  }
}

class DipendenteDetailScreen extends StatelessWidget {
  final Dipendente dipendente;

  const DipendenteDetailScreen({super.key, required this.dipendente});

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${dipendente.nome} ${dipendente.cognome}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informazioni personali
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(51),
                          child: Text(
                            '${dipendente.nome.isNotEmpty ? dipendente.nome[0] : '?'}${dipendente.cognome.isNotEmpty ? dipendente.cognome[0] : '?'}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dipendente.nome} ${dipendente.cognome}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dipendente.ruolo,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.email,
                      'Email',
                      dipendente.email,
                    ),
                    _buildInfoRow(
                      context,
                      Icons.account_circle,
                      'Utente WordPress',
                      dipendente.wpUserId > 0
                          ? '#${dipendente.wpUserId}'
                          : 'Non collegato',
                    ),
                    _buildInfoRow(
                      context,
                      Icons.phone,
                      'Telefono',
                      'N/A',
                    ), // Placeholder
                    if (dipendente.dataNascita != null)
                      _buildInfoRow(
                        context,
                        Icons.cake,
                        'Data di nascita',
                        '${dipendente.dataNascita!.day}/${dipendente.dataNascita!.month}/${dipendente.dataNascita!.year}',
                      ),
                    if (dipendente.dataAssunzione != null)
                      _buildInfoRow(
                        context,
                        Icons.work,
                        'Data assunzione',
                        '${dipendente.dataAssunzione!.day}/${dipendente.dataAssunzione!.month}/${dipendente.dataAssunzione!.year}',
                      ),
                    if (dipendente.tipoContratto != null)
                      _buildInfoRow(
                        context,
                        Icons.description,
                        'Tipo contratto',
                        dipendente.tipoContratto!,
                      ),
                    if (dipendente.orarioLavoro != null)
                      _buildInfoRow(
                        context,
                        Icons.schedule,
                        'Orario lavoro',
                        dipendente.orarioLavoro!,
                      ),
                    _buildInfoRow(
                      context,
                      Icons.euro,
                      'Stipendio',
                      '€${dipendente.stipendio.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DipendenteAccessoPermessiCard(dipendente: dipendente),
            const SizedBox(height: 16),
            // Performance
            if (dipendente.venditeTotali != null ||
                dipendente.produzioneTotale != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (dipendente.venditeTotali != null)
                        _buildInfoRow(
                          context,
                          Icons.trending_up,
                          'Vendite Totali',
                          '€${dipendente.venditeTotali!.toStringAsFixed(2)}',
                        ),
                      if (dipendente.produzioneTotale != null)
                        _buildInfoRow(
                          context,
                          Icons.factory,
                          'Produzione Totale',
                          '${dipendente.produzioneTotale} unità',
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Ferie e malattie
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ferie e Malattie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Ferie Disponibili',
                            dipendente.giorniFerieDisponibili.toString(),
                            Colors.green,
                            Icons.beach_access,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Ferie Usate',
                            dipendente.giorniFerieUsati.toString(),
                            Colors.blue,
                            Icons.calendar_today,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Giorni Malattia',
                      dipendente.giorniMalattia.toString(),
                      Colors.red,
                      Icons.sick,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Benefici
            if (dipendente.benefici != null && dipendente.benefici!.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Benefici',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dipendente.benefici!.map(
                        (beneficio) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(beneficio),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Formazione
            if (dipendente.formazione != null &&
                dipendente.formazione!.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Formazione',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dipendente.formazione!.map(
                        (corso) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.school, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(corso),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Valutazioni
            if (dipendente.valutazioni != null &&
                dipendente.valutazioni!.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valutazioni',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dipendente.valutazioni!.map(
                        (valutazione) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                '${valutazione['anno']}: ${valutazione['valutazione']}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Documenti
            if (dipendente.documenti != null &&
                dipendente.documenti!.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documenti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dipendente.documenti!.map(
                        (documento) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(documento),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DipendenteAccessoPermessiCard extends StatefulWidget {
  final Dipendente dipendente;

  const _DipendenteAccessoPermessiCard({required this.dipendente});

  @override
  State<_DipendenteAccessoPermessiCard> createState() =>
      _DipendenteAccessoPermessiCardState();
}

class _DipendenteAccessoPermessiCardState
    extends State<_DipendenteAccessoPermessiCard> {
  static const Set<String> _capabilityWhitelist = {
    'read',
    'mgws_stock_read',
    'mgws_stock_move',
    'mgws_order_accept',
  };

  final QueryUserWordPress _userApi = QueryUserWordPress();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Map<String, bool> _capabilities = <String, bool>{};
  List<String> _roles = <String>[];
  List<String> _editableRoles = <String>[];
  final Set<String> _selectedRoles = <String>{};
  final Map<String, bool> _capabilityChanges = <String, bool>{};

  int get _wpUserId => widget.dipendente.wpUserId;

  @override
  void initState() {
    super.initState();
    if (_wpUserId > 0) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _userApi.getUserPermissions(_wpUserId);
      final capsRaw = data['capabilities'];
      final rolesRaw = data['roles'];
      final editableRaw = data['editable_roles'];
      final caps = <String, bool>{};
      if (capsRaw is Map) {
        for (final entry in capsRaw.entries) {
          caps[entry.key.toString()] = entry.value == true;
        }
      }
      final roles = rolesRaw is List
          ? rolesRaw.map((role) => role.toString()).toList()
          : <String>[];
      final editable = editableRaw is List
          ? editableRaw.map((role) => role.toString()).toList()
          : <String>[];
      if (!mounted) return;
      setState(() {
        _capabilities = caps;
        _roles = roles;
        _editableRoles = editable;
        _selectedRoles
          ..clear()
          ..addAll(roles);
        _capabilityChanges.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossibile caricare i permessi: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRoles() async {
    if (_selectedRoles.isEmpty) {
      _showMessage('Seleziona almeno un ruolo');
      return;
    }
    await _save(() async {
      final updated = await _userApi.updateUserPermissions(
        userId: _wpUserId,
        roles: _selectedRoles.toList()..sort(),
      );
      _applyUpdatedPermissions(updated);
      _showMessage('Ruoli aggiornati');
    });
  }

  Future<void> _saveCapabilities() async {
    final filtered = <String, bool>{};
    _capabilityChanges.forEach((key, value) {
      if (_capabilityWhitelist.contains(key)) {
        filtered[key] = value;
      }
    });
    if (filtered.isEmpty) {
      _showMessage('Nessuna capability modificabile selezionata');
      return;
    }
    await _save(() async {
      final updated = await _userApi.updateUserPermissions(
        userId: _wpUserId,
        capabilities: filtered,
      );
      _applyUpdatedPermissions(updated);
      _capabilityChanges.clear();
      _showMessage('Capability aggiornate');
    });
  }

  Future<void> _save(Future<void> Function() action) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Salvataggio non riuscito: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _applyUpdatedPermissions(Map<String, dynamic> updated) {
    final capsRaw = updated['capabilities'];
    final rolesRaw = updated['roles'];
    setState(() {
      if (capsRaw is Map) {
        _capabilities = {
          for (final entry in capsRaw.entries)
            entry.key.toString(): entry.value == true,
        };
      }
      if (rolesRaw is List) {
        _roles = rolesRaw.map((role) => role.toString()).toList();
        _selectedRoles
          ..clear()
          ..addAll(_roles);
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Accesso e permessi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_wpUserId > 0)
                  IconButton(
                    tooltip: 'Ricarica permessi',
                    onPressed: _isLoading || _isSaving
                        ? null
                        : _loadPermissions,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_wpUserId <= 0)
              const Text(
                'Questo dipendente non è collegato a un utente WordPress. '
                'Le capability MGWS si gestiscono solo sui dipendenti collegati.',
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_error != null) ...[
                MaterialBanner(
                  content: Text(_error!),
                  leading: const Icon(Icons.warning_amber),
                  actions: [
                    TextButton(
                      onPressed: _loadPermissions,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text('Utente WordPress #$_wpUserId'),
              const SizedBox(height: 12),
              _buildRolesSection(),
              const Divider(height: 28),
              _buildCapabilitiesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRolesSection() {
    final rolesUi = _editableRoles.isNotEmpty ? _editableRoles : _roles;
    if (rolesUi.isEmpty) {
      return const Text('Nessun ruolo disponibile per questo utente.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ruoli', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rolesUi
              .map(
                (role) => FilterChip(
                  label: Text(role),
                  selected: _selectedRoles.contains(role),
                  onSelected: _isSaving
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.add(role);
                            } else if (_selectedRoles.length > 1) {
                              _selectedRoles.remove(role);
                            }
                          });
                        },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveRoles,
          icon: const Icon(Icons.save),
          label: Text(_isSaving ? 'Salvataggio...' : 'Salva ruoli'),
        ),
      ],
    );
  }

  Widget _buildCapabilitiesSection() {
    final visibleCapabilities =
        _capabilities.keys.where(_capabilityWhitelist.contains).toList()
          ..sort();
    if (visibleCapabilities.isEmpty) {
      return const Text('Nessuna capability MGWS modificabile disponibile.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Capability MGWS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...visibleCapabilities.map(
          (capability) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(capability),
            value:
                _capabilityChanges[capability] ??
                (_capabilities[capability] == true),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _capabilityChanges[capability] = value;
                    });
                  },
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveCapabilities,
          icon: const Icon(Icons.save),
          label: Text(_isSaving ? 'Salvataggio...' : 'Salva capability'),
        ),
      ],
    );
  }
}
