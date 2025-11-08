import 'package:flutter/material.dart';
import '../ordini_gestisci/ordini_gestisci.code.dart';
import '../class_ordini.dart';
import '../../theme/theme.dart';

/// Pagina per la creazione di un nuovo ordine
class OrdiniCreaPage extends StatefulWidget {
  final OrdiniGestioneController controller;

  const OrdiniCreaPage({
    super.key,
    required this.controller,
  });

  @override
  State<OrdiniCreaPage> createState() => _OrdiniCreaPageState();
}

class _OrdiniCreaPageState extends State<OrdiniCreaPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers per i campi del form
  final _emailController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _indirizzoController = TextEditingController();
  final _indirizzo2Controller = TextEditingController();
  final _cittaController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _capController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _aziendaController = TextEditingController();

  OrdineStatus _statoSelezionato = OrdineStatus.pending;
  String _metodoPagamento = 'cod';
  bool _isCreating = false;
  bool _copiaIndirizzo = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _indirizzoController.dispose();
    _indirizzo2Controller.dispose();
    _cittaController.dispose();
    _provinciaController.dispose();
    _capController.dispose();
    _telefonoController.dispose();
    _aziendaController.dispose();
    super.dispose();
  }

  Future<void> _creaOrdine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    try {
      final billing = IndirizzoBilling(
        firstName: _nomeController.text,
        lastName: _cognomeController.text,
        email: _emailController.text,
        phone: _telefonoController.text,
        address1: _indirizzoController.text,
        address2: _indirizzo2Controller.text.isEmpty ? null : _indirizzo2Controller.text,
        city: _cittaController.text,
        state: _provinciaController.text,
        postcode: _capController.text,
        country: 'IT',
        company: _aziendaController.text.isEmpty ? null : _aziendaController.text,
      );

      final shipping = _copiaIndirizzo ? IndirizzoShipping(
        firstName: _nomeController.text,
        lastName: _cognomeController.text,
        address1: _indirizzoController.text,
        address2: _indirizzo2Controller.text.isEmpty ? null : _indirizzo2Controller.text,
        city: _cittaController.text,
        state: _provinciaController.text,
        postcode: _capController.text,
        country: 'IT',
        company: _aziendaController.text.isEmpty ? null : _aziendaController.text,
      ) : null;

      final nuovoOrdine = OrdiniGlobal(
        id: 0,
        status: _statoSelezionato,
        billing: billing,
        shipping: shipping,
        paymentMethod: _metodoPagamento,
        paymentMethodTitle: _getMetodoPagamentoTitolo(_metodoPagamento),
        lineItems: [], // Ordine vuoto, i prodotti verranno aggiunti dopo
      );

      final ordine = await widget.controller.creaOrdine(nuovoOrdine);

      if (mounted) {
        if (ordine != null) {
          Navigator.pop(context, ordine);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ordine #${ordine.number} creato con successo'),
              backgroundColor: customColors.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Errore nella creazione dell\'ordine'),
              backgroundColor: customColors.errorColorStatus,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _getMetodoPagamentoTitolo(String metodo) {
    switch (metodo) {
      case 'cod':
        return 'Contrassegno';
      case 'bacs':
        return 'Bonifico bancario';
      case 'cheque':
        return 'Assegno';
      case 'paypal':
        return 'PayPal';
      default:
        return 'Altro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Nuovo Ordine'),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stato ordine
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informazioni Ordine',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<OrdineStatus>(
                      value: _statoSelezionato,
                      decoration: const InputDecoration(
                        labelText: 'Stato iniziale',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: widget.controller.getStatiDisponibili().map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(widget.controller.getTestoStato(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statoSelezionato = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _metodoPagamento,
                      decoration: const InputDecoration(
                        labelText: 'Metodo di pagamento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cod', child: Text('Contrassegno')),
                        DropdownMenuItem(value: 'bacs', child: Text('Bonifico bancario')),
                        DropdownMenuItem(value: 'cheque', child: Text('Assegno')),
                        DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _metodoPagamento = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dati cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dati Cliente',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obbligatorio';
                        }
                        if (!value.contains('@')) {
                          return 'Email non valida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cognomeController,
                            decoration: const InputDecoration(
                              labelText: 'Cognome *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Telefono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aziendaController,
                      decoration: const InputDecoration(
                        labelText: 'Azienda (opzionale)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Indirizzo di fatturazione
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Indirizzo di Fatturazione',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _copiaIndirizzo,
                          onChanged: (value) {
                            setState(() => _copiaIndirizzo = value ?? true);
                          },
                        ),
                        const Text('Copia per spedizione'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _indirizzoController,
                      decoration: const InputDecoration(
                        labelText: 'Indirizzo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _indirizzo2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Indirizzo 2 (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cittaController,
                            decoration: const InputDecoration(
                              labelText: 'Città *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _provinciaController,
                            decoration: const InputDecoration(
                              labelText: 'Provincia',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capController,
                      decoration: const InputDecoration(
                        labelText: 'CAP *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.markunread_mailbox),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info box
            Card(
              color: theme.primaryColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primaryColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Dopo aver creato l\'ordine, potrai aggiungere i prodotti dalla pagina di gestione.',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _creaOrdine,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Crea Ordine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
