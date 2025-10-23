import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../class_prodotti.dart';
import '../../theme/theme.dart';
import 'prodotti_crea.code.dart';
import 'widgets/media_selector_dialog.dart';

class ProdottiCreaPage extends StatefulWidget {
  const ProdottiCreaPage({super.key});

  @override
  State<ProdottiCreaPage> createState() => _ProdottiCreaPageState();
}

class _ProdottiCreaPageState extends State<ProdottiCreaPage> with TickerProviderStateMixin {
  // Form e Controllers
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _skuController = TextEditingController();
  final _prezzoNormaleController = TextEditingController();
  final _prezzoScontatoController = TextEditingController();
  final _descrizioneBreveController = TextEditingController();
  final _descrizioneCompletaController = TextEditingController();
  final _immagineUrlController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _quantitaController = TextEditingController();

  // Animazioni
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Stato della UI
  bool _inStock = true;
  bool _hasPrezzoScontato = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isUpdatingExisting = false;
  String? _initializationError;
  int _currentStep = 0;

  // Dati
  List<VarianteTemp> _varianti = [];
  List<String> _tags = [];
  ProdottoWoo? _prodottoOriginale;
  
  // Autocompletamento
  List<ProdottoWoo> _prodottiDisponibili = [];
  List<String> _suggerimentiNome = [];
  List<String> _suggerimentiSku = [];
  List<String> _suggerimentiCategoria = [];
  List<String> _suggerimentiAttributi = [];
  Map<String, List<String>> _suggerimentiOpzioni = {};

  // Servizi
  ProdottiCreaController? _prodottiController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextControllerListeners();
    // Inizializzazione ritardata per evitare dipendenze circolari
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inizializzaPagina();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _setupTextControllerListeners() {
    _nomeController.addListener(_onNomeChanged);
    _skuController.addListener(_onSkuChanged);
  }

