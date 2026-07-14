import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:gestione_negozio_abbigliamento/log_viewer/app_logger.dart';
import '../../class_image_modofy.dart';
import '../../../notification/notification_service.dart';
import '../../../settings/app_settings.dart';
import '../../../login/jwt_api/query_woocommerce/woo_query_media.dart';
import '../../../login/jwt_api/class_prodotti.dart';

/// Dialog per selezionare immagini dalla libreria media di WordPress
class MediaSelectorDialog extends StatefulWidget {
  final bool initialEnableResize;
  final bool initialEnableBackgroundRemove;
  final bool initialEnableFormatConvert;
  final String initialOutputFormat;
  final int initialResizeWidth;
  final int initialResizeHeight;

  const MediaSelectorDialog({
    super.key,
    this.initialEnableResize = true,
    this.initialEnableBackgroundRemove = true,
    this.initialEnableFormatConvert = true,
    this.initialOutputFormat = 'webp',
    this.initialResizeWidth = 720,
    this.initialResizeHeight = 1080,
  });

  @override
  State<MediaSelectorDialog> createState() => _MediaSelectorDialogState();
}

class _MediaSelectorDialogState extends State<MediaSelectorDialog> {
  final WooQueryMedia _mediaQuery = WooQueryMedia();

  List<MediaFile> _images = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  final int _perPage = 20;
  bool _hasMorePages = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Stato per drag & drop e upload
  bool _isDragging = false;
  bool _isUploading = false;
  String? _uploadingFileName;

  // Pre-processing immagini locale
  bool _enableResize = false;
  bool _enableBackgroundRemove = false;
  bool _enableFormatConvert = false;
  String _outputFormat = 'webp';
  late final TextEditingController _resizeWidthController;
  late final TextEditingController _resizeHeightController;

