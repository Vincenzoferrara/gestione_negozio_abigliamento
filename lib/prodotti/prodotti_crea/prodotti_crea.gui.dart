import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../class_prodotti.dart';
import '../../theme/theme.dart';
import '../../settings/app_settings.dart';
import '../../settings/prodotti_image_settings.dart';
import '../../ai/ai_service.dart';
import '../../log_viewer/app_logger.dart';
import '../../notification/notification_service.dart';
import '../../reuse_class/gui/searchable_checkbox_dialog.dart';
import '../../reuse_class/gui/notification_recap_dialog.dart';
import '../../reuse_class/image_url_resolver.dart';
import 'prodotti_crea.code.dart';
import 'variant_combinations.dart';
import 'widgets/media_selector_dialog.dart';

Future<bool?> openProductEditor(
  BuildContext context, {
  ProdottoGlobal? prodottoDaModificare,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) =>
          ProdottiCreaPage(prodottoDaModificare: prodottoDaModificare),
    ),
  );
}

class ProdottiCreaPage extends StatefulWidget {
  final ProdottoGlobal? prodottoDaModificare;
  final ProdottiCreaController? controller;

  const ProdottiCreaPage({
    super.key,
    this.prodottoDaModificare,
    this.controller,
  });

  @override
  State<ProdottiCreaPage> createState() => _ProdottiCreaPageState();
}

enum ProductTypeSelection { simple, variable }

const List<String> _productStatusOptions = <String>[
  'draft',
  'publish',
  'private',
  'pending',
];

