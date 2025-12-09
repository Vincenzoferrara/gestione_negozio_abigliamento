import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dipendenti.code.dart'; // Import the code file for logic

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
        builder: (context) => DipendenteFormScreen(isEdit: false),
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
        builder: (context) =>
            DipendenteFormScreen(isEdit: true, dipendente: dipendente),
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

  const DipendenteFormScreen({
    super.key,
    required this.isEdit,
    this.dipendente,
  });

  @override
  _DipendenteFormScreenState createState() => _DipendenteFormScreenState();
}

class _DipendenteFormScreenState extends State<DipendenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _ruoloController = TextEditingController();
  final _stipendioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.dipendente != null) {
      _nomeController.text = widget.dipendente!.nome;
      _cognomeController.text = widget.dipendente!.cognome;
      _emailController.text = widget.dipendente!.email;
      _ruoloController.text = widget.dipendente!.ruolo;
      _stipendioController.text = widget.dipendente!.stipendio.toString();
    }
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
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Inserisci stipendio' : null,
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

  void _saveDipendente() {
    if (_formKey.currentState!.validate()) {
      final dipendente = Dipendente(
        id: widget.isEdit ? widget.dipendente!.id : 0,
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        email: _emailController.text,
        ruolo: _ruoloController.text,
        stipendio: double.parse(_stipendioController.text),
        // Per ora non aggiungiamo i nuovi campi nella form, solo nel modello
      );
      if (widget.isEdit) {
        DipendentiService().updateDipendente(dipendente);
      } else {
        DipendentiService().addDipendente(dipendente);
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
