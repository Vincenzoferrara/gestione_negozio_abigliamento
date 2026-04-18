import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../class_prodotti.dart';
import '../../theme/theme.dart';
import '../../settings/app_settings.dart';
import '../../ai/ai_service.dart';
import '../../log_viewer/app_logger.dart';
import '../../notification/notification_service.dart';
import 'prodotti_crea.code.dart';
import 'widgets/media_selector_dialog.dart';

class ProdottiCreaPage extends StatefulWidget {
  final ProdottoGlobal? prodottoDaModificare;

  const ProdottiCreaPage({super.key, this.prodottoDaModificare});

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
  final List<FocusNode> _barcodeFocusNodes = [];
  final Map<int, String> _barcodePreviousValues = {};

  // Stato IA
  bool _isGeneratingShortDesc = false;
  bool _isGeneratingLongDesc = false;
  bool _isGeneratingCategories = false;
  bool _isGeneratingTags = false;

  // Dati
  List<VarianteTemp> _varianti = [];
  List<AttributoProdottoSelezionato> _attributiProdottoSelezionati = [];
  List<String> _categorieSelezionate = [];
  List<String> _tags = [];
  ProdottoGlobal? _prodottoOriginale;
  final ImageProcessUiConfig _mainImageConfig = ImageProcessUiConfig();
  final ImageProcessUiConfig _defaultImageConfig = ImageProcessUiConfig();
  List<String> _mainImageSetUrls = [];

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
      _prodottiController = ProdottiCreaController();
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
    final settings = AppSettings();
    await settings.init();

    if (!mounted) return;