class _ProdottiCreaPageState extends State<ProdottiCreaPage>
    with TickerProviderStateMixin {
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
  final _marcaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _quantitaController = TextEditingController();
  final _quickVarianteSkuController = TextEditingController();
  final _quickVarianteBarcodeController = TextEditingController();
  final _quickVarianteQuantitaController = TextEditingController(text: '0');
  final _quickVarianteTagliaController = TextEditingController();
  final _quickVarianteColoreController = TextEditingController();
  final _mgwsStockController = TextEditingController();
  final _mgwsReasonController = TextEditingController();

  // Animazioni
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Stato della UI
  bool _inStock = true;
  bool _hasPrezzoScontato = false;
  ProductTypeSelection _productType = ProductTypeSelection.variable;
  String _productStatus = 'draft';
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isUpdatingExisting = false;
  String? _initializationError;
  int _currentStep = 0;
  int? _selectedVarianteIndex;
  double _saveProgress = 0.0;
  String _saveProgressLabel = '';
  bool _mgwsInventoryEnabled = false;
  String? _mgwsInventoryFeedbackText;
  bool? _mgwsInventoryFeedbackSuccess;
  final List<FocusNode> _barcodeFocusNodes = [];
  final Map<int, String> _barcodePreviousValues = {};

  // Stato IA
  bool _isGeneratingShortDesc = false;
  bool _isGeneratingLongDesc = false;
  bool _isGeneratingCategories = false;
  bool _isGeneratingTags = false;

  // Dati
  List<VarianteTemp> _varianti = [];
  List<AttributoVariante> _attributiProdottoEsistenti = [];
  List<AttributoProdottoSelezionato> _attributiProdottoSelezionati = [];
  List<String> _categorieSelezionate = [];
  List<String> _tags = [];
  ProdottoGlobal? _prodottoOriginale;
  final ProductImageUiConfig _mainImageConfig = ProductImageUiConfig();
  final ProductImageUiConfig _defaultImageConfig = ProductImageUiConfig();
  List<String> _mainImageSetUrls = [];
  bool _showImageDimensionWarnings = true;
  int _imageWarningThresholdWidth = 720;
  int _imageWarningThresholdHeight = 1080;

  // Autocompletamento
  List<String> _suggerimentiCategoria = [];
  List<String> _suggerimentiMarca = [];
  List<String> _suggerimentiAttributi = [];
  Map<String, List<String>> _suggerimentiOpzioni = {};

  // Servizi
  ProdottiCreaController? _prodottiController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Inizializzazione ritardata per evitare dipendenze circolari
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inizializzaPagina();
    });
  }

  void _initializeAnimations() {
    _mgwsReasonController.text = _defaultMgwsInventoryReason();
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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _inizializzaPagina() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    try {
      // Inizializza il controller (usa PlatformManager internamente)
      _prodottiController = widget.controller ?? ProdottiCreaController();
      await Future.wait([
        _caricaDatiAutocompletamento(),
        _caricaImpostazioniImmaginiDefault(),
      ]);

      if (widget.prodottoDaModificare != null) {
        await _caricaDatiProdottoEsistente(widget.prodottoDaModificare!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = 'Impossibile inizializzare il form: $e';
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
      log.d('PCREA_AUTOCOMPLETE_START');
      await Future.wait([
        _prodottiController!
            .getAttributes()
            .then((attributes) async {
              _suggerimentiAttributi = attributes
                  .map((a) => a.name as String? ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList();
              for (final attr in attributes) {
                try {
                  if (attr.id != null && attr.name != null) {
                    final terms = await _prodottiController!.getAttributeTerms(
                      attr.id!,
                    );
                    _suggerimentiOpzioni[attr.name!] = terms
                        .map((t) => t.name as String? ?? '')
                        .where((n) => n.isNotEmpty)
                        .toList();
                  }
                } catch (e) {
                  debugPrint('Errore caricamento termini per ${attr.name}: $e');
                }
              }
            })
            .catchError((e) {
              debugPrint('Errore caricamento attributi: $e');
              log.e('PCREA_AUTOCOMPLETE_ATTRIBUTES_FAIL $e');
              return null;
            }),

        _prodottiController!
            .getCategories()
            .then((categories) {
              _suggerimentiCategoria = categories.map((c) => c.nome).toList();
            })
            .catchError((e) {
              debugPrint('Errore caricamento categorie: $e');
              log.e('PCREA_AUTOCOMPLETE_CATEGORIES_FAIL $e');
              return null;
            }),

        _prodottiController!
            .getBrands()
            .then((brands) {
              _suggerimentiMarca = brands.map((b) => b.nome).toSet().toList();
            })
            .catchError((e) {
              debugPrint('Errore caricamento marchi: $e');
              log.e('PCREA_AUTOCOMPLETE_BRANDS_FAIL $e');
              return null;
            }),
      ]);
      log.d('PCREA_AUTOCOMPLETE_DONE');
    } catch (e) {
      debugPrint('Errore generale caricamento dati: $e');
      log.e('PCREA_AUTOCOMPLETE_FAIL $e');
    }
  }

  Future<void> _caricaImpostazioniImmaginiDefault() async {
    final settings = ProductImageWarningSettings();
    await settings.init();

    if (!mounted) return;

    setState(() {
      _showImageDimensionWarnings = settings.warningsEnabled;
      _imageWarningThresholdWidth = settings.thresholdWidth;
      _imageWarningThresholdHeight = settings.thresholdHeight;
    });
  }

  void _applyDefaultImageConfig(ProductImageUiConfig target) {
    target.isSetMode = false;
  }

  ProductImageUiConfig _newImageConfigFromDefaults() {
    final config = ProductImageUiConfig();
    _applyDefaultImageConfig(config);
    return config;
  }

  Future<void> _caricaDatiProdottoEsistente(ProdottoGlobal prodotto) async {
    final int productId = prodotto.id ?? 0;
    log.d('PCREA_LOAD_EXISTING_START productId=$productId sku=${prodotto.sku}');

    List<VarianteProductGlobal> variantiServer = prodotto.varianti ?? [];
    if (productId > 0 && _prodottiController != null) {
      try {
        variantiServer = await _prodottiController!.getAllVarianti(
          productId,
          logRawAttributeMapping: true,
        );
        log.d(
          'PCREA_LOAD_EXISTING_VARIANTS productId=$productId count=${variantiServer.length}',
        );
      } catch (e) {
        log.e(
          'PCREA_LOAD_EXISTING_VARIANTS_FAIL productId=$productId error=$e',
        );
      }
    }

    if (!mounted) return;

    for (final attributo in _attributiProdottoSelezionati) {
      attributo.dispose();
    }

    setState(() {
      _isUpdatingExisting = true;
      _prodottoOriginale = prodotto;
      _nomeController.text = prodotto.nome ?? '';
      _skuController.text = prodotto.sku ?? '';
      _prezzoNormaleController.text = (prodotto.prezzoNormale ?? 0).toString();
      _prezzoScontatoController.text =
          prodotto.prezzoScontato?.toString() ?? '';
      _hasPrezzoScontato = prodotto.prezzoScontato != null;
      _productType = (variantiServer.isNotEmpty)
          ? ProductTypeSelection.variable
          : ProductTypeSelection.simple;
      _descrizioneBreveController.text = prodotto.descrizioneBreve ?? '';
      _descrizioneCompletaController.text = prodotto.descrizioneCompleta ?? '';
      _immagineUrlController.text = prodotto.immagineUrl ?? '';
      _categorieSelezionate =
          prodotto.categoria?.map((c) => c.nome).toList() ?? [];
      _categoriaController.text = _categorieSelezionate.join(', ');
      _marcaController.text = prodotto.marca ?? '';
      _pesoController.text = prodotto.peso ?? '';
      _quantitaController.text = (prodotto.quantitaTotale ?? 0).toString();
      _inStock = prodotto.inStock;
      _mgwsInventoryEnabled = false;
      _mgwsStockController.clear();
      _mgwsReasonController.text = _defaultMgwsInventoryReason();
      _mgwsInventoryFeedbackText = null;
      _mgwsInventoryFeedbackSuccess = null;
      _productStatus = _normalizeProductStatus(prodotto.status);
      _tags = prodotto.tag?.map((t) => t.nome).toList() ?? [];
      _applyDefaultImageConfig(_mainImageConfig);
      _mainImageSetUrls = List<String>.from(prodotto.immaginiAggiuntive ?? []);
      _mainImageConfig.isSetMode = _mainImageSetUrls.isNotEmpty;
      _varianti = variantiServer
          .map(
            (v) =>
                VarianteTemp.fromVarianteProductGlobal(v, _defaultImageConfig),
          )
          .toList();
      _attributiProdottoEsistenti = _collectProductAttributes(
        prodotto: prodotto,
        varianti: _varianti,
      );
      // In modifica le varianti esistenti restano disponibili, ma il
      // compositore parte vuoto: gli attributi da aggiungere sono una scelta
      // esplicita dell'utente e non vengono precompilati da quelli esistenti.
      _attributiProdottoSelezionati = [];
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = _varianti.isEmpty ? null : 0;
    });

    NotificationService.instance.messageBar(
      'successo',
      'prodotti_crea',
      'Dati del prodotto "${prodotto.nome}" caricati per la modifica',
    );
    log.d('PCREA_LOAD_EXISTING_DONE productId=$productId');
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
      _categorieSelezionate = [];
      _marcaController.clear();
      _pesoController.clear();
      _quantitaController.clear();
      _quickVarianteSkuController.clear();
      _quickVarianteBarcodeController.clear();
      _quickVarianteQuantitaController.text = '0';
      _quickVarianteTagliaController.clear();
      _quickVarianteColoreController.clear();
      _mgwsStockController.clear();
      _mgwsReasonController.text = _defaultMgwsInventoryReason();
      _mgwsInventoryEnabled = false;
      _mgwsInventoryFeedbackText = null;
      _mgwsInventoryFeedbackSuccess = null;
      for (final attributo in _attributiProdottoSelezionati) {
        attributo.dispose();
      }
      _attributiProdottoSelezionati = [];
      _attributiProdottoEsistenti = [];
      _varianti.clear();
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = null;
      _tags.clear();
      _applyDefaultImageConfig(_mainImageConfig);
      _mainImageSetUrls = [];
      _inStock = true;
      _hasPrezzoScontato = false;
      _productType = ProductTypeSelection.variable;
      _productStatus = 'draft';
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
    _marcaController.dispose();
    _pesoController.dispose();
    _quantitaController.dispose();
    _quickVarianteSkuController.dispose();
    _quickVarianteBarcodeController.dispose();
    _quickVarianteQuantitaController.dispose();
    _quickVarianteTagliaController.dispose();
    _quickVarianteColoreController.dispose();
    _mgwsStockController.dispose();
    _mgwsReasonController.dispose();
    for (final attributo in _attributiProdottoSelezionati) {
      attributo.dispose();
    }
    for (final node in _barcodeFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.9),
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
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).extension<AppColorExtension>()?.gradientEnd ??
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
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
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Indietro'),
                      ),
                      FilledButton.icon(
                        onPressed: _inizializzaPagina,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
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
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    _buildSaveProgressSection(),
                  ],
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
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: Theme.of(context).primaryColor),
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
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _skuController,
          label: 'SKU',
          icon: Icons.qr_code,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        // Tags con pulsante IA
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTagsField()),
            const SizedBox(width: 8),
            _buildAIButton(
              isLoading: _isGeneratingTags,
              tooltip: 'Suggerisci tag',
              onPressed: _generateTags,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrezziEStock() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.category_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<ProductTypeSelection>(
                    initialValue: _productType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo prodotto',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ProductTypeSelection.simple,
                        child: Text('Semplice'),
                      ),
                      DropdownMenuItem(
                        value: ProductTypeSelection.variable,
                        child: Text('Con varianti'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _productType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSmartTextFormField(
          controller: _prezzoNormaleController,
          label: 'Prezzo Normale',
          icon: Icons.euro,
          suffix: '€',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
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
        if (_productType == ProductTypeSelection.simple)
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
                    final customColors = Theme.of(
                      context,
                    ).extension<AppColorExtension>()!;
                    return Card(
                      child: SwitchListTile(
                        title: const Text('Disponibile'),
                        value: _inStock,
                        onChanged: (value) => setState(() => _inStock = value),
                        secondary: Icon(
                          _inStock ? Icons.check_circle : Icons.cancel,
                          color: _inStock
                              ? customColors.successColor
                              : customColors.errorColorStatus,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Stock per variante'),
              subtitle: const Text(
                'Per prodotti con varianti, quantità/disponibilità si impostano su ogni variante.',
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildMgwsInventorySection(),
      ],
    );
  }

  Widget _buildMgwsInventorySection() {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();
    final feedbackSuccess = _mgwsInventoryFeedbackSuccess ?? false;
    final feedbackColor = feedbackSuccess
        ? customColors?.successColor ?? theme.colorScheme.primary
        : customColors?.warningColor ?? theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const ValueKey('productMgwsInventoryEnabledSwitch'),
              contentPadding: EdgeInsets.zero,
              value: _mgwsInventoryEnabled,
              onChanged: _setMgwsInventoryEnabled,
              secondary: Icon(
                Icons.warehouse_outlined,
                color: _mgwsInventoryEnabled ? theme.primaryColor : null,
              ),
              title: Text(
                'Inventario MGWS',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                'Registra stock iniziale o rettifica auditata dopo il salvataggio del prodotto.',
              ),
            ),
            Text(
              'Il valore inserito diventa il totale finale MGWS tramite reconcile stock. I carichi incrementali fornitore restano in un modulo separato.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            if (_mgwsInventoryEnabled) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSmartTextFormField(
                      controller: _mgwsStockController,
                      fieldKey: const ValueKey('productMgwsStockField'),
                      label: 'Stock MGWS totale',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateMgwsStock,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSmartTextFormField(
                      controller: _mgwsReasonController,
                      fieldKey: const ValueKey('productMgwsReasonField'),
                      label: 'Motivo rettifica',
                      icon: Icons.fact_check_outlined,
                      validator: _validateMgwsReason,
                      required: true,
                    ),
                  ),
                ],
              ),
            ],
            if (_mgwsInventoryFeedbackText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feedbackColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: feedbackColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      feedbackSuccess
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      color: feedbackColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _mgwsInventoryFeedbackText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setMgwsInventoryEnabled(bool value) {
    setState(() {
      _mgwsInventoryEnabled = value;
      _mgwsInventoryFeedbackText = null;
      _mgwsInventoryFeedbackSuccess = null;
      if (value && _mgwsReasonController.text.trim().isEmpty) {
        _mgwsReasonController.text = _defaultMgwsInventoryReason();
      }
    });
  }

  String _defaultMgwsInventoryReason() {
    return _isUpdatingExisting
        ? 'Rettifica stock prodotto da app Flutter'
        : 'Stock iniziale prodotto da app Flutter';
  }

  String? _validateMgwsStock(String? value) {
    return validateProductMgwsStock(
      enabled: _mgwsInventoryEnabled,
      value: value,
    );
  }

  String? _validateMgwsReason(String? value) {
    return validateProductMgwsReason(
      enabled: _mgwsInventoryEnabled,
      value: value,
    );
  }

  ProductMgwsStockInput _buildMgwsStockInput() {
    return ProductMgwsStockInput(
      stockText: _mgwsStockController.text,
      reasonText: _mgwsReasonController.text,
    );
  }

  Widget _buildDettagli() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _productStatus,
                    decoration: const InputDecoration(
                      labelText: 'Stato prodotto',
                      isDense: true,
                    ),
                    items: _productStatusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _productStatus = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Descrizione Breve con pulsante IA
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSmartTextFormField(
                controller: _descrizioneBreveController,
                label: 'Descrizione Breve',
                icon: Icons.short_text,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                required: true,
              ),
            ),
            const SizedBox(width: 8),
            _buildAIButton(
              isLoading: _isGeneratingShortDesc,
              tooltip: 'Genera con IA',
              onPressed: _generateShortDescription,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Descrizione Completa con pulsante IA
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSmartTextFormField(
                controller: _descrizioneCompletaController,
                label: 'Descrizione Completa',
                icon: Icons.article,
                maxLines: 5,
              ),
            ),
            const SizedBox(width: 8),
            _buildAIButton(
              isLoading: _isGeneratingLongDesc,
              tooltip: 'Genera con IA',
              onPressed: _generateLongDescription,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildImageSelector(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCategorieField()),
            const SizedBox(width: 8),
            _buildAIButton(
              isLoading: _isGeneratingCategories,
              tooltip: 'Suggerisci categorie',
              onPressed: _generateCategories,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMarchioField(),
        const SizedBox(height: 16),
        if (_productType == ProductTypeSelection.simple)
          _buildSmartTextFormField(
            controller: _pesoController,
            label: 'Peso (kg)',
            icon: Icons.scale,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.scale_outlined),
              title: const Text('Peso per variante'),
              subtitle: const Text(
                'Per prodotti con varianti, il peso va impostato nel dettaglio della singola variante.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVarianti() {
    if (_productType == ProductTypeSelection.simple) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 40),
              const SizedBox(height: 10),
              Text(
                'Prodotto semplice selezionato',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Passa a "Con varianti" nel passo Prezzi e Stock per configurare varianti.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _aggiungiAttributoProdotto,
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi Attributo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _generaVariantiDaAttributi,
                      icon: const Icon(Icons.auto_awesome_motion),
                      label: const Text('Genera Varianti'),
                    ),
                  ],
                );
                final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Varianti Prodotto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_varianti.length} varianti configurate',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                );

                if (constraints.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 12), actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInserimentoRapidoVariante(),
        const SizedBox(height: 12),
        _buildAttributiProdottoComposer(),
        const SizedBox(height: 16),
        if (_varianti.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inventory, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna Variante',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi una variante rapida oppure configura gli attributi e genera le combinazioni.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          _buildTabellaVariantiGerarchica(),
      ],
    );
  }

  Widget _buildTabellaVariantiGerarchica() {
    final allIndexes = List<int>.generate(_varianti.length, (index) => index);
    final primaryAttribute = _preferredGroupingAttribute(allIndexes);
    if (primaryAttribute == null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildUngroupedVariantGridHeader(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Le varianti senza attributi non possono essere raggruppate.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            _buildVariantBlockRows(indexes: allIndexes),
          ],
        ),
      );
    }

    final secondaryAttribute = _preferredGroupingAttribute(
      allIndexes,
      excluding: primaryAttribute,
    );
    final primaryGroups = _groupVariantIndexesByAttribute(primaryAttribute);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildVariantGridHeader(
            primaryAttribute: primaryAttribute,
            secondaryAttribute: secondaryAttribute ?? 'Sottogruppo',
          ),
          const Divider(height: 1),
          ...primaryGroups.entries.map(
            (entry) => _buildPrimaryVariantBlock(
              primaryAttribute: primaryAttribute,
              primaryValue: entry.key,
              indexes: entry.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantGridHeader({
    String primaryAttribute = 'Attributo',
    String secondaryAttribute = 'Sottogruppo',
  }) {
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Varianti raggruppate per attributo', style: style),
          );
        }
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: Center(child: Text(primaryAttribute, style: style)),
              ),
              SizedBox(
                width: 200,
                child: Center(child: Text(secondaryAttribute, style: style)),
              ),
              Expanded(child: Text('Varianti', style: style)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUngroupedVariantGridHeader() {
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text('Varianti', style: style),
    );
  }

  Widget _buildPrimaryVariantBlock({
    required String primaryAttribute,
    required String primaryValue,
    required List<int> indexes,
  }) {
    final secondaryAttribute = _preferredGroupingAttribute(
      indexes,
      excluding: primaryAttribute,
    );
    final secondaryGroups = secondaryAttribute == null
        ? <String, List<int>>{'Senza valore': indexes}
        : _groupVariantIndexesByAttribute(secondaryAttribute, indexes: indexes);

    // The non-positioned content determines the height. The positioned cell
    // fills that exact height, including expanded variant details, without
    // IntrinsicHeight measuring ExpansionTile descendants.
    return LayoutBuilder(
      builder: (context, constraints) {
        final secondaryBlocks = secondaryGroups.entries
            .map(
              (entry) => _buildSecondaryVariantBlock(
                attributeName: secondaryAttribute,
                value: entry.key,
                indexes: entry.value,
              ),
            )
            .toList();
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMergedAttributeCell(
                title: '$primaryAttribute: $primaryValue',
                count: indexes.length,
                isPrimary: true,
              ),
              ...secondaryBlocks,
            ],
          );
        }
        return Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 220,
              child: _buildMergedAttributeCell(
                title: '$primaryAttribute: $primaryValue',
                count: indexes.length,
                isPrimary: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: secondaryBlocks,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryVariantBlock({
    required String? attributeName,
    required String value,
    required List<int> indexes,
  }) {
    final title = attributeName == null ? value : '$attributeName: $value';
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMergedAttributeCell(title: title, count: indexes.length),
              _buildVariantBlockRows(indexes: indexes),
            ],
          );
        }
        return Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 200,
              child: _buildMergedAttributeCell(
                title: title,
                count: indexes.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 200),
              child: _buildVariantBlockRows(indexes: indexes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMergedAttributeCell({
    required String title,
    required int count,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border(
          right: BorderSide(color: theme.dividerColor),
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'variante' : 'varianti'}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildVariantBlockRows({required List<int> indexes}) {
    return Column(children: indexes.map(_buildVariantCatalogRow).toList());
  }

  Widget _buildVariantCatalogRow(int index) {
    final variante = _varianti[index];
    final hasDiscount =
        variante.prezzoScontato != null && variante.prezzoScontato! > 0;
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    Widget property(String label, String value, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(value, style: valueStyle, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return Container(
      key: ValueKey(variante.uiKey),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) setState(() => _selectedVarianteIndex = index);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final image = SizedBox(
              width: 52,
              height: 52,
              child: _buildVarianteImageThumb(index, variante),
            );
            final sku = property(
              'SKU',
              variante.sku.isEmpty ? '—' : variante.sku,
              flex: 2,
            );
            final supplierSku = property(
              'SKU fornitore',
              variante.skuFornitore.isEmpty ? '—' : variante.skuFornitore,
              flex: 2,
            );
            final price = property(
              'Prezzo',
              '€ ${variante.prezzo.toStringAsFixed(2)}',
            );
            final discount = property(
              'Sconto',
              hasDiscount
                  ? '€ ${variante.prezzoScontato!.toStringAsFixed(2)}'
                  : '—',
            );
            final quantity = property('Quantità', '${variante.quantita}');

            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      image,
                      const SizedBox(width: 8),
                      sku,
                      supplierSku,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [price, discount, quantity]),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                image,
                const SizedBox(width: 8),
                sku,
                supplierSku,
                price,
                discount,
                quantity,
              ],
            );
          },
        ),
        children: [_buildVarianteDetails(index)],
      ),
    );
  }

  Map<String, List<int>> _groupVariantIndexesByAttribute(
    String attributeName, {
    List<int>? indexes,
  }) {
    final groups = <String, List<int>>{};
    for (final index
        in indexes ?? List<int>.generate(_varianti.length, (i) => i)) {
      final value = _attributeValue(_varianti[index], attributeName);
      groups.putIfAbsent(value ?? 'Senza valore', () => <int>[]).add(index);
    }
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map<String, List<int>>.fromEntries(sortedEntries);
  }

  String? _preferredGroupingAttribute(List<int> indexes, {String? excluding}) {
    final counts = <String, int>{};
    final displayNames = <String, String>{};
    for (final index in indexes) {
      for (final attribute in _varianti[index].attributi) {
        final name = attribute.nome.trim();
        if (name.isEmpty || attribute.opzione.trim().isEmpty) continue;
        final normalized = name.toLowerCase();
        if (normalized == excluding?.toLowerCase()) continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
        displayNames.putIfAbsent(normalized, () => name);
      }
    }
    if (counts.isEmpty) return null;

    const preferredOrder = ['colore', 'color', 'taglia', 'size'];
    for (final preferred in preferredOrder) {
      if (counts.containsKey(preferred)) return displayNames[preferred];
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final countComparison = counts[b]!.compareTo(counts[a]!);
        return countComparison != 0 ? countComparison : a.compareTo(b);
      });
    return displayNames[names.first];
  }

  String? _attributeValue(VarianteTemp variante, String attributeName) {
    for (final attribute in variante.attributi) {
      if (attribute.nome.trim().toLowerCase() == attributeName.toLowerCase()) {
        final value = attribute.opzione.trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  Widget _buildInserimentoRapidoVariante() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inserimento rapido variante',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Aggiungi una variante senza configurare prima gli attributi del prodotto.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: _buildSmartTextFormField(
                    controller: _quickVarianteSkuController,
                    label: 'SKU variante',
                    icon: Icons.qr_code,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _buildSmartTextFormField(
                    controller: _quickVarianteBarcodeController,
                    label: 'Codice a barre',
                    icon: Icons.qr_code_scanner,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _buildSmartTextFormField(
                    controller: _quickVarianteQuantitaController,
                    label: 'Quantità',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildSmartTextFormField(
                    controller: _quickVarianteTagliaController,
                    label: 'Taglia',
                    icon: Icons.straighten,
                    suggestions: _suggerimentiOpzioni['Taglia'],
                    enableCreateOption: true,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildSmartTextFormField(
                    controller: _quickVarianteColoreController,
                    label: 'Colore',
                    icon: Icons.palette_outlined,
                    suggestions: _suggerimentiOpzioni['Colore'],
                    enableCreateOption: true,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _aggiungiVarianteRapida,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi variante'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributiProdottoComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attributi del prodotto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Seleziona o scrivi nome attributo e scegli più valori. Il campo valori mostra i selezionati separati da virgola.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (_attributiProdottoSelezionati.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.tune, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nessun attributo configurato',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                _attributiProdottoSelezionati.length,
                (index) => _buildAttributoProdottoRow(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianteDetails(int index) {
    final variante = _varianti[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Dettagli variante #${index + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            _buildVarianteActionsMenu(index),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: variante.sku,
                onChanged: (value) => variante.sku = value,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  isDense: true,
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                focusNode: _barcodeFocusNodeFor(index),
                initialValue: variante.barcode,
                onChanged: (value) => _onBarcodeChanged(index, value),
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  isDense: true,
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              child: TextFormField(
                initialValue: variante.quantita.toString(),
                onChanged: (value) =>
                    variante.quantita = int.tryParse(value) ?? 0,
                decoration: const InputDecoration(
                  labelText: 'Quantità',
                  isDense: true,
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: variante.skuFornitore,
          onChanged: (value) => variante.skuFornitore = value,
          decoration: const InputDecoration(
            labelText: 'SKU fornitore',
            isDense: true,
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: variante.prezzo.toString(),
                onChanged: (value) =>
                    variante.prezzo = double.tryParse(value) ?? 0.0,
                decoration: const InputDecoration(
                  labelText: 'Prezzo',
                  prefixIcon: Icon(Icons.euro),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: variante.peso ?? '',
                onChanged: (value) =>
                    variante.peso = value.trim().isEmpty ? null : value.trim(),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  prefixIcon: Icon(Icons.scale),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAttributiVariante(variante, index),
      ],
    );
  }

  Widget _buildVarianteActionsMenu(int index) {
    return PopupMenuButton(
      tooltip: 'Azioni variante',
      icon: const Icon(Icons.more_horiz),
      itemBuilder: (context) => [
        if (index > 0)
          PopupMenuItem(
            onTap: () => _spostaVariante(index, -1),
            child: const Text('Sposta su'),
          ),
        if (index < _varianti.length - 1)
          PopupMenuItem(
            onTap: () => _spostaVariante(index, 1),
            child: const Text('Sposta giù'),
          ),
        PopupMenuItem(
          onTap: () => _duplicaVariante(index),
          child: const Text('Duplica'),
        ),
        PopupMenuItem(
          onTap: () => _rimuoviVariante(index),
          child: const Text('Elimina'),
        ),
      ],
    );
  }

  Widget _buildVarianteImageThumb(int varianteIndex, VarianteTemp variante) {
    final imageUrl = resolveImageUrl(variante.immagineUrl);

    return InkWell(
      onTap: () async {
        final selectedMedia = await showMediaSelector(
          context,
          showDimensionWarnings: _showImageDimensionWarnings,
          warningThresholdWidth: _imageWarningThresholdWidth,
          warningThresholdHeight: _imageWarningThresholdHeight,
        );
        if (selectedMedia == null || !mounted) return;
        setState(() {
          _varianti[varianteIndex].immagineUrl = selectedMedia.url;
        });
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(Icons.add_a_photo_outlined)
            : ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 144,
                  cacheHeight: 144,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
      ),
    );
  }

  Widget _buildAttributiVariante(VarianteTemp variante, int varianteIndex) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                Text(
                  'Variante #${varianteIndex + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                      Icon(Icons.tune, size: 32, color: Colors.grey[400]),
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
                (attrIndex) => _buildAttributoItem(
                  variante.attributi[attrIndex],
                  varianteIndex,
                  attrIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributoItem(
    AttributoVariante attributo,
    int varianteIndex,
    int attrIndex,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: attributo.nome,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nome Attributo',
                isDense: true,
                prefixIcon: Icon(Icons.tune),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: attributo.opzione,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Opzione',
                isDense: true,
                prefixIcon: Icon(Icons.format_list_bulleted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    final immagineUrl = (resolveImageUrl(_immagineUrlController.text) ?? '')
        .trim();
    final hasImage = immagineUrl.isNotEmpty;

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
                      immagineUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 720,
                      cacheHeight: 400,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey[600],
                              ),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                          final selectedMedia = await showMediaSelector(
                            context,
                            showDimensionWarnings: _showImageDimensionWarnings,
                            warningThresholdWidth: _imageWarningThresholdWidth,
                            warningThresholdHeight:
                                _imageWarningThresholdHeight,
                          );
                          if (selectedMedia != null && mounted) {
                            setState(() {
                              _immagineUrlController.text = selectedMedia.url;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: Text(
                          hasImage
                              ? 'Cambia Immagine'
                              : 'Seleziona da Libreria',
                        ),
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final customColors = Theme.of(
                            context,
                          ).extension<AppColorExtension>()!;
                          return OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _immagineUrlController.clear();
                              });
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: customColors.errorColorStatus,
                            ),
                            label: Text(
                              'Rimuovi',
                              style: TextStyle(
                                color: customColors.errorColorStatus,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildImageSetOptions(
                  config: _mainImageConfig,
                  title: 'Immagine principale',
                  setImages: _mainImageSetUrls,
                  onAddSetImage: () async {
                    final selectedMedia = await showMediaSelector(
                      context,
                      showDimensionWarnings: _showImageDimensionWarnings,
                      warningThresholdWidth: _imageWarningThresholdWidth,
                      warningThresholdHeight: _imageWarningThresholdHeight,
                    );
                    if (selectedMedia == null || !mounted) return;
                    setState(() {
                      if (!_mainImageSetUrls.contains(selectedMedia.url)) {
                        _mainImageSetUrls.add(selectedMedia.url);
                      }
                    });
                  },
                  onRemoveSetImage: (url) {
                    setState(() {
                      _mainImageSetUrls.remove(url);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSetOptions({
    required ProductImageUiConfig config,
    required String title,
    List<String>? setImages,
    Future<void> Function()? onAddSetImage,
    void Function(String)? onRemoveSetImage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title - set immagini',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: config.isSetMode,
                    onChanged: (value) {
                      setState(() {
                        config.isSetMode = value ?? false;
                      });
                    },
                  ),
                  const Text('Set immagini'),
                ],
              ),
            ],
          ),
          if (config.isSetMode && setImages != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: setImages
                        .map(
                          (url) => InputChip(
                            label: Text(
                              url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: onRemoveSetImage == null
                                ? null
                                : () => onRemoveSetImage(url),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (onAddSetImage != null)
                  IconButton(
                    tooltip: 'Aggiungi immagine al set',
                    onPressed: () {
                      onAddSetImage();
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
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
                          if (value.trim().isNotEmpty &&
                              !_tags.contains(value.trim())) {
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
                    children: _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _saveProgressLabel.isEmpty
                  ? 'Salvataggio in corso...'
                  : _saveProgressLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _saveProgress),
          ],
        ),
      ),
    );
  }

  void _updateSaveProgress(double value, String label) {
    if (!mounted) return;
    setState(() {
      _saveProgress = value.clamp(0.0, 1.0);
      _saveProgressLabel = label;
    });
  }

  Widget _buildSmartTextFormField({
    Key? fieldKey,
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
    bool enableCreateOption = false,
    void Function(String)? onCreateOption,
    String createOptionText = '+ Crea nuovo',
  }) {
    // Se non è fornito un controller, usa initialValue direttamente (senza controller)
    // Questo evita problemi con il testo che si scrive al contrario

    if (suggestions != null || enableCreateOption) {
      final sourceSuggestions = suggestions ?? const <String>[];
      String lastAutocompleteQuery = '';
      // Con autocompletamento
      return Autocomplete<String>(
        displayStringForOption: (option) {
          if (enableCreateOption && option == createOptionText) {
            return lastAutocompleteQuery;
          }
          return option;
        },
        initialValue: TextEditingValue(text: initialValue ?? ''),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable.empty();
          final query = textEditingValue.text.trim();
          lastAutocompleteQuery = query;
          final filtered = sourceSuggestions.where(
            (option) => option.toLowerCase().contains(query.toLowerCase()),
          );

          final exactExists = sourceSuggestions.any(
            (option) => option.toLowerCase() == query.toLowerCase(),
          );

          if (enableCreateOption && query.isNotEmpty && !exactExists) {
            return <String>[...filtered, createOptionText];
          }

          return filtered;
        },
        onSelected: (selection) {
          if (enableCreateOption && selection == createOptionText) {
            final created = lastAutocompleteQuery.trim();
            if (created.isEmpty) {
              return;
            }
            // Esegue l'azione di creazione senza sostituire il testo digitato
            if (controller != null && controller.text != created) {
              controller.text = created;
              controller.selection = TextSelection.collapsed(
                offset: created.length,
              );
            }
            onCreateOption?.call(created);
            onChanged?.call(created);
            return;
          }
          if (controller != null && controller.text != selection) {
            controller.text = selection;
            controller.selection = TextSelection.collapsed(
              offset: selection.length,
            );
          }
          onChanged?.call(selection);
        },
        fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
          // Con autocomplete, usa sempre il controller interno per non rompere il filtering.
          final seedText = controller?.text ?? initialValue ?? '';
          if (fieldController.text.isEmpty && seedText.isNotEmpty) {
            fieldController.text = seedText;
            fieldController.selection = TextSelection.collapsed(
              offset: seedText.length,
            );
          }

          return TextFormField(
            key: fieldKey,
            controller: fieldController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixText: suffix,
            ),
            validator: validator,
            onChanged: (value) {
              if (controller != null && controller.text != value) {
                controller.text = value;
                controller.selection = TextSelection.collapsed(
                  offset: value.length,
                );
              }
              onChanged?.call(value);
            },
            onFieldSubmitted: (value) {
              final created = value.trim();
              final alreadyExists = sourceSuggestions.any(
                (option) => option.toLowerCase() == created.toLowerCase(),
              );
              if (!enableCreateOption || created.isEmpty || alreadyExists) {
                return;
              }

              if (controller != null && controller.text != created) {
                controller.text = created;
                controller.selection = TextSelection.collapsed(
                  offset: created.length,
                );
              }
              onCreateOption?.call(created);
              onChanged?.call(created);
              focusNode.unfocus();
            },
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
          );
        },
      );
    }

    // Senza autocompletamento - usa initialValue direttamente
    return TextFormField(
      key: fieldKey,
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

  Widget _buildCategorieField() {
    return TextFormField(
      controller: _categoriaController,
      readOnly: true,
      onTap: _apriSelettoreCategorie,
      validator: (value) =>
          _categorieSelezionate.isEmpty ? 'Campo obbligatorio' : null,
      decoration: const InputDecoration(
        labelText: 'Categorie *',
        prefixIcon: Icon(Icons.category),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildMarchioField() {
    return DropdownSearch<String>(
      selectedItem: _marcaController.text.trim().isEmpty
          ? null
          : _marcaController.text.trim(),
      items: (filter, _) async {
        final query = filter.trim();
        final items = _suggerimentiMarca.toSet().toList()..sort();
        final filtered = query.isEmpty
            ? items
            : items
                  .where(
                    (item) => item.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
        final exists = items.any(
          (item) => item.toLowerCase() == query.toLowerCase(),
        );
        if (query.isNotEmpty && !exists) {
          filtered.add(_brandCreateOptionLabel(query));
        }
        return filtered;
      },
      compareFn: (item1, item2) => item1 == item2,
      onSelected: (value) {
        if (value == null) return;
        final createdValue = _extractCreatedBrandValue(value);
        setState(() {
          _marcaController.text = createdValue ?? value;
          final normalized = _marcaController.text.trim();
          if (normalized.isNotEmpty &&
              !_suggerimentiMarca.any(
                (item) => item.toLowerCase() == normalized.toLowerCase(),
              )) {
            _suggerimentiMarca.add(normalized);
            _suggerimentiMarca.sort();
          }
        });
      },
      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Marchio',
          prefixIcon: Icon(Icons.branding_watermark_outlined),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        fit: FlexFit.loose,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Cerca o scrivi un nuovo marchio',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      suffixProps: DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(
          isVisible: _marcaController.text.trim().isNotEmpty,
        ),
      ),
      onClear: () {
        setState(() {
          _marcaController.clear();
        });
      },
    );
  }

  Future<void> _apriSelettoreCategorie() async {
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Categorie prodotto',
      inputLabel: 'Filtra o nuova categoria',
      input_list: _suggerimentiCategoria,
      preselected_list: _categorieSelezionate,
    );

    if (selected == null || !mounted) return;

    setState(() {
      _categorieSelezionate = List<String>.from(selected)..sort();
      _categoriaController.text = _categorieSelezionate.join(', ');
      for (final categoria in _categorieSelezionate) {
        if (!_suggerimentiCategoria.any(
          (item) => item.toLowerCase() == categoria.toLowerCase(),
        )) {
          _suggerimentiCategoria.add(categoria);
        }
      }
      _suggerimentiCategoria.sort();
    });
  }

  String _brandCreateOptionLabel(String value) => '+ CREA: $value';

  String? _extractCreatedBrandValue(String value) {
    if (!value.startsWith('+ CREA: ')) return null;
    final created = value.substring('+ CREA: '.length).trim();
    return created.isEmpty ? null : created;
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

  void _syncBarcodeFocusNodes() {
    while (_barcodeFocusNodes.length < _varianti.length) {
      _barcodeFocusNodes.add(FocusNode());
    }
    while (_barcodeFocusNodes.length > _varianti.length) {
      _barcodeFocusNodes.removeLast().dispose();
    }
  }

  FocusNode _barcodeFocusNodeFor(int index) {
    _syncBarcodeFocusNodes();
    return _barcodeFocusNodes[index];
  }

  void _onBarcodeChanged(int varianteIndex, String value) {
    _varianti[varianteIndex].barcode = value;

    final previous = _barcodePreviousValues[varianteIndex] ?? '';
    _barcodePreviousValues[varianteIndex] = value;
    final jump = value.length - previous.length;

    final looksLikeScannerShot =
        value.isNotEmpty &&
        (previous.isEmpty && value.length >= 6 || jump >= 4);
    if (!looksLikeScannerShot) return;

    final next = varianteIndex + 1;
    if (next >= _varianti.length) return;

    setState(() {
      _selectedVarianteIndex = next;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_barcodeFocusNodeFor(next));
    });
  }

  Widget _buildAttributoProdottoRow(int index) {
    final attributo = _attributiProdottoSelezionati[index];
    final attrKey = attributo.nome.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSmartTextFormField(
              controller: attributo.nomeController,
              label: 'Nome Attributo',
              icon: Icons.tune,
              suggestions: _suggerimentiAttributi,
              enableCreateOption: true,
              createOptionText: '+ CREA NUOVO',
              onCreateOption: (value) {
                final normalized = value.trim();
                if (normalized.isEmpty) return;
                setState(() {
                  if (!_suggerimentiAttributi.any(
                    (s) => s.toLowerCase() == normalized.toLowerCase(),
                  )) {
                    _suggerimentiAttributi.add(normalized);
                    _suggerimentiAttributi.sort();
                  }
                  attributo.nomeController.text = normalized;
                });
              },
              onChanged: (value) {
                setState(() {
                  attributo.nomeController.text = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: attributo.valoriController,
              readOnly: true,
              onTap: () => _apriSelettoreValoriAttributo(index),
              decoration: const InputDecoration(
                labelText: 'Valori',
                prefixIcon: Icon(Icons.checklist),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Rimuovi attributo',
            onPressed: () => _rimuoviAttributoProdotto(index),
            icon: const Icon(Icons.delete_outline),
          ),
          if (attrKey.isNotEmpty)
            IconButton(
              tooltip: 'Scegli valori',
              onPressed: () => _apriSelettoreValoriAttributo(index),
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
            ),
        ],
      ),
    );
  }

  void _aggiungiAttributoProdotto() {
    setState(() {
      _attributiProdottoSelezionati.add(AttributoProdottoSelezionato());
    });
  }

  void _rimuoviAttributoProdotto(int index) {
    setState(() {
      _attributiProdottoSelezionati[index].dispose();
      _attributiProdottoSelezionati.removeAt(index);
    });
  }

  Future<void> _apriSelettoreValoriAttributo(int index) async {
    final attributo = _attributiProdottoSelezionati[index];
    final attrName = attributo.nome.trim();

    final selected = await SearchableCheckboxDialog.show(
      context,
      title: attrName.isEmpty ? 'Valori attributo' : 'Valori $attrName',
      inputLabel: 'Filtra o nuovo valore',
      input_list: _suggerimentiOpzioni[attrName] ?? const <String>[],
      preselected_list: attributo.valori,
    );

    if (selected == null || !mounted) return;

    setState(() {
      attributo.setValori(selected);
      if (attrName.isNotEmpty) {
        final options = _suggerimentiOpzioni.putIfAbsent(
          attrName,
          () => <String>[],
        );
        for (final value in selected) {
          if (!options.any((s) => s.toLowerCase() == value.toLowerCase())) {
            options.add(value);
          }
        }
        options.sort();
      }
    });
  }

  void _aggiungiVarianteRapida() {
    final taglia = _quickVarianteTagliaController.text.trim();
    final colore = _quickVarianteColoreController.text.trim();
    if (taglia.isEmpty && colore.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Inserisci almeno taglia o colore per la variante rapida.',
      );
      return;
    }

    final attributi = <AttributoVariante>[
      if (taglia.isNotEmpty) AttributoVariante(nome: 'Taglia', opzione: taglia),
      if (colore.isNotEmpty) AttributoVariante(nome: 'Colore', opzione: colore),
    ];
    final comboKey = VariantCombinations.key(attributi);
    if (_varianti.any(
      (variante) => VariantCombinations.key(variante.attributi) == comboKey,
    )) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'La variante ${_buildAttributeSummary(attributi)} è già presente.',
      );
      return;
    }

    setState(() {
      _varianti.add(
        VarianteTemp(
          nome: 'Variante ${_varianti.length + 1}',
          sku: _quickVarianteSkuController.text.trim(),
          barcode: _quickVarianteBarcodeController.text.trim(),
          prezzo: double.tryParse(_prezzoNormaleController.text) ?? 0.0,
          quantita: int.tryParse(_quickVarianteQuantitaController.text) ?? 0,
          peso: _pesoController.text.trim().isEmpty
              ? null
              : _pesoController.text.trim(),
          imageConfig: _newImageConfigFromDefaults(),
          attributi: attributi,
        ),
      );
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = _varianti.length - 1;
      _quickVarianteSkuController.clear();
      _quickVarianteBarcodeController.clear();
      _quickVarianteQuantitaController.text = '0';
      _quickVarianteTagliaController.clear();
      _quickVarianteColoreController.clear();
    });

    NotificationService.instance.messageBar(
      'successo',
      'prodotti_crea',
      'Variante ${_buildAttributeSummary(attributi)} aggiunta.',
    );
  }

  String _buildAttributeSummary(List<AttributoVariante> attributes) {
    return attributes.map((attr) => '${attr.nome}: ${attr.opzione}').join(', ');
  }

  void _generaVariantiDaAttributi() {
    final attributiValidi = _buildAttributiProdottoValidi();
    if (attributiValidi.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Aggiungi almeno un attributo con uno o più valori.',
      );
      return;
    }

    final combinazioni = VariantCombinations.generate(attributiValidi);
    if (combinazioni.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Nessuna combinazione generata.',
      );
      return;
    }

    final chiaviEsistenti = _varianti
        .map((variante) => VariantCombinations.key(variante.attributi))
        .where((chiave) => chiave.isNotEmpty)
        .toSet();
    final combinazioniNuove = <List<AttributoVariante>>[];

    for (final combinazione in combinazioni) {
      final chiave = VariantCombinations.key(combinazione);
      if (chiave.isEmpty || !chiaviEsistenti.add(chiave)) continue;
      combinazioniNuove.add(combinazione);
    }

    if (combinazioniNuove.isEmpty) {
      NotificationService.instance.messageBar(
        'successo',
        'prodotti_crea',
        'Tutte le combinazioni generate sono già associate al prodotto.',
      );
      return;
    }

    setState(() {
      final firstNewVariantIndex = _varianti.length;
      _varianti.addAll(
        combinazioniNuove.asMap().entries.map((entry) {
          final index = entry.key;
          final attributi = entry.value;
          return VarianteTemp(
            nome: 'Variante ${firstNewVariantIndex + index + 1}',
            sku: '',
            barcode: '',
            prezzo: double.tryParse(_prezzoNormaleController.text) ?? 0.0,
            quantita: 0,
            peso: _pesoController.text.trim().isEmpty
                ? null
                : _pesoController.text.trim(),
            imageConfig: _newImageConfigFromDefaults(),
            attributi: attributi,
          );
        }),
      );
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = firstNewVariantIndex;
      for (final attributo in _attributiProdottoSelezionati) {
        attributo.dispose();
      }
      _attributiProdottoSelezionati = [];
    });

    NotificationService.instance.messageBar(
      'successo',
      'prodotti_crea',
      'Generate ${combinazioniNuove.length} nuove varianti.',
    );
  }

  void _duplicaVariante(int index) {
    final variante = _varianti[index];
    setState(() {
      _varianti.insert(
        index + 1,
        VarianteTemp(
          nome: '${variante.nome} (Copia)',
          sku: '${variante.sku}_copy',
          skuFornitore: variante.skuFornitore,
          barcode: variante.barcode,
          prezzo: variante.prezzo,
          quantita: variante.quantita,
          peso: variante.peso,
          immagineUrl: variante.immagineUrl,
          imageSetUrls: List<String>.from(variante.imageSetUrls),
          imageConfig: variante.imageConfig.copy(),
          metadatiCustom: variante.metadatiCustom == null
              ? null
              : Map<String, dynamic>.from(variante.metadatiCustom!),
          attributi: variante.attributi
              .map(
                (attr) => AttributoVariante(
                  nome: attr.nome,
                  opzione: attr.opzione,
                  valore: attr.valore,
                ),
              )
              .toList(),
        ),
      );
      _syncBarcodeFocusNodes();
    });
  }

  void _spostaVariante(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _varianti.length) return;

    setState(() {
      final item = _varianti.removeAt(index);
      _varianti.insert(newIndex, item);
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = newIndex;
    });
  }

  void _rimuoviVariante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare la variante "${_varianti[index].nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _varianti.removeAt(index);
                _syncBarcodeFocusNodes();
                if (_varianti.isEmpty) {
                  _selectedVarianteIndex = null;
                } else if (_selectedVarianteIndex != null) {
                  if (_selectedVarianteIndex == index) {
                    _selectedVarianteIndex = 0;
                  } else if (_selectedVarianteIndex! > index) {
                    _selectedVarianteIndex = _selectedVarianteIndex! - 1;
                  }
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).extension<AppColorExtension>()!.errorColorStatus,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  // Widget pulsante IA
  Widget _buildAIButton({
    required bool isLoading,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  // Metodi per generazione IA
  Future<void> _generateShortDescription() async {
    if (_nomeController.text.trim().isEmpty) {
      _showAIError('Inserisci prima il nome del prodotto');
      return;
    }

    setState(() => _isGeneratingShortDesc = true);
    try {
      final settings = AppSettings();
      await settings.init();
      final aiService = AIService(settings);

      final description = await aiService.generateProductDescription(
        productName: _nomeController.text.trim(),
        category: _categoriaController.text.trim().isNotEmpty
            ? _categoriaController.text.trim()
            : null,
        price: _prezzoNormaleController.text.trim().isNotEmpty
            ? _prezzoNormaleController.text.trim()
            : null,
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        shortDescription: true,
      );

      setState(() {
        _descrizioneBreveController.text = description;
      });
    } catch (e) {
      _showAIError(e.toString());
    } finally {
      setState(() => _isGeneratingShortDesc = false);
    }
  }

  Future<void> _generateLongDescription() async {
    if (_nomeController.text.trim().isEmpty) {
      _showAIError('Inserisci prima il nome del prodotto');
      return;
    }

    setState(() => _isGeneratingLongDesc = true);
    try {
      final settings = AppSettings();
      await settings.init();
      final aiService = AIService(settings);

      final description = await aiService.generateProductDescription(
        productName: _nomeController.text.trim(),
        category: _categoriaController.text.trim().isNotEmpty
            ? _categoriaController.text.trim()
            : null,
        price: _prezzoNormaleController.text.trim().isNotEmpty
            ? _prezzoNormaleController.text.trim()
            : null,
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        shortDescription: false,
      );

      setState(() {
        _descrizioneCompletaController.text = description;
      });
    } catch (e) {
      _showAIError(e.toString());
    } finally {
      setState(() => _isGeneratingLongDesc = false);
    }
  }

  Future<void> _generateCategories() async {
    if (_nomeController.text.trim().isEmpty) {
      _showAIError('Inserisci prima il nome del prodotto');
      return;
    }

    setState(() => _isGeneratingCategories = true);
    try {
      final settings = AppSettings();
      await settings.init();
      final aiService = AIService(settings);

      final categories = await aiService.suggestCategories(
        productName: _nomeController.text.trim(),
        description: _descrizioneBreveController.text.trim().isNotEmpty
            ? _descrizioneBreveController.text.trim()
            : null,
      );

      if (categories.isNotEmpty) {
        // Mostra dialog per selezione categorie
        if (mounted) {
          final selected = await SearchableCheckboxDialog.show(
            context,
            title: 'Categorie suggerite',
            inputLabel: 'Filtra o nuova categoria',
            input_list: categories,
            preselected_list: _categorieSelezionate,
          );

          if (selected != null && selected.isNotEmpty) {
            setState(() {
              _categorieSelezionate = List<String>.from(selected)..sort();
              _categoriaController.text = _categorieSelezionate.join(', ');
              for (final categoria in _categorieSelezionate) {
                if (!_suggerimentiCategoria.any(
                  (item) => item.toLowerCase() == categoria.toLowerCase(),
                )) {
                  _suggerimentiCategoria.add(categoria);
                }
              }
              _suggerimentiCategoria.sort();
            });
          }
        }
      }
    } catch (e) {
      _showAIError(e.toString());
    } finally {
      setState(() => _isGeneratingCategories = false);
    }
  }

  Future<void> _generateTags() async {
    if (_nomeController.text.trim().isEmpty) {
      _showAIError('Inserisci prima il nome del prodotto');
      return;
    }

    setState(() => _isGeneratingTags = true);
    try {
      final settings = AppSettings();
      await settings.init();
      final aiService = AIService(settings);

      final suggestedTags = await aiService.suggestTags(
        productName: _nomeController.text.trim(),
        description: _descrizioneBreveController.text.trim().isNotEmpty
            ? _descrizioneBreveController.text.trim()
            : null,
        category: _categoriaController.text.trim().isNotEmpty
            ? _categoriaController.text.trim()
            : null,
      );

      if (suggestedTags.isNotEmpty && mounted) {
        // Mostra dialog per selezione tag
        final selectedTags = await SearchableCheckboxDialog.show(
          context,
          title: 'Tag Suggeriti',
          inputLabel: 'Filtra o nuovo tag',
          input_list: suggestedTags,
          preselected_list: _tags,
        );

        if (selectedTags != null && selectedTags.isNotEmpty) {
          setState(() {
            for (final tag in selectedTags) {
              if (!_tags.contains(tag)) {
                _tags.add(tag);
              }
            }
          });
        }
      }
    } catch (e) {
      _showAIError(e.toString());
    } finally {
      setState(() => _isGeneratingTags = false);
    }
  }

  void _showAIError(String message) {
    if (!mounted) return;
    NotificationService.instance.messageBar('errore', 'prodotti_crea', message);
  }

  void _salvaProdotto() async {
    if (!_formKey.currentState!.validate()) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Controlla i campi obbligatori',
      );
      return;
    }

    if (_prodottiController == null) {
      NotificationService.instance.messageBar(
        'errore',
        'prodotti_crea',
        'Impossibile salvare in modalità offline',
      );
      return;
    }

    if (_productType == ProductTypeSelection.variable && _varianti.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Aggiungi almeno una variante per il prodotto variabile.',
      );
      return;
    }

    final validationError = _validateVariantiBeforeSave();
    if (validationError != null) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        validationError,
      );
      return;
    }

    if (_isUpdatingExisting) {
      final confirmed = await NotificationRecapDialog.edit(
        context,
        changes: [
          _nomeController.text.trim().isEmpty
              ? 'Prodotto senza nome'
              : _nomeController.text.trim(),
          'Tipo: ${_productType == ProductTypeSelection.variable ? 'variabile' : 'semplice'}',
          if (_varianti.isNotEmpty) '${_varianti.length} varianti configurate',
        ],
        affectedItemsCount: 1,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _isLoading = true;
      _saveProgress = 0.05;
      _saveProgressLabel = 'Validazione dati...';
    });

    try {
      _updateSaveProgress(0.2, 'Preparazione payload...');
      final prodotto = _creaProdottoDaForm();
      log.d(
        'PCREA_SAVE_START mode=${_isUpdatingExisting ? 'update' : 'create'} productId=${prodotto.id} sku=${prodotto.sku} expectedVariants=${prodotto.varianti?.length ?? 0}',
      );

      // Usa salvaProductoConVarianti per gestire sia il prodotto che le varianti
      _updateSaveProgress(0.45, 'Salvataggio prodotto e varianti...');
      final savedProduct = await _prodottiController!.salvaProductoConVarianti(
        prodotto,
      );
      log.d(
        'PCREA_SAVE_DONE savedProductId=${savedProduct.id} sku=${savedProduct.sku}',
      );

      ProductMgwsStockFeedback? mgwsFeedback;
      if (_mgwsInventoryEnabled) {
        _updateSaveProgress(0.65, 'Registrazione stock MGWS...');
        mgwsFeedback = await _prodottiController!.reconcileMgwsStockAfterSave(
          savedProduct: savedProduct,
          input: _buildMgwsStockInput(),
        );
        if (mounted) {
          setState(() {
            _mgwsInventoryFeedbackText = mgwsFeedback!.message;
            _mgwsInventoryFeedbackSuccess = mgwsFeedback.success;
          });
        }
        log.d(
          'PCREA_MGWS_RECONCILE_DONE success=${mgwsFeedback.success} productId=${savedProduct.id}',
        );
      }

      final verify = await _verificaPersistenzaProdotto(
        expected: prodotto,
        saved: savedProduct,
      );
      _updateSaveProgress(1.0, 'Completato');

      if (mounted) {
        final isFullSuccess = verify.productExists && verify.variantsComplete;
        final mgwsOk = mgwsFeedback?.success ?? true;
        final message = [
          _buildVerifyMessage(verify),
          if (mgwsFeedback != null) mgwsFeedback.message,
          if (mgwsFeedback != null && mgwsFeedback.details.isNotEmpty)
            mgwsFeedback.details.join(' '),
        ].join(' ');
        NotificationService.instance.messageBar(
          isFullSuccess && mgwsOk ? 'successo' : 'partial',
          'prodotti_crea',
          message,
        );
        if (isFullSuccess && mgwsOk) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      _updateSaveProgress(1.0, 'Errore durante il salvataggio');
      if (mounted) {
        final errorMessage = e.toString();
        NotificationService.instance.messageBar(
          'errore',
          'prodotti_crea',
          errorMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateVariantiBeforeSave() {
    if (_productType == ProductTypeSelection.simple) {
      return null;
    }

    if (_varianti.isEmpty) {
      return 'Aggiungi almeno una variante.';
    }

    final seenComboKeys = <String>{};
    final seenSkus = <String>{};

    for (int vIndex = 0; vIndex < _varianti.length; vIndex++) {
      final variante = _varianti[vIndex];
      int validAttributePairs = 0;

      for (int aIndex = 0; aIndex < variante.attributi.length; aIndex++) {
        final attr = variante.attributi[aIndex];
        final nome = attr.nome.trim();
        final opzione = attr.opzione.trim();

        if (nome.isEmpty && opzione.isEmpty) continue;
        if (nome.isEmpty && opzione.isNotEmpty) {
          return 'Variante ${vIndex + 1}, attributo ${aIndex + 1}: nome attributo mancante.';
        }
        if (nome.isNotEmpty && opzione.isEmpty) {
          return 'Variante ${vIndex + 1}, attributo ${aIndex + 1}: valore mancante.';
        }
        validAttributePairs++;
      }

      if (validAttributePairs == 0) {
        return 'Variante ${vIndex + 1}: aggiungi almeno un attributo valido oppure rimuovi la variante.';
      }

      final comboKey = VariantCombinations.key(variante.attributi);
      if (comboKey.isNotEmpty) {
        if (seenComboKeys.contains(comboKey)) {
          return 'Variante ${vIndex + 1}: questa combinazione esiste già.';
        }
        seenComboKeys.add(comboKey);
      }

      final normalizedSku = variante.sku.trim().toLowerCase();
      if (normalizedSku.isNotEmpty) {
        if (seenSkus.contains(normalizedSku)) {
          return 'Variante ${vIndex + 1}: SKU duplicato (${variante.sku.trim()}).';
        }
        seenSkus.add(normalizedSku);
      }
    }
    return null;
  }

  Future<_PcreaVerifyResult> _verificaPersistenzaProdotto({
    required ProdottoGlobal expected,
    required ProdottoGlobal saved,
  }) async {
    final requestedVariants =
        expected.varianti ?? const <VarianteProductGlobal>[];
    final savedProductId = saved.id ?? 0;

    if (_prodottiController == null || savedProductId <= 0) {
      log.e(
        'PCREA_VERIFY_FAIL reason=invalid-controller-or-product-id savedProductId=$savedProductId',
      );
      return const _PcreaVerifyResult(
        productExists: false,
        variantsComplete: false,
        expectedVariants: 0,
        foundVariants: 0,
        missingSkus: <String>[],
      );
    }

    log.d(
      'PCREA_VERIFY_START productId=$savedProductId expectedVariants=${requestedVariants.length}',
    );

    bool productExists = false;
    try {
      final productFromServer = await _prodottiController!.getProductById(
        savedProductId,
      );
      productExists = (productFromServer.id ?? 0) > 0;
      log.d(
        'PCREA_VERIFY_PRODUCT_EXISTS productId=$savedProductId exists=$productExists',
      );
    } catch (e) {
      log.e(
        'PCREA_VERIFY_PRODUCT_EXISTS_FAIL productId=$savedProductId error=$e',
      );
      productExists = false;
    }

    List<VarianteProductGlobal> serverVariants =
        const <VarianteProductGlobal>[];
    try {
      serverVariants = await _prodottiController!.getAllVarianti(
        savedProductId,
      );
      log.d(
        'PCREA_VERIFY_VARIANTS_EXISTS productId=$savedProductId expected=${requestedVariants.length} found=${serverVariants.length}',
      );
    } catch (e) {
      log.e(
        'PCREA_VERIFY_VARIANTS_EXISTS_FAIL productId=$savedProductId error=$e',
      );
    }

    final expectedSkus = requestedVariants
        .map((v) => (v.sku).trim().toLowerCase())
        .where((sku) => sku.isNotEmpty)
        .toSet();

    final foundSkus = serverVariants
        .map((v) => (v.sku).trim().toLowerCase())
        .where((sku) => sku.isNotEmpty)
        .toSet();

    final missingSkus =
        expectedSkus.where((sku) => !foundSkus.contains(sku)).toList()..sort();

    final variantsComplete = requestedVariants.isEmpty
        ? true
        : (missingSkus.isEmpty &&
              serverVariants.length >= requestedVariants.length);

    if (missingSkus.isNotEmpty) {
      log.e(
        'PCREA_VERIFY_MISSING_VARIANTS productId=$savedProductId missingSkus=${missingSkus.join(',')}',
      );
    }

    return _PcreaVerifyResult(
      productExists: productExists,
      variantsComplete: variantsComplete,
      expectedVariants: requestedVariants.length,
      foundVariants: serverVariants.length,
      missingSkus: missingSkus,
    );
  }

  String _buildVerifyMessage(_PcreaVerifyResult verify) {
    final action = _isUpdatingExisting ? 'aggiornato' : 'creato';
    if (verify.productExists && verify.variantsComplete) {
      return 'Prodotto $action e verificato (${verify.foundVariants}/${verify.expectedVariants} varianti trovate).';
    }
    if (!verify.productExists) {
      return 'Salvataggio eseguito ma verifica fallita: prodotto non trovato lato server.';
    }
    if (verify.missingSkus.isEmpty) {
      return 'Prodotto salvato, ma verifica varianti incompleta (${verify.foundVariants}/${verify.expectedVariants}).';
    }
    return 'Prodotto salvato, ma mancano ${verify.missingSkus.length} varianti: ${verify.missingSkus.join(', ')}';
  }

  ProdottoGlobal _creaProdottoDaForm() {
    final isVariable = _productType == ProductTypeSelection.variable;
    final productStatus = _normalizeProductStatus(_productStatus);
    final attributiProdotto = _buildAttributiProdottoDaSalvare();
    final categorie =
        _categorieSelezionate
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final variantiPulite = _varianti
        .map((temp) {
          final attributiPuliti = temp.attributi
              .map(
                (a) =>
                    a.copyWith(nome: a.nome.trim(), opzione: a.opzione.trim()),
              )
              .where((a) => a.nome.isNotEmpty && a.opzione.isNotEmpty)
              .toList();
          return temp.toVarianteProductGlobal(
            attributiOverride: attributiPuliti,
          );
        })
        .where((v) => v.attributi.isNotEmpty)
        .toList();

    return ProdottoGlobal(
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
      immaginiAggiuntive: _mainImageConfig.isSetMode
          ? List<String>.from(_mainImageSetUrls)
          : [],
      categoria: categorie
          .map(
            (categoria) => CategoriaProdotto(
              id: 0,
              nome: categoria,
              slug: categoria.toLowerCase().replaceAll(' ', '-'),
            ),
          )
          .toList(),
      peso: isVariable
          ? null
          : (_pesoController.text.trim().isEmpty
                ? null
                : _pesoController.text.trim()),
      quantitaTotale: isVariable
          ? 0
          : (int.tryParse(_quantitaController.text) ?? 0),
      inStock: isVariable ? false : _inStock,
      marca: _marcaController.text.trim().isEmpty
          ? null
          : _marcaController.text.trim(),
      attributi: isVariable ? attributiProdotto : [],
      varianti: isVariable ? variantiPulite : [],
      tag: _tags
          .map(
            (tagName) => TagProdotto(
              id: 0, // Il backend gestirà l'ID
              nome: tagName,
              slug: tagName.toLowerCase().replaceAll(' ', '-'),
            ),
          )
          .toList(),
      status: productStatus,
    );
  }

  String _normalizeProductStatus(String? status) {
    final normalized = status?.trim().toLowerCase() ?? 'draft';
    return _productStatusOptions.contains(normalized) ? normalized : 'draft';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'publish':
        return 'Pubblicato';
      case 'private':
        return 'Privato';
      case 'pending':
        return 'In revisione';
      case 'draft':
      default:
        return 'Bozza';
    }
  }

  List<AttributoVariante> _buildAttributiProdottoValidi() {
    final result = <AttributoVariante>[];

    for (final item in _attributiProdottoSelezionati) {
      final nome = item.nome.trim();
      if (nome.isEmpty) continue;

      final valori =
          item.valori
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      for (final valore in valori) {
        result.add(AttributoVariante(nome: nome, opzione: valore));
      }
    }

    return result;
  }

  List<AttributoVariante> _buildAttributiProdottoDaSalvare() {
    final unique = <String, AttributoVariante>{};

    void addAll(Iterable<AttributoVariante> attributes) {
      for (final attribute in attributes) {
        final nome = attribute.nome.trim();
        final opzione = attribute.opzione.trim();
        if (nome.isEmpty || opzione.isEmpty) continue;
        final key = '${nome.toLowerCase()}=${opzione.toLowerCase()}';
        unique[key] = attribute.copyWith(nome: nome, opzione: opzione);
      }
    }

    addAll(_attributiProdottoEsistenti);
    addAll(_buildAttributiProdottoValidi());
    for (final variante in _varianti) {
      addAll(variante.attributi);
    }

    return unique.values.toList()..sort(
      (a, b) => '${a.nome.toLowerCase()}=${a.opzione.toLowerCase()}'.compareTo(
        '${b.nome.toLowerCase()}=${b.opzione.toLowerCase()}',
      ),
    );
  }

  List<AttributoVariante> _collectProductAttributes({
    required ProdottoGlobal prodotto,
    required List<VarianteTemp> varianti,
  }) {
    final attributes = <AttributoVariante>[
      ...?prodotto.attributi,
      for (final variante in varianti) ...variante.attributi,
    ];
    final unique = <String, AttributoVariante>{};
    for (final attribute in attributes) {
      final nome = attribute.nome.trim();
      final opzione = attribute.opzione.trim();
      if (nome.isEmpty || opzione.isEmpty) continue;
      unique['${nome.toLowerCase()}=${opzione.toLowerCase()}'] = attribute
          .copyWith(nome: nome, opzione: opzione);
    }
    return unique.values.toList();
  }
}

class _PcreaVerifyResult {
  final bool productExists;
  final bool variantsComplete;
  final int expectedVariants;
  final int foundVariants;
  final List<String> missingSkus;

  const _PcreaVerifyResult({
    required this.productExists,
    required this.variantsComplete,
    required this.expectedVariants,
    required this.foundVariants,
    required this.missingSkus,
  });
}

class ProductImageUiConfig {
  bool isSetMode;

  ProductImageUiConfig({this.isSetMode = false});

  void reset() {
    isSetMode = false;
  }

  ProductImageUiConfig copy() {
    return ProductImageUiConfig(isSetMode: isSetMode);
  }
}

// Classe helper per gestire le varianti temporanee durante l'editing
class VarianteTemp {
  final Object uiKey = Object();
  int? id;
  String nome;
  String sku;
  String skuFornitore;
  String barcode;
  double prezzo;
  double? prezzoScontato;
  int quantita;
  String? peso;
  String? immagineUrl;
  List<String> imageSetUrls;
  ProductImageUiConfig imageConfig;
  List<AttributoVariante> attributi;
  Map<String, dynamic>? metadatiCustom;

  VarianteTemp({
    this.id,
    required this.nome,
    required this.sku,
    this.skuFornitore = '',
    required this.barcode,
    required this.prezzo,
    this.prezzoScontato,
    required this.quantita,
    this.peso,
    this.immagineUrl,
    List<String>? imageSetUrls,
    ProductImageUiConfig? imageConfig,
    List<AttributoVariante>? attributi,
    this.metadatiCustom,
  }) : imageSetUrls = imageSetUrls ?? [],
       imageConfig = imageConfig ?? ProductImageUiConfig(),
       attributi = attributi ?? [];

  static VarianteTemp fromVarianteProductGlobal(
    VarianteProductGlobal variante,
    ProductImageUiConfig? defaultImageConfig,
  ) {
    return VarianteTemp(
      id: variante.id,
      nome: variante.nome,
      sku: variante.sku,
      skuFornitore: (variante.metadatiCustom?['supplier_sku'] ?? '').toString(),
      barcode: (variante.metadatiCustom?['barcode'] ?? '').toString(),
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: variante.quantita,
      peso: variante.peso,
      immagineUrl: variante.immagineUrl,
      imageSetUrls: [],
      imageConfig: defaultImageConfig?.copy() ?? ProductImageUiConfig(),
      attributi: List.from(variante.attributi),
      metadatiCustom: variante.metadatiCustom == null
          ? null
          : Map<String, dynamic>.from(variante.metadatiCustom!),
    );
  }

  VarianteProductGlobal toVarianteProductGlobal({
    List<AttributoVariante>? attributiOverride,
  }) {
    return VarianteProductGlobal(
      id: id ?? 0,
      nome: nome,
      sku: sku,
      metadatiCustom: <String, dynamic>{
        ...?metadatiCustom,
        if (barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        if (skuFornitore.trim().isNotEmpty) 'supplier_sku': skuFornitore.trim(),
      },
      prezzo: prezzo,
      prezzoScontato: prezzoScontato,
      quantita: quantita,
      peso: peso,
      immagineUrl: imageConfig.isSetMode && imageSetUrls.isNotEmpty
          ? imageSetUrls.first
          : immagineUrl,
      attributi: attributiOverride ?? attributi,
    );
  }
}

class AttributoProdottoSelezionato {
  final TextEditingController nomeController;
  final TextEditingController valoriController;
  List<String> valori;

  AttributoProdottoSelezionato({String nome = '', List<String>? valori})
    : nomeController = TextEditingController(text: nome),
      valoriController = TextEditingController(
        text: (valori ?? const <String>[]).join(', '),
      ),
      valori = List<String>.from(valori ?? const <String>[]);

  String get nome => nomeController.text.trim();

  void setValori(List<String> newValues) {
    valori =
        newValues
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    valoriController.text = valori.join(', ');
  }

  void dispose() {
    nomeController.dispose();
    valoriController.dispose();
  }
}