  Future<void> _inizializzaPagina() async {
    if (!mounted) return;
    
    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    try {
      // Inizializza il controller (usa PlatformManager internamente)
      _prodottiController = ProdottiCreaController();
      await _caricaDatiAutocompletamento();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          //_initializationError = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _caricaDatiAutocompletamento() async {
    if (_prodottiController == null) return;
    
    try {
      await Future.wait([
        _prodottiController!.listProducts(perPage: 100).then((prodotti) {
          _prodottiDisponibili = prodotti;
          _suggerimentiNome = _prodottiDisponibili.map((p) => p.nome).toSet().toList();
          _suggerimentiSku = _prodottiDisponibili.map((p) => p.sku).where((s) => s.isNotEmpty).toSet().toList();
        }).catchError((e) { debugPrint('Errore caricamento prodotti: $e'); return null; }),
        
        _prodottiController!.getAttributes().then((attributes) async {
          _suggerimentiAttributi = attributes.map((a) => a.name as String? ?? '').where((n) => n.isNotEmpty).toList();
          for (final attr in attributes) {
            try {
              if (attr.id != null && attr.name != null) {
                final terms = await _prodottiController!.getAttributeTerms(attr.id!);
                _suggerimentiOpzioni[attr.name!] = terms.map((t) => t.name as String? ?? '').where((n) => n.isNotEmpty).toList();
              }
            } catch (e) {
              debugPrint('Errore caricamento termini per ${attr.name}: $e');
            }
          }
        }).catchError((e) { debugPrint('Errore caricamento attributi: $e'); return null; }),

        _prodottiController!.getCategories().then((categories) {
          _suggerimentiCategoria = categories.map((c) => c.nome).toList();
        }).catchError((e) { debugPrint('Errore caricamento categorie: $e'); return null; }),
      ]);
    } catch (e) {
      debugPrint('Errore generale caricamento dati: $e');
    }
  }

  void _onNomeChanged() {
    if (_prodottiController == null) return;
    final nome = _nomeController.text.trim();
    if (nome.isEmpty || _isUpdatingExisting) return;
    
    final prodottoTrovato = _prodottiDisponibili.firstWhere(
      (p) => p.nome.toLowerCase() == nome.toLowerCase(),
      orElse: () => ProdottoWoo(id: 0, nome: '', sku: '', prezzoNormale: 0.0, descrizioneBreve: '', immagineUrl: '', varianti: [], categoria: '', inStock: false),
    );
    if (prodottoTrovato.id != 0) _mostraDialogProdottoEsistente(prodottoTrovato);
  }

  void _onSkuChanged() {
    if (_prodottiController == null) return;
    final sku = _skuController.text.trim();
    if (sku.isEmpty || _isUpdatingExisting) return;
    
    final prodottoTrovato = _prodottiDisponibili.firstWhere(
      (p) => p.sku.toLowerCase() == sku.toLowerCase(),
      orElse: () => ProdottoWoo(id: 0, nome: '', sku: '', prezzoNormale: 0.0, descrizioneBreve: '', immagineUrl: '', varianti: [], categoria: '', inStock: false),
    );
    if (prodottoTrovato.id != 0) _mostraDialogProdottoEsistente(prodottoTrovato);
  }

  void _mostraDialogProdottoEsistente(ProdottoWoo prodotto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Prodotto Esistente')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Il prodotto "${prodotto.nome}" esiste già nel sistema.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${prodotto.id}', style: Theme.of(context).textTheme.bodySmall),
                  Text('SKU: ${prodotto.sku}', style: Theme.of(context).textTheme.bodySmall),
                  Text('Prezzo: €${prodotto.prezzoNormale.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Vuoi caricare i dati esistenti per modificarlo?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continua Nuovo'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _caricaDatiProdottoEsistente(prodotto);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Carica e Modifica'),
          ),
        ],
      ),
    );
  }

  void _caricaDatiProdottoEsistente(ProdottoWoo prodotto) {
    setState(() {
      _isUpdatingExisting = true;
      _prodottoOriginale = prodotto;
      _nomeController.text = prodotto.nome;
      _skuController.text = prodotto.sku;
      _prezzoNormaleController.text = prodotto.prezzoNormale.toString();
      _prezzoScontatoController.text = prodotto.prezzoScontato?.toString() ?? '';
      _hasPrezzoScontato = prodotto.prezzoScontato != null;
      _descrizioneBreveController.text = prodotto.descrizioneBreve;
      _descrizioneCompletaController.text = prodotto.descrizioneCompleta ?? '';
      _immagineUrlController.text = prodotto.immagineUrl;
      _categoriaController.text = prodotto.categoria;
      _pesoController.text = prodotto.peso ?? '';
      _quantitaController.text = (prodotto.quantitaTotale ?? 0).toString();
      _inStock = prodotto.inStock;
      _tags = List.from(prodotto.tag);
      _varianti = prodotto.varianti.map((v) => VarianteTemp.fromVarianteWoo(v)).toList();
    });

    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Dati del prodotto "${prodotto.nome}" caricati per la modifica'),
          ],
        ),
        backgroundColor: customColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isUpdatingExisting = false;
      _prodottoOriginale = null;
      _currentStep = 0;
      _formKey.currentState?.reset();
      _nomeController.clear();
      _skuController.clear();
      _prezzoNormaleController.clear();
      _prezzoScontatoController.clear();
      _descrizioneBreveController.clear();
      _descrizioneCompletaController.clear();
      _immagineUrlController.clear();
      _categoriaController.clear();
      _pesoController.clear();
      _quantitaController.clear();
      _varianti.clear();
      _tags.clear();
      _inStock = true;
      _hasPrezzoScontato = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nomeController.dispose();
    _skuController.dispose();
    _prezzoNormaleController.dispose();
    _prezzoScontatoController.dispose();
    _descrizioneBreveController.dispose();
    _descrizioneCompletaController.dispose();
    _immagineUrlController.dispose();
    _categoriaController.dispose();
    _pesoController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        // Aggiunge il tema per la selezione del testo (cursore e highlight)
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor.withValues(alpha: 0.3),
          selectionHandleColor: primaryColor,
        ),
        // cardTheme: CardTheme(
        //   elevation: 6,
        //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        //   shadowColor: Colors.black26,
        // ),
      ),
      child: Scaffold(
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).extension<AppColorExtension>()?.gradientStart ?? 
              Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).extension<AppColorExtension>()?.gradientEnd ?? 
              Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isInitializing) 
            _buildLoadingSliver()
          else if (_initializationError != null)
            _buildErrorSliver()
          else
            _buildContentSliver(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isUpdatingExisting ? 'Modifica Prodotto' : 'Nuovo Prodotto',
            key: ValueKey(_isUpdatingExisting),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isUpdatingExisting)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Crea Nuovo Prodotto',
            onPressed: _resetForm,
          ),
        if (_prodottiController != null)
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            tooltip: 'Salva Prodotto',
            onPressed: _isLoading ? null : _salvaProdotto,
          ),
      ],
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Caricamento dati...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparazione interfaccia prodotti',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Modalità Offline',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _initializationError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Indietro'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _initializationError = null;
                            _prodottiController = null;
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Continua Offline'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isUpdatingExisting) _buildStatusBanner(),
                  const SizedBox(height: 16),
                  _buildStepperContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modalità Modifica',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID Prodotto: ${_prodottoOriginale?.id} - SKU: ${_prodottoOriginale?.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperContent() {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Theme.of(context).primaryColor,
        ),
      ),
      child: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (details.stepIndex < 3)
                FilledButton.icon(
                  onPressed: details.onStepContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Avanti'),
                ),
              if (details.stepIndex > 0) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Indietro'),
                ),
              ],
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Informazioni Base'),
            content: _buildInformazioniGenerali(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Prezzi e Stock'),
            content: _buildPrezziEStock(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Dettagli'),
            content: _buildDettagli(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Varianti'),
            content: _buildVarianti(),
            isActive: _currentStep >= 3,
            state: _currentStep == 3 ? StepState.indexed : StepState.disabled,
          ),
        ],
      ),
    );
  }

  Widget _buildInformazioniGenerali() {
    return Column(
      children: [
        _buildSmartTextFormField(
          controller: _nomeController,
          label: 'Nome Prodotto',
          icon: Icons.inventory,
          suggestions: _suggerimentiNome,
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _skuController,
          label: 'SKU',
          icon: Icons.qr_code,
          suggestions: _suggerimentiSku,
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _categoriaController,
          label: 'Categoria',
          icon: Icons.category,
          suggestions: _suggerimentiCategoria,
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildTagsField(),
      ],
    );
  }

  Widget _buildPrezziEStock() {
    return Column(
      children: [
        _buildSmartTextFormField(
          controller: _prezzoNormaleController,
          label: 'Prezzo Normale',
          icon: Icons.euro,
          suffix: '€',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('Prezzo Scontato'),
            subtitle: const Text('Attiva per impostare un prezzo di vendita'),
            value: _hasPrezzoScontato,
            onChanged: (value) => setState(() => _hasPrezzoScontato = value),
            secondary: const Icon(Icons.local_offer),
          ),
        ),
        if (_hasPrezzoScontato) ...[
          const SizedBox(height: 16),
          _buildSmartTextFormField(
            controller: _prezzoScontatoController,
            label: 'Prezzo Scontato',
            icon: Icons.local_offer,
            suffix: '€',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmartTextFormField(
                controller: _quantitaController,
                label: 'Quantità',
                icon: Icons.inventory_2,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final customColors = Theme.of(context).extension<AppColorExtension>()!;
                  return Card(
                    child: SwitchListTile(
                      title: const Text('Disponibile'),
                      value: _inStock,
                      onChanged: (value) => setState(() => _inStock = value),
                      secondary: Icon(
                        _inStock ? Icons.check_circle : Icons.cancel,
                        color: _inStock ? customColors.successColor : customColors.errorColorStatus,
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDettagli() {
    return Column(
      children: [
        _buildSmartTextFormField(
          controller: _descrizioneBreveController,
          label: 'Descrizione Breve',
          icon: Icons.short_text,
          maxLines: 3,
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _descrizioneCompletaController,
          label: 'Descrizione Completa',
          icon: Icons.article,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        _buildImageSelector(),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _pesoController,
          label: 'Peso (kg)',
          icon: Icons.scale,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildVarianti() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Varianti Prodotto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_varianti.length} varianti configurate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _aggiungiVariante,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi Variante'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_varianti.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna Variante',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Il prodotto sarà "semplice". Aggiungi varianti per creare un prodotto variabile.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_varianti.length, (index) => _buildVarianteCard(index)),
      ],
    );
  }

  Widget _buildVarianteCard(int index) {
    final variante = _varianti[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: Text('${index + 1}'),
        ),
        title: Text(
          'Variante #${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'SKU: ${variante.sku.isEmpty ? 'Non impostato' : variante.sku} - Prezzo: €${variante.prezzo.toStringAsFixed(2)}',
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _duplicaVariante(index),
              child: const Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Duplica'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _rimuoviVariante(index),
              child: Builder(
                builder: (context) {
                  final customColors = Theme.of(context).extension<AppColorExtension>()!;
                  return Row(
                    children: [
                      Icon(Icons.delete, color: customColors.errorColorStatus),
                      const SizedBox(width: 8),
                      Text('Elimina', style: TextStyle(color: customColors.errorColorStatus)),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: variante.sku,
                        onChanged: (value) => variante.sku = value,
                        decoration: const InputDecoration(
                          labelText: 'SKU Variante',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: variante.prezzo.toString(),
                        onChanged: (value) => variante.prezzo = double.tryParse(value) ?? 0.0,
                        decoration: const InputDecoration(
                          labelText: 'Prezzo',
                          prefixIcon: Icon(Icons.euro),
                          suffixText: '€',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: variante.quantita.toString(),
                        onChanged: (value) => variante.quantita = int.tryParse(value) ?? 0,
                        decoration: const InputDecoration(
                          labelText: 'Quantità',
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: variante.immagineUrl ?? '',
                        onChanged: (value) => variante.immagineUrl = value.isEmpty ? null : value,
                        decoration: const InputDecoration(
                          labelText: 'URL Immagine',
                          prefixIcon: Icon(Icons.image),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAttributiVariante(variante, index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributiVariante(VarianteTemp variante, int varianteIndex) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attributi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _aggiungiAttributo(varianteIndex),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (variante.attributi.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nessun attributo definito',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(
                variante.attributi.length,
                (attrIndex) => _buildAttributoItem(variante.attributi[attrIndex], varianteIndex, attrIndex),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributoItem(AttributoVariante attributo, int varianteIndex, int attrIndex) {
    final isColorAttr = _prodottiController?.isColorAttribute(attributo.nome) ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildSmartTextFormField(
                  initialValue: attributo.nome,
                  label: 'Nome Attributo',
                  icon: Icons.tune,
                  suggestions: _suggerimentiAttributi,
                  onChanged: (value) {
                    setState(() {
                      _varianti[varianteIndex].attributi[attrIndex] = 
                          attributo.copyWith(nome: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildSmartTextFormField(
                  initialValue: attributo.opzione,
                  label: 'Opzione',
                  icon: Icons.format_list_bulleted,
                  suggestions: _suggerimentiOpzioni[attributo.nome] ?? [],
                  onChanged: (value) {
                    setState(() {
                      _varianti[varianteIndex].attributi[attrIndex] = 
                          attributo.copyWith(opzione: value);
                    });
                  },
                ),
              ),
              if (isColorAttr) ...[
                const SizedBox(width: 12),
                _buildColorPicker(attributo, varianteIndex, attrIndex),
              ],
              Builder(
                builder: (context) {
                  final customColors = Theme.of(context).extension<AppColorExtension>()!;
                  return IconButton(
                    icon: Icon(Icons.delete_outline, color: customColors.errorColorStatus),
                    tooltip: 'Rimuovi Attributo',
                    onPressed: () => _rimuoviAttributo(varianteIndex, attrIndex),
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(AttributoVariante attributo, int varianteIndex, int attrIndex) {
    final currentColor = ColorUtils.colorFromHex(attributo.valore ?? '#FFFFFF');
    
    return Column(
      children: [
        const Text('Colore', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showColorPickerDialog(
            context: context,
            initialColor: currentColor,
            onColorSelected: (color) {
              final hexValue = ColorUtils.colorToHex(color).toUpperCase();
              setState(() {
                _varianti[varianteIndex].attributi[attrIndex] = 
                    attributo.copyWith(valore: hexValue);
              });
            },
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.palette,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    final hasImage = _immagineUrlController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Immagine Principale *',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (hasImage) ...[
                  // Anteprima immagine
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _immagineUrlController.text.trim(),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Impossibile caricare l\'immagine',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _immagineUrlController.text.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final selectedMedia = await showMediaSelector(context);
                          if (selectedMedia != null && mounted) {
                            setState(() {
                              _immagineUrlController.text = selectedMedia.url;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: Text(hasImage ? 'Cambia Immagine' : 'Seleziona da Libreria'),
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final customColors = Theme.of(context).extension<AppColorExtension>()!;
                          return OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _immagineUrlController.clear();
                              });
                            },
                            icon: Icon(Icons.delete_outline, color: customColors.errorColorStatus),
                            label: Text('Rimuovi', style: TextStyle(color: customColors.errorColorStatus)),
                          );
                        }
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Aggiungi Tag',
                          prefixIcon: Icon(Icons.tag),
                          suffixIcon: Icon(Icons.add),
                        ),
                        onFieldSubmitted: (value) {
                          if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
                            setState(() => _tags.add(value.trim()));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartTextFormField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    IconData? icon,
    List<String>? suggestions,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
  }) {
    // Se non è fornito un controller, usa initialValue direttamente (senza controller)
    // Questo evita problemi con il testo che si scrive al contrario

    if (suggestions != null && suggestions.isNotEmpty) {
      // Con autocompletamento
      return Autocomplete<String>(
        initialValue: TextEditingValue(text: initialValue ?? ''),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable.empty();
          return suggestions.where((option) =>
              option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (selection) {
          onChanged?.call(selection);
        },
        fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
          // Sincronizza il controller con initialValue solo alla prima creazione
          if (controller == null && initialValue != null && fieldController.text.isEmpty) {
            fieldController.text = initialValue;
          }

          return TextFormField(
            controller: controller ?? fieldController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixText: suffix,
            ),
            validator: validator,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
          );
        },
      );
    }

    // Senza autocompletamento - usa initialValue direttamente
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixText: suffix,
      ),
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildFloatingActionButton() {
    if (_prodottiController == null) return const SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _salvaProdotto,
      icon: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(_isUpdatingExisting ? Icons.update : Icons.save),
      label: Text(_isUpdatingExisting ? 'Aggiorna' : 'Salva Prodotto'),
      backgroundColor: _isLoading 
          ? Colors.grey 
          : Theme.of(context).primaryColor,
    );
  }

  void _showColorPickerDialog({
    required BuildContext context,
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    Color pickerColor = initialColor;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette),
                  const SizedBox(width: 8),
                  Text(
                    'Seleziona Colore',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) => pickerColor = color,
                pickerAreaHeightPercent: 0.6,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsv,
                labelTypes: const [ColorLabelType.hex],
                hexInputBar: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      onColorSelected(pickerColor);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Conferma'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _aggiungiVariante() {
    setState(() {
      _varianti.add(VarianteTemp(
        nome: 'Variante ${_varianti.length + 1}',
        sku: '',
        prezzo: double.tryParse(_prezzoNormaleController.text) ?? 0.0,
        quantita: int.tryParse(_quantitaController.text) ?? 0,
      ));
    });
  }

  void _duplicaVariante(int index) {
    final variante = _varianti[index];
    setState(() {
      _varianti.insert(index + 1, VarianteTemp(
        nome: '${variante.nome} (Copia)',
        sku: '${variante.sku}_copy',
        prezzo: variante.prezzo,
        quantita: variante.quantita,
        immagineUrl: variante.immagineUrl,
        attributi: variante.attributi.map((attr) => AttributoVariante(
          nome: attr.nome,
          opzione: attr.opzione,
          valore: attr.valore,
        )).toList(),
      ));
    });
  }

  void _rimuoviVariante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Sei sicuro di voler eliminare la variante "${_varianti[index].nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _varianti.removeAt(index));
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).extension<AppColorExtension>()!.errorColorStatus),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _aggiungiAttributo(int varianteIndex) {
    setState(() {
      _varianti[varianteIndex].attributi.add(
        AttributoVariante(nome: '', opzione: ''),
      );
    });
  }

  void _rimuoviAttributo(int varianteIndex, int attrIndex) {
    setState(() {
      _varianti[varianteIndex].attributi.removeAt(attrIndex);
    });
  }

  void _salvaProdotto() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Controlla i campi obbligatori'),
            ],
          ),
          backgroundColor: Theme.of(context).extension<AppColorExtension>()!.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_prodottiController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Impossibile salvare in modalità offline'),
            ],
          ),
          backgroundColor: Theme.of(context).extension<AppColorExtension>()!.errorColorStatus,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prodotto = _creaProdottoDaForm();

      // Usa salvaProductoConVarianti per gestire sia il prodotto che le varianti
      await _prodottiController!.salvaProductoConVarianti(prodotto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_isUpdatingExisting 
                    ? 'Prodotto aggiornato con successo!' 
                    : 'Prodotto creato con successo!'),
              ],
            ),
            backgroundColor: Theme.of(context).extension<AppColorExtension>()!.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: errorMessage));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Errore copiato negli appunti'),
                      ],
                    ),
                    backgroundColor: Theme.of(context).extension<AppColorExtension>()!.successColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Errore: $errorMessage'),
                        const SizedBox(height: 4),
                        const Text(
                          'Tocca per copiare',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy, color: Colors.white70, size: 18),
                ],
              ),
            ),
            backgroundColor: Theme.of(context).extension<AppColorExtension>()!.errorColorStatus,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ProdottoWoo _creaProdottoDaForm() {
    return ProdottoWoo(
      id: _prodottoOriginale?.id ?? 0,
      nome: _nomeController.text.trim(),
      sku: _skuController.text.trim(),
      prezzoNormale: double.tryParse(_prezzoNormaleController.text) ?? 0.0,
      prezzoScontato: _hasPrezzoScontato 
          ? double.tryParse(_prezzoScontatoController.text)
          : null,
      descrizioneBreve: _descrizioneBreveController.text.trim(),
      descrizioneCompleta: _descrizioneCompletaController.text.trim().isEmpty 
          ? null 
          : _descrizioneCompletaController.text.trim(),
      immagineUrl: _immagineUrlController.text.trim(),
      categoria: _categoriaController.text.trim(),
      peso: _pesoController.text.trim().isEmpty ? null : _pesoController.text.trim(),
      quantitaTotale: int.tryParse(_quantitaController.text) ?? 0,
      inStock: _inStock,
      varianti: _varianti.map((temp) => temp.toVarianteWoo()).toList(),
      tag: List.from(_tags),
      status: 'draft',
    );
  }
}

// Classe helper per gestire le varianti temporanee durante l'editing
class VarianteTemp {
  int? id;
  String nome;
  String sku;
  double prezzo;
  double? prezzoScontato;
  int quantita;
  String? immagineUrl;
  List<AttributoVariante> attributi;

  VarianteTemp({
    this.id,
    required this.nome,
    required this.sku,
    required this.prezzo,
    this.prezzoScontato,
    required this.quantita,
    this.immagineUrl,
    List<AttributoVariante>? attributi,
  }) : attributi = attributi ?? [];

  factory VarianteTemp.fromVarianteWoo(VarianteWoo variante) {
    return VarianteTemp(
      id: variante.id,
      nome: variante.nome,
      sku: variante.sku,
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: variante.quantita,
      immagineUrl: variante.immagineUrl,
      attributi: List.from(variante.attributi),
    );
  }

  VarianteWoo toVarianteWoo() {
    return VarianteWoo(
      id: id ?? 0,
      nome: nome,
      sku: sku,
      prezzo: prezzo,
      prezzoScontato: prezzoScontato,
      quantita: quantita,
      immagineUrl: immagineUrl,
      attributi: attributi,
    );
  }
}