  @override
  void initState() {
    super.initState();
    _enableResize = widget.initialEnableResize;
    _enableBackgroundRemove = widget.initialEnableBackgroundRemove;
    _enableFormatConvert = widget.initialEnableFormatConvert;
    _outputFormat = widget.initialOutputFormat;
    _resizeWidthController = TextEditingController(
      text: widget.initialResizeWidth.toString(),
    );
    _resizeHeightController = TextEditingController(
      text: widget.initialResizeHeight.toString(),
    );
    _loadImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _resizeWidthController.dispose();
    _resizeHeightController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMorePages) {
        _loadMoreImages();
      }
    }
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _images.clear();
    });

    try {
      final images = await _mediaQuery.getImages(
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          _images = images;
          _hasMorePages = images.length == _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      log.e('Errore caricamento immagini', e);
      if (mounted) {
        setState(() {
          _error = 'Errore nel caricamento: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final newImages = await _mediaQuery.getImages(
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          _images.addAll(newImages);
          _hasMorePages = newImages.length == _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      log.e('Errore caricamento pagina $_currentPage', e);
      if (mounted) {
        setState(() {
          _currentPage--;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchImages(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _images.clear();
    });

    try {
      final images = await _mediaQuery.getMediaList(
        page: 1,
        perPage: _perPage,
        search: query.isEmpty ? null : query,
        mimeType: 'image',
      );

      if (mounted) {
        setState(() {
          _images = images;
          _hasMorePages = images.length == _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      log.e('Errore ricerca immagini', e);
      if (mounted) {
        setState(() {
          _error = 'Errore nella ricerca: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Seleziona e carica un'immagine dal file system
  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // Utente ha annullato
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Percorso file non valido');
      }

      await _uploadFile(file.path!, file.name);
    } catch (e) {
      log.e('Errore selezione file', e);
      if (mounted) {
        NotificationService.instance.messageBar(
          'errore',
          'media_selector_dialog',
          'Errore nella selezione del file: $e',
        );
      }
    }
  }

  /// Gestisce file trascinati (drag & drop)
  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    // Prendi solo il primo file se sono stati trascinati più file
    final file = details.files.first;

    // Verifica che sia un'immagine
    final extension = file.path.split('.').last.toLowerCase();
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];

    if (!validExtensions.contains(extension)) {
      if (mounted) {
        NotificationService.instance.messageBar(
          'warning',
          'media_selector_dialog',
          'Per favore trascina solo file immagine (jpg, png, gif, webp, svg)',
        );
      }
      return;
    }

    await _uploadFile(file.path, file.name);
  }

  bool get _hasImageProcessingEnabled {
    return _enableResize || _enableBackgroundRemove || _enableFormatConvert;
  }

  int _parseResizeValue(String raw) {
    final value = int.tryParse(raw.trim()) ?? 0;
    return value < 0 ? 0 : value;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  Future<String> _prepareImageForUpload(String originalPath) async {
    if (!_hasImageProcessingEnabled) {
      return originalPath;
    }

    final width = _parseResizeValue(_resizeWidthController.text);
    final height = _parseResizeValue(_resizeHeightController.text);

    if (_enableResize && width <= 0 && height <= 0) {
      throw Exception(
        'Resize attivo ma larghezza e altezza non valide. Inserisci almeno un valore > 0.',
      );
    }

    final processor = class_image_modofy([originalPath]);
    final settings = AppSettings();
    await settings.init();
    processor.modalita_scontorno(
      mode: settings.imageBackgroundMode,
      apiEndpoint: settings.imageBackgroundApiEndpoint,
      apiKey: settings.imageBackgroundApiKey,
    );
    processor.modifica_risolzione(_enableResize, width, height);
    processor.backgraud_remove(_enableBackgroundRemove);
    processor.cambia_formato(_enableFormatConvert, _outputFormat);

    final results = await processor.processa_dettagliata();
    if (results.isEmpty) {
      throw Exception('Nessun risultato dal pre-processing immagini.');
    }

    final result = results.first;
    if (!result.success || result.outputPath == null) {
      throw Exception(
        result.errorMessage ?? 'Errore durante pre-processing immagine.',
      );
    }

    return result.outputPath!;
  }

  /// Carica un file su WordPress
  Future<void> _uploadFile(String filePath, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadingFileName = fileName;
    });

    try {
      log.d('📤 Inizio upload: $fileName');

      final pathToUpload = await _prepareImageForUpload(filePath);
      final uploadName = _fileNameFromPath(pathToUpload);

      final uploadedMedia = await _mediaQuery.uploadMedia(
        pathToUpload,
        title: uploadName.split('.').first,
      );

      log.d(
        '✅ Upload completato: ${uploadedMedia.id} - ${uploadedMedia.title}',
      );

      if (mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'media_selector_dialog',
          'Immagine "$fileName" caricata con successo!',
        );

        // Ricarica la lista immagini per mostrare quella appena caricata
        await _loadImages();
      }
    } catch (e) {
      log.e('❌ Errore upload file', e);
      if (mounted) {
        NotificationService.instance.messageBar(
          'errore',
          'media_selector_dialog',
          'Errore nel caricamento: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingFileName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: DropTarget(
          onDragEntered: (details) {
            setState(() => _isDragging = true);
          },
          onDragExited: (details) {
            setState(() => _isDragging = false);
          },
          onDragDone: (details) {
            setState(() => _isDragging = false);
            _handleDroppedFiles(details);
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.photo_library, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Seleziona Immagine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Pulsante Carica
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Carica'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildImageProcessingControls(),
                  const SizedBox(height: 12),

                  // Barra di ricerca
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca immagini...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchImages('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: _searchImages,
                  ),
                  const SizedBox(height: 16),

                  // Indicatore upload
                  if (_isUploading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Caricamento in corso...',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_uploadingFileName != null)
                                  Text(
                                    _uploadingFileName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Contatore immagini
                  if (_images.isNotEmpty && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_images.length} immagini trovate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),

                  // Griglia immagini
                  Expanded(child: _buildContent()),
                ],
              ),

              // Overlay drag & drop
              if (_isDragging)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.blue,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 64,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Rilascia qui per caricare',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageProcessingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_fix_high, size: 18),
                SizedBox(width: 8),
                Text(
                  'Pre-processing locale',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Modifica risoluzione'),
              value: _enableResize,
              onChanged: _isUploading
                  ? null
                  : (value) {
                      setState(() => _enableResize = value);
                    },
            ),
            if (_enableResize)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _resizeWidthController,
                      enabled: !_isUploading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Larghezza',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _resizeHeightController,
                      enabled: !_isUploading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Altezza',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Scontorna sfondo'),
              value: _enableBackgroundRemove,
              onChanged: _isUploading
                  ? null
                  : (value) {
                      setState(() => _enableBackgroundRemove = value);
                    },
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Cambia formato'),
              value: _enableFormatConvert,
              onChanged: _isUploading
                  ? null
                  : (value) {
                      setState(() => _enableFormatConvert = value);
                    },
            ),
            if (_enableFormatConvert)
              DropdownButtonFormField<String>(
                value: _outputFormat,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Formato output'),
                items: const [
                  DropdownMenuItem(value: 'webp', child: Text('WEBP')),
                  DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                  DropdownMenuItem(value: 'png', child: Text('PNG')),
                ],
                onChanged: _isUploading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _outputFormat = value);
                      },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImages,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento immagini...'),
          ],
        ),
      );
    }

    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessuna immagine trovata',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return _buildImageCard(image);
            },
          ),
        ),
        if (_isLoading && _images.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildImageCard(MediaFile image) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(image),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Immagine
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                  // Overlay hover
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title ?? 'Immagine senza titolo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (image.width != null && image.height != null)
                    Text(
                      '${image.width} × ${image.height}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metodo helper per mostrare il dialog e ottenere l'immagine selezionata
Future<MediaFile?> showMediaSelector(
  BuildContext context, {
  bool initialEnableResize = true,
  bool initialEnableBackgroundRemove = true,
  bool initialEnableFormatConvert = true,
  String initialOutputFormat = 'webp',
  int initialResizeWidth = 720,
  int initialResizeHeight = 1080,
}) async {
  return await showDialog<MediaFile>(
    context: context,
    builder: (context) => MediaSelectorDialog(
      initialEnableResize: initialEnableResize,
      initialEnableBackgroundRemove: initialEnableBackgroundRemove,
      initialEnableFormatConvert: initialEnableFormatConvert,
      initialOutputFormat: initialOutputFormat,
      initialResizeWidth: initialResizeWidth,
      initialResizeHeight: initialResizeHeight,
    ),
  );
}