    setState(() {
      _defaultImageConfig.enableResize = settings.imageResizeEnabled;
      _defaultImageConfig.resizeWidth = settings.imageResizeWidth;
      _defaultImageConfig.resizeHeight = settings.imageResizeHeight;
      _defaultImageConfig.enableBackgroundRemove =
          settings.imageBackgroundRemoveEnabled;
      _defaultImageConfig.enableFormatConvert =
          settings.imageFormatChangeEnabled;
      _defaultImageConfig.outputFormat = settings.imageOutputFormat;

      _mainImageConfig.enableResize = _defaultImageConfig.enableResize;
      _mainImageConfig.resizeWidth = _defaultImageConfig.resizeWidth;
      _mainImageConfig.resizeHeight = _defaultImageConfig.resizeHeight;
      _mainImageConfig.enableBackgroundRemove =
          _defaultImageConfig.enableBackgroundRemove;
      _mainImageConfig.enableFormatConvert =
          _defaultImageConfig.enableFormatConvert;
      _mainImageConfig.outputFormat = _defaultImageConfig.outputFormat;
    });
  }

  void _applyDefaultImageConfig(ImageProcessUiConfig target) {
    target.enableResize = _defaultImageConfig.enableResize;
    target.resizeWidth = _defaultImageConfig.resizeWidth;
    target.resizeHeight = _defaultImageConfig.resizeHeight;
    target.enableBackgroundRemove = _defaultImageConfig.enableBackgroundRemove;
    target.enableFormatConvert = _defaultImageConfig.enableFormatConvert;
    target.outputFormat = _defaultImageConfig.outputFormat;
    target.isSetMode = false;
  }

  ImageProcessUiConfig _newImageConfigFromDefaults() {
    final config = ImageProcessUiConfig();
    _applyDefaultImageConfig(config);
    return config;
  }

  Future<void> _caricaDatiProdottoEsistente(ProdottoGlobal prodotto) async {
    final int productId = prodotto.id ?? 0;
    log.d('PCREA_LOAD_EXISTING_START productId=$productId sku=${prodotto.sku}');

    List<VarianteProductGlobal> variantiServer = prodotto.varianti ?? [];
    if (productId > 0 && _prodottiController != null) {
      try {
        variantiServer = await _prodottiController!.getAllVarianti(productId);
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
      _attributiProdottoSelezionati = _ricostruisciAttributiProdotto(
        prodotto: prodotto,
        varianti: _varianti,
      );
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
      for (final attributo in _attributiProdottoSelezionati) {
        attributo.dispose();
      }
      _attributiProdottoSelezionati = [];
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
      ],
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
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
                ),
              ],
            ),
          ),
        ),
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
                    'Il prodotto sarà "semplice". Aggiungi varianti per creare un prodotto variabile.',
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
          ...List.generate(
            _varianti.length,
            (index) => _buildVarianteCard(index),
          ),
      ],
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

  Widget _buildVarianteCard(int index) {
    final variante = _varianti[index];
    final attrSummary = variante.attributi
        .where((a) => a.nome.trim().isNotEmpty && a.opzione.trim().isNotEmpty)
        .map((a) => '${a.nome}:${a.opzione}')
        .join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (!expanded) return;
          setState(() {
            _selectedVarianteIndex = index;
          });
        },
        leading: _buildVarianteImageThumb(index, variante),
        title: Text('Variante #${index + 1}'),
        subtitle: Text(
          'SKU: ${variante.sku.isEmpty ? "-" : variante.sku} | ${attrSummary.isEmpty ? "-" : attrSummary} | BAR: ${variante.barcode.isEmpty ? "-" : variante.barcode} | QTA: ${variante.quantita}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (index > 0)
              PopupMenuItem(
                onTap: () => _spostaVariante(index, -1),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward),
                    SizedBox(width: 8),
                    Text('Sposta su'),
                  ],
                ),
              ),
            if (index < _varianti.length - 1)
              PopupMenuItem(
                onTap: () => _spostaVariante(index, 1),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_downward),
                    SizedBox(width: 8),
                    Text('Sposta giu'),
                  ],
                ),
              ),
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
              child: const Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text('Elimina'),
                ],
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const SizedBox(height: 6),
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
                  onChanged: (value) => variante.peso = value.trim().isEmpty
                      ? null
                      : value.trim(),
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
      ),
    );
  }

  Widget _buildVarianteImageThumb(int varianteIndex, VarianteTemp variante) {
    final imageUrl = variante.immagineUrl;

    return InkWell(
      onTap: () async {
        final selectedMedia = await showMediaSelector(
          context,
          initialEnableResize: variante.imageConfig.enableResize,
          initialEnableBackgroundRemove:
              variante.imageConfig.enableBackgroundRemove,
          initialEnableFormatConvert: variante.imageConfig.enableFormatConvert,
          initialOutputFormat: variante.imageConfig.outputFormat,
          initialResizeWidth: variante.imageConfig.resizeWidth,
          initialResizeHeight: variante.imageConfig.resizeHeight,
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
      ).colorScheme.surfaceVariant.withValues(alpha: 0.5),
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

  Widget _buildColorPicker(
    AttributoVariante attributo,
    int varianteIndex,
    int attrIndex,
  ) {
    final currentColor =
        _hexToColor(attributo.valore ?? '#FFFFFF') ?? Colors.white;

    return Column(
      children: [
        const Text(
          'Colore',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showColorPickerDialog(
            context: context,
            initialColor: currentColor,
            onColorSelected: (color) {
              final hexValue = _colorToHex(color).toUpperCase();
              setState(() {
                _varianti[varianteIndex].attributi[attrIndex] = attributo
                    .copyWith(valore: hexValue);
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
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.palette, color: Colors.white, size: 20),
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
                            initialEnableResize: _mainImageConfig.enableResize,
                            initialEnableBackgroundRemove:
                                _mainImageConfig.enableBackgroundRemove,
                            initialEnableFormatConvert:
                                _mainImageConfig.enableFormatConvert,
                            initialOutputFormat: _mainImageConfig.outputFormat,
                            initialResizeWidth: _mainImageConfig.resizeWidth,
                            initialResizeHeight: _mainImageConfig.resizeHeight,
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
                _buildImageProcessingOptions(
                  config: _mainImageConfig,
                  title: 'Immagine principale',
                  setImages: _mainImageSetUrls,
                  onAddSetImage: () async {
                    final selectedMedia = await showMediaSelector(
                      context,
                      initialEnableResize: _mainImageConfig.enableResize,
                      initialEnableBackgroundRemove:
                          _mainImageConfig.enableBackgroundRemove,
                      initialEnableFormatConvert:
                          _mainImageConfig.enableFormatConvert,
                      initialOutputFormat: _mainImageConfig.outputFormat,
                      initialResizeWidth: _mainImageConfig.resizeWidth,
                      initialResizeHeight: _mainImageConfig.resizeHeight,
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

  Widget _buildImageProcessingOptions({
    required ImageProcessUiConfig config,
    required String title,
    List<String>? setImages,
    Future<void> Function()? onAddSetImage,
    void Function(String)? onRemoveSetImage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title - Opzioni',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: config.enableFormatConvert,
                    onChanged: (value) {
                      setState(() {
                        config.enableFormatConvert = value ?? false;
                      });
                    },
                  ),
                  const Text('Cambia formato'),
                ],
              ),
              if (config.enableFormatConvert)
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    value: config.outputFormat,
                    decoration: const InputDecoration(labelText: 'Formato'),
                    items: const [
                      DropdownMenuItem(value: 'webp', child: Text('WEBP')),
                      DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                      DropdownMenuItem(value: 'png', child: Text('PNG')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        config.outputFormat = value;
                      });
                    },
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: config.enableResize,
                    onChanged: (value) {
                      setState(() {
                        config.enableResize = value ?? false;
                      });
                    },
                  ),
                  const Text('Risoluzione'),
                ],
              ),
              if (config.enableResize)
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: config.resizeWidth.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'W',
                    ),
                    onChanged: (value) {
                      config.resizeWidth = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              if (config.enableResize)
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: config.resizeHeight.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'H',
                    ),
                    onChanged: (value) {
                      config.resizeHeight = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: config.enableBackgroundRemove,
                    onChanged: (value) {
                      setState(() {
                        config.enableBackgroundRemove = value ?? false;
                      });
                    },
                  ),
                  const Text('Rimuovi background'),
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
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => _AttributeValuesDialog(
        title: 'Categorie prodotto',
        inputLabel: 'Filtra o nuova categoria',
        suggestions: _suggerimentiCategoria,
        selectedValues: _categorieSelezionate,
      ),
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

  // Helper methods per colori
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
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

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => _AttributeValuesDialog(
        title: attrName.isEmpty ? 'Valori attributo' : 'Valori $attrName',
        inputLabel: 'Filtra o nuovo valore',
        suggestions: _suggerimentiOpzioni[attrName] ?? const <String>[],
        selectedValues: attributo.valori,
      ),
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

    final combinazioni = _generaCombinazioniAttributi(attributiValidi);
    if (combinazioni.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_crea',
        'Nessuna combinazione generata.',
      );
      return;
    }

    final variantiEsistenti = {
      for (final variante in _varianti)
        _buildVariantCombinationKey(variante.attributi): variante,
    };

    setState(() {
      _varianti = combinazioni.asMap().entries.map((entry) {
        final index = entry.key;
        final attributi = entry.value;
        final comboKey = _buildVariantCombinationKey(attributi);
        final esistente = variantiEsistenti[comboKey];

        if (esistente != null) {
          esistente.attributi = attributi;
          return esistente;
        }

        return VarianteTemp(
          nome: 'Variante ${index + 1}',
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
      }).toList();
      _syncBarcodeFocusNodes();
      _selectedVarianteIndex = _varianti.isEmpty ? null : 0;
    });

    NotificationService.instance.messageBar(
      'successo',
      'prodotti_crea',
      'Generate ${combinazioni.length} varianti.',
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
          barcode: variante.barcode,
          prezzo: variante.prezzo,
          quantita: variante.quantita,
          peso: variante.peso,
          immagineUrl: variante.immagineUrl,
          imageSetUrls: List<String>.from(variante.imageSetUrls),
          imageConfig: variante.imageConfig.copy(),
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
          final selected = await showDialog<List<String>>(
            context: context,
            builder: (context) => _AttributeValuesDialog(
              title: 'Categorie suggerite',
              inputLabel: 'Filtra o nuova categoria',
              suggestions: categories,
              selectedValues: _categorieSelezionate,
            ),
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
        final selectedTags = await showDialog<List<String>>(
          context: context,
          builder: (context) => _TagSelectionDialog(
            suggestedTags: suggestedTags,
            existingTags: _tags,
          ),
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

      final verify = await _verificaPersistenzaProdotto(
        expected: prodotto,
        saved: savedProduct,
      );
      _updateSaveProgress(1.0, 'Completato');

      if (mounted) {
        final isFullSuccess = verify.productExists && verify.variantsComplete;
        final message = _buildVerifyMessage(verify);
        NotificationService.instance.messageBar(
          isFullSuccess ? 'successo' : 'partial',
          'prodotti_crea',
          message,
        );
        if (isFullSuccess) {
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

      final comboKey = _buildVariantCombinationKey(variante.attributi);
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

  String _buildVariantCombinationKey(List<AttributoVariante> attributes) {
    final pairs =
        attributes
            .map(
              (a) =>
                  '${a.nome.trim().toLowerCase()}=${a.opzione.trim().toLowerCase()}',
            )
            .where((p) => !p.startsWith('=') && !p.endsWith('='))
            .toList()
          ..sort();
    return pairs.join('|');
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
    final attributiProdotto = _buildAttributiProdottoValidi();
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

  List<AttributoProdottoSelezionato> _ricostruisciAttributiProdotto({
    required ProdottoGlobal prodotto,
    required List<VarianteTemp> varianti,
  }) {
    final grouped = <String, Set<String>>{};

    for (final attr in prodotto.attributi ?? const <AttributoVariante>[]) {
      final nome = attr.nome.trim();
      final valore = attr.opzione.trim();
      if (nome.isEmpty || valore.isEmpty) continue;
      grouped.putIfAbsent(nome, () => <String>{}).add(valore);
    }

    for (final variante in varianti) {
      for (final attr in variante.attributi) {
        final nome = attr.nome.trim();
        final valore = attr.opzione.trim();
        if (nome.isEmpty || valore.isEmpty) continue;
        grouped.putIfAbsent(nome, () => <String>{}).add(valore);
      }
    }

    return grouped.entries.map((entry) {
      final valori = entry.value.toList()..sort();
      return AttributoProdottoSelezionato(nome: entry.key, valori: valori);
    }).toList();
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

  List<List<AttributoVariante>> _generaCombinazioniAttributi(
    List<AttributoVariante> attributi,
  ) {
    final grouped = <String, List<String>>{};
    for (final attributo in attributi) {
      grouped
          .putIfAbsent(attributo.nome, () => <String>[])
          .add(attributo.opzione);
    }

    var combinations = <List<AttributoVariante>>[<AttributoVariante>[]];
    for (final entry in grouped.entries) {
      final valori = entry.value.toSet().toList()..sort();
      final next = <List<AttributoVariante>>[];

      for (final combination in combinations) {
        for (final valore in valori) {
          next.add([
            ...combination,
            AttributoVariante(nome: entry.key, opzione: valore),
          ]);
        }
      }

      combinations = next;
    }

    return combinations;
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

class ImageProcessUiConfig {
  bool isSetMode;
  bool enableResize;
  int resizeWidth;
  int resizeHeight;
  bool enableBackgroundRemove;
  bool enableFormatConvert;
  String outputFormat;

  ImageProcessUiConfig({
    this.isSetMode = false,
    this.enableResize = true,
    this.resizeWidth = 720,
    this.resizeHeight = 1080,
    this.enableBackgroundRemove = true,
    this.enableFormatConvert = true,
    this.outputFormat = 'webp',
  });

  void reset() {
    isSetMode = false;
    enableResize = true;
    resizeWidth = 720;
    resizeHeight = 1080;
    enableBackgroundRemove = true;
    enableFormatConvert = true;
    outputFormat = 'webp';
  }

  ImageProcessUiConfig copy() {
    return ImageProcessUiConfig(
      isSetMode: isSetMode,
      enableResize: enableResize,
      resizeWidth: resizeWidth,
      resizeHeight: resizeHeight,
      enableBackgroundRemove: enableBackgroundRemove,
      enableFormatConvert: enableFormatConvert,
      outputFormat: outputFormat,
    );
  }
}

// Classe helper per gestire le varianti temporanee durante l'editing
class VarianteTemp {
  int? id;
  String nome;
  String sku;
  String barcode;
  double prezzo;
  double? prezzoScontato;
  int quantita;
  String? peso;
  String? immagineUrl;
  List<String> imageSetUrls;
  ImageProcessUiConfig imageConfig;
  List<AttributoVariante> attributi;

  VarianteTemp({
    this.id,
    required this.nome,
    required this.sku,
    required this.barcode,
    required this.prezzo,
    this.prezzoScontato,
    required this.quantita,
    this.peso,
    this.immagineUrl,
    List<String>? imageSetUrls,
    ImageProcessUiConfig? imageConfig,
    List<AttributoVariante>? attributi,
  }) : imageSetUrls = imageSetUrls ?? [],
       imageConfig = imageConfig ?? ImageProcessUiConfig(),
       attributi = attributi ?? [];

  static VarianteTemp fromVarianteProductGlobal(
    VarianteProductGlobal variante,
    ImageProcessUiConfig? defaultImageConfig,
  ) {
    return VarianteTemp(
      id: variante.id,
      nome: variante.nome,
      sku: variante.sku,
      barcode: (variante.metadatiCustom?['barcode'] ?? '').toString(),
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: variante.quantita,
      peso: variante.peso,
      immagineUrl: variante.immagineUrl,
      imageSetUrls: [],
      imageConfig: defaultImageConfig?.copy() ?? ImageProcessUiConfig(),
      attributi: List.from(variante.attributi),
    );
  }

  VarianteProductGlobal toVarianteProductGlobal({
    List<AttributoVariante>? attributiOverride,
  }) {
    return VarianteProductGlobal(
      id: id ?? 0,
      nome: nome,
      sku: sku,
      metadatiCustom: barcode.trim().isEmpty
          ? null
          : <String, dynamic>{'barcode': barcode.trim()},
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

class _AttributeValuesDialog extends StatefulWidget {
  final String title;
  final String inputLabel;
  final List<String> suggestions;
  final List<String> selectedValues;

  const _AttributeValuesDialog({
    required this.title,
    this.inputLabel = 'Filtra o nuovo valore',
    required this.suggestions,
    required this.selectedValues,
  });

  @override
  State<_AttributeValuesDialog> createState() => _AttributeValuesDialogState();
}

class _AttributeValuesDialogState extends State<_AttributeValuesDialog> {
  late final TextEditingController _newValueController;
  late List<String> _options;
  late Set<String> _selected;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _newValueController = TextEditingController();
    _options = {...widget.suggestions, ...widget.selectedValues}.toList()
      ..sort();
    _selected = widget.selectedValues.toSet();
  }

  @override
  void dispose() {
    _newValueController.dispose();
    super.dispose();
  }

  void _addCustomValue() {
    final value = _newValueController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      if (!_options.any(
        (option) => option.toLowerCase() == value.toLowerCase(),
      )) {
        _options.add(value);
        _options.sort();
      }

      final existing = _options.firstWhere(
        (option) => option.toLowerCase() == value.toLowerCase(),
      );
      _selected.add(existing);
      _newValueController.clear();
      _filter = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _filter.trim().isEmpty
        ? _options
        : _options
              .where(
                (option) =>
                    option.toLowerCase().contains(_filter.trim().toLowerCase()),
              )
              .toList();
    final hasExactMatch = _options.any(
      (option) => option.toLowerCase() == _filter.trim().toLowerCase(),
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: _options.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selected = _options.toSet();
                          });
                        },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Seleziona tutto'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selected.clear();
                          });
                        },
                  child: const Text('Pulisci'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newValueController,
                    decoration: InputDecoration(
                      labelText: widget.inputLabel,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                    onSubmitted: (_) => _addCustomValue(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _filter.trim().isEmpty ? null : _addCustomValue,
                  child: Text(hasExactMatch ? 'Seleziona' : 'Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filteredOptions.isEmpty
                  ? const Center(child: Text('Nessun valore trovato'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredOptions.length,
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final selected = _selected.contains(option);
                        return CheckboxListTile(
                          value: selected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(option),
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selected.add(option);
                              } else {
                                _selected.remove(option);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final result = _selected.toList()..sort();
            Navigator.pop(context, result);
          },
          child: Text('Conferma (${_selected.length})'),
        ),
      ],
    );
  }
}

// Dialog per selezione tag suggeriti dall'IA
class _TagSelectionDialog extends StatefulWidget {
  final List<String> suggestedTags;
  final List<String> existingTags;

  const _TagSelectionDialog({
    required this.suggestedTags,
    required this.existingTags,
  });

  @override
  State<_TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<_TagSelectionDialog> {
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = {};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tag Suggeriti'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleziona i tag da aggiungere:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestedTags.map((tag) {
                final isExisting = widget.existingTags.contains(tag);
                final isSelected = _selectedTags.contains(tag);

                return FilterChip(
                  label: Text(tag),
                  selected: isSelected || isExisting,
                  onSelected: isExisting
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                  backgroundColor: isExisting ? Colors.grey[300] : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _selectedTags.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedTags.toList()),
          child: Text('Aggiungi (${_selectedTags.length})'),
        ),
      ],
    );
  }
}
