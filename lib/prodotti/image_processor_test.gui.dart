import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'class_image_modofy.dart';
import '../settings/app_settings.dart';

class ImageProcessorTestPage extends StatefulWidget {
  const ImageProcessorTestPage({super.key});

  @override
  State<ImageProcessorTestPage> createState() => _ImageProcessorTestPageState();
}

class _ImageProcessorTestPageState extends State<ImageProcessorTestPage> {
  String? _inputPath;
  String? _outputPath;
  String? _error;
  bool _isProcessing = false;

  bool _enableResize = true;
  bool _enableBackgroundRemove = true;
  bool _enableFormatChange = true;
  String _format = 'webp';
  String _bgModeLabel = 'local';

  final TextEditingController _widthController = TextEditingController(
    text: '720',
  );
  final TextEditingController _heightController = TextEditingController(
    text: '1080',
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = AppSettings();
    await settings.init();
    if (!mounted) return;
    setState(() {
      _bgModeLabel = settings.imageBackgroundMode;
    });
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    setState(() {
      _inputPath = result.files.first.path;
      _outputPath = null;
      _error = null;
    });
  }

  Future<void> _processImage() async {
    if (_inputPath == null) {
      setState(() => _error = 'Seleziona prima un\'immagine.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final width = int.tryParse(_widthController.text.trim()) ?? 0;
      final height = int.tryParse(_heightController.text.trim()) ?? 0;

      final processor = class_image_modofy([_inputPath!]);
      final settings = AppSettings();
      await settings.init();
      processor.modalita_scontorno(
        mode: settings.imageBackgroundMode,
        apiEndpoint: settings.imageBackgroundApiEndpoint,
        apiKey: settings.imageBackgroundApiKey,
      );
      processor.modifica_risolzione(_enableResize, width, height);
      processor.backgraud_remove(_enableBackgroundRemove);
      processor.cambia_formato(_enableFormatChange, _format);

      final results = await processor.processa_dettagliata();
      if (results.isEmpty || !results.first.success || results.first.outputPath == null) {
        throw Exception(results.isEmpty ? 'Nessun risultato.' : results.first.errorMessage);
      }

      setState(() {
        _outputPath = results.first.outputPath;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Image Processor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Seleziona immagine locale'),
                  ),
                  if (_inputPath != null) ...[
                    const SizedBox(height: 8),
                    Text(_inputPath!, style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Modalita scontorno attiva da Settings: $_bgModeLabel',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _enableResize,
                    onChanged: _isProcessing
                        ? null
                        : (v) => setState(() => _enableResize = v ?? false),
                    title: const Text('Resize'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_enableResize)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Width',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  CheckboxListTile(
                    value: _enableBackgroundRemove,
                    onChanged: _isProcessing
                        ? null
                        : (v) =>
                              setState(() => _enableBackgroundRemove = v ?? false),
                    title: const Text('Rimuovi background'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _enableFormatChange,
                    onChanged: _isProcessing
                        ? null
                        : (v) =>
                              setState(() => _enableFormatChange = v ?? false),
                    title: const Text('Cambia formato'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_enableFormatChange)
                    DropdownButtonFormField<String>(
                      value: _format,
                      decoration: const InputDecoration(
                        labelText: 'Formato output',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'webp', child: Text('WEBP')),
                        DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                        DropdownMenuItem(value: 'png', child: Text('PNG')),
                      ],
                      onChanged: _isProcessing
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _format = v);
                              }
                            },
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processImage,
                    icon: _isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isProcessing ? 'Elaborazione...' : 'Esegui test'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_inputPath != null) _buildPreviewCard('Input', _inputPath!),
          if (_outputPath != null) ...[
            const SizedBox(height: 12),
            _buildPreviewCard('Output', _outputPath!),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard(String title, String path) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(path, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Anteprima non disponibile'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
