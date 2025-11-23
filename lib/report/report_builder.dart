// Report Builder - Creazione report personalizzati
//
// Permette di creare report selezionando campi da una classe dati
// Salva configurazioni in file .report

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../log_viewer/app_logger.dart';

/// Configurazione etichetta per stampa
class EtichettaConfig {
  final bool isCartaTermica;
  final double larghezza; // mm
  final double altezza; // mm
  final double spaziaturaTra; // mm tra etichette
  final double bordoSuperiore; // mm
  final double bordoInferiore; // mm
  final double bordoSinistro; // mm
  final double bordoDestro; // mm
  final int etichettaPerRiga; // solo per A4
  final int etichettaPerColonna; // solo per A4
  final double spazioLateraleA4; // mm

  const EtichettaConfig({
    this.isCartaTermica = false,
    this.larghezza = 50.0,
    this.altezza = 30.0,
    this.spaziaturaTra = 2.0,
    this.bordoSuperiore = 5.0,
    this.bordoInferiore = 5.0,
    this.bordoSinistro = 5.0,
    this.bordoDestro = 5.0,
    this.etichettaPerRiga = 3,
    this.etichettaPerColonna = 10,
    this.spazioLateraleA4 = 5.0,
  });

  Map<String, dynamic> toJson() => {
    'isCartaTermica': isCartaTermica,
    'larghezza': larghezza,
    'altezza': altezza,
    'spaziaturaTra': spaziaturaTra,
    'bordoSuperiore': bordoSuperiore,
    'bordoInferiore': bordoInferiore,
    'bordoSinistro': bordoSinistro,
    'bordoDestro': bordoDestro,
    'etichettaPerRiga': etichettaPerRiga,
    'etichettaPerColonna': etichettaPerColonna,
    'spazioLateraleA4': spazioLateraleA4,
  };

  factory EtichettaConfig.fromJson(Map<String, dynamic> json) => EtichettaConfig(
    isCartaTermica: json['isCartaTermica'] ?? false,
    larghezza: (json['larghezza'] ?? 50.0).toDouble(),
    altezza: (json['altezza'] ?? 30.0).toDouble(),
    spaziaturaTra: (json['spaziaturaTra'] ?? 2.0).toDouble(),
    bordoSuperiore: (json['bordoSuperiore'] ?? 5.0).toDouble(),
    bordoInferiore: (json['bordoInferiore'] ?? 5.0).toDouble(),
    bordoSinistro: (json['bordoSinistro'] ?? 5.0).toDouble(),
    bordoDestro: (json['bordoDestro'] ?? 5.0).toDouble(),
    etichettaPerRiga: json['etichettaPerRiga'] ?? 3,
    etichettaPerColonna: json['etichettaPerColonna'] ?? 10,
    spazioLateraleA4: (json['spazioLateraleA4'] ?? 5.0).toDouble(),
  );

  EtichettaConfig copyWith({
    bool? isCartaTermica,
    double? larghezza,
    double? altezza,
    double? spaziaturaTra,
    double? bordoSuperiore,
    double? bordoInferiore,
    double? bordoSinistro,
    double? bordoDestro,
    int? etichettaPerRiga,
    int? etichettaPerColonna,
    double? spazioLateraleA4,
  }) => EtichettaConfig(
    isCartaTermica: isCartaTermica ?? this.isCartaTermica,
    larghezza: larghezza ?? this.larghezza,
    altezza: altezza ?? this.altezza,
    spaziaturaTra: spaziaturaTra ?? this.spaziaturaTra,
    bordoSuperiore: bordoSuperiore ?? this.bordoSuperiore,
    bordoInferiore: bordoInferiore ?? this.bordoInferiore,
    bordoSinistro: bordoSinistro ?? this.bordoSinistro,
    bordoDestro: bordoDestro ?? this.bordoDestro,
    etichettaPerRiga: etichettaPerRiga ?? this.etichettaPerRiga,
    etichettaPerColonna: etichettaPerColonna ?? this.etichettaPerColonna,
    spazioLateraleA4: spazioLateraleA4 ?? this.spazioLateraleA4,
  );
}

/// Definizione di un campo nel report
class ReportField {
  final String name;
  final String label;
  final Type type;
  final bool selected;
  final int order;

  const ReportField({
    required this.name,
    required this.label,
    required this.type,
    this.selected = false,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
    'type': type.toString(),
    'selected': selected,
    'order': order,
  };

  factory ReportField.fromJson(Map<String, dynamic> json) => ReportField(
    name: json['name'],
    label: json['label'],
    type: _parseType(json['type']),
    selected: json['selected'] ?? false,
    order: json['order'] ?? 0,
  );

  ReportField copyWith({
    String? name,
    String? label,
    Type? type,
    bool? selected,
    int? order,
  }) => ReportField(
    name: name ?? this.name,
    label: label ?? this.label,
    type: type ?? this.type,
    selected: selected ?? this.selected,
    order: order ?? this.order,
  );

  static Type _parseType(String typeStr) {
    switch (typeStr) {
      case 'int':
        return int;
      case 'double':
        return double;
      case 'bool':
        return bool;
      case 'DateTime':
        return DateTime;
      default:
        return String;
    }
  }
}

/// Configurazione completa del report
class ReportConfig {
  final String name;
  final String description;
  final List<ReportField> fields;
  final EtichettaConfig etichetta;
  final String layoutType; // 'etichetta', 'lista', 'tabella', 'fattura'
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportConfig({
    required this.name,
    this.description = '',
    required this.fields,
    EtichettaConfig? etichetta,
    this.layoutType = 'lista',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : etichetta = etichetta ?? const EtichettaConfig(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  List<ReportField> get selectedFields =>
    fields.where((f) => f.selected).toList()..sort((a, b) => a.order.compareTo(b.order));

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'fields': fields.map((f) => f.toJson()).toList(),
    'etichetta': etichetta.toJson(),
    'layoutType': layoutType,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
    name: json['name'],
    description: json['description'] ?? '',
    fields: (json['fields'] as List).map((f) => ReportField.fromJson(f)).toList(),
    etichetta: EtichettaConfig.fromJson(json['etichetta'] ?? {}),
    layoutType: json['layoutType'] ?? 'lista',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  ReportConfig copyWith({
    String? name,
    String? description,
    List<ReportField>? fields,
    EtichettaConfig? etichetta,
    String? layoutType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReportConfig(
    name: name ?? this.name,
    description: description ?? this.description,
    fields: fields ?? this.fields,
    etichetta: etichetta ?? this.etichetta,
    layoutType: layoutType ?? this.layoutType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}

/// Servizio per gestire i file report
class ReportFileService {
  static const String _extension = '.report';

  /// Ottiene la directory dei report
  Future<Directory> getReportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final reportDir = Directory('${appDir.path}/file_report');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    return reportDir;
  }

  /// Salva un report
  Future<File> saveReport(ReportConfig config) async {
    try {
      final dir = await getReportDirectory();
      final fileName = '${config.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$_extension';
      final file = File('${dir.path}/$fileName');

      final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toJson());
      await file.writeAsString(jsonStr);

      log.i('Report salvato: ${file.path}');
      return file;
    } catch (e) {
      log.e('Errore salvataggio report', e);
      rethrow;
    }
  }

  /// Carica un report da file
  Future<ReportConfig> loadReport(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      return ReportConfig.fromJson(json);
    } catch (e) {
      log.e('Errore caricamento report', e);
      rethrow;
    }
  }

  /// Lista tutti i report salvati
  Future<List<File>> listReports() async {
    try {
      final dir = await getReportDirectory();
      final files = await dir.list().where((e) => e.path.endsWith(_extension)).toList();
      return files.map((e) => File(e.path)).toList();
    } catch (e) {
      log.e('Errore lista report', e);
      return [];
    }
  }

  /// Elimina un report
  Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        log.i('Report eliminato: ${file.path}');
      }
    } catch (e) {
      log.e('Errore eliminazione report', e);
      rethrow;
    }
  }

  /// Importa un report da path esterno
  Future<ReportConfig> importReport(String path) async {
    try {
      final file = File(path);
      return await loadReport(file);
    } catch (e) {
      log.e('Errore importazione report', e);
      rethrow;
    }
  }
}

/// Widget per creare/modificare report
class ReportBuilderPage extends StatefulWidget {
  final List<ReportField> availableFields;
  final ReportConfig? existingConfig;
  final Function(ReportConfig) onSave;

  const ReportBuilderPage({
    super.key,
    required this.availableFields,
    this.existingConfig,
    required this.onSave,
  });

  @override
  State<ReportBuilderPage> createState() => _ReportBuilderPageState();
}

class _ReportBuilderPageState extends State<ReportBuilderPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<ReportField> _fields;
  late EtichettaConfig _etichettaConfig;
  late String _layoutType;

  @override
  void initState() {
    super.initState();
    if (widget.existingConfig != null) {
      _nameController = TextEditingController(text: widget.existingConfig!.name);
      _descriptionController = TextEditingController(text: widget.existingConfig!.description);
      _fields = List.from(widget.existingConfig!.fields);
      _etichettaConfig = widget.existingConfig!.etichetta;
      _layoutType = widget.existingConfig!.layoutType;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _fields = widget.availableFields.map((f) => f.copyWith(selected: false, order: 0)).toList();
      _etichettaConfig = const EtichettaConfig();
      _layoutType = 'lista';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleField(int index) {
    setState(() {
      final field = _fields[index];
      _fields[index] = field.copyWith(
        selected: !field.selected,
        order: field.selected ? 0 : _fields.where((f) => f.selected).length,
      );
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
      // Aggiorna ordini
      for (int i = 0; i < _fields.length; i++) {
        if (_fields[i].selected) {
          _fields[i] = _fields[i].copyWith(order: i);
        }
      }
    });
  }

  void _showEtichettaSettings() {
    showDialog(
      context: context,
      builder: (context) => EtichettaSettingsDialog(
        config: _etichettaConfig,
        onSave: (config) {
          setState(() {
            _etichettaConfig = config;
          });
        },
      ),
    );
  }

  void _saveReport() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per il report')),
      );
      return;
    }

    final selectedFields = _fields.where((f) => f.selected).toList();
    if (selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un campo')),
      );
      return;
    }

    final config = ReportConfig(
      name: _nameController.text,
      description: _descriptionController.text,
      fields: _fields,
      etichetta: _etichettaConfig,
      layoutType: _layoutType,
      createdAt: widget.existingConfig?.createdAt,
    );

    widget.onSave(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingConfig != null ? 'Modifica Report' : 'Crea Report'),
        actions: [
          if (_layoutType == 'etichetta')
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showEtichettaSettings,
              tooltip: 'Impostazioni Etichetta',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReport,
            tooltip: 'Salva',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome e descrizione
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Report',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Tipo layout
            const Text(
              'Tipo Layout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Lista'),
                  selected: _layoutType == 'lista',
                  onSelected: (selected) {
                    if (selected) setState(() => _layoutType = 'lista');
                  },
                ),
                ChoiceChip(
                  label: const Text('Tabella'),
                  selected: _layoutType == 'tabella',
                  onSelected: (selected) {
                    if (selected) setState(() => _layoutType = 'tabella');
                  },
                ),
                ChoiceChip(
                  label: const Text('Etichetta'),
                  selected: _layoutType == 'etichetta',
                  onSelected: (selected) {
                    if (selected) setState(() => _layoutType = 'etichetta');
                  },
                ),
                ChoiceChip(
                  label: const Text('Fattura'),
                  selected: _layoutType == 'fattura',
                  onSelected: (selected) {
                    if (selected) setState(() => _layoutType = 'fattura');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Campi disponibili
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Campi Disponibili',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_fields.where((f) => f.selected).length} selezionati',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fields.length,
              onReorder: _reorderFields,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return Card(
                  key: ValueKey(field.name),
                  child: ListTile(
                    leading: Checkbox(
                      value: field.selected,
                      onChanged: (_) => _toggleField(index),
                    ),
                    title: Text(field.label),
                    subtitle: Text(
                      _getTypeLabel(field.type),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: field.selected
                        ? const Icon(Icons.drag_handle)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(Type type) {
    if (type == int) return 'Numero intero';
    if (type == double) return 'Numero decimale';
    if (type == bool) return 'Sì/No';
    if (type == DateTime) return 'Data';
    return 'Testo';
  }
}

/// Dialog per impostazioni etichetta
class EtichettaSettingsDialog extends StatefulWidget {
  final EtichettaConfig config;
  final Function(EtichettaConfig) onSave;

  const EtichettaSettingsDialog({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<EtichettaSettingsDialog> createState() => _EtichettaSettingsDialogState();
}

class _EtichettaSettingsDialogState extends State<EtichettaSettingsDialog> {
  late EtichettaConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Impostazioni Etichetta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tipo carta
            SwitchListTile(
              title: const Text('Carta Termica'),
              subtitle: Text(_config.isCartaTermica ? 'Rotolo termico' : 'Foglio A4'),
              value: _config.isCartaTermica,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(isCartaTermica: value);
                });
              },
            ),
            const Divider(),

            // Dimensioni etichetta
            const Text('Dimensioni Etichetta (mm)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Larghezza'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.larghezza.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(larghezza: value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Altezza'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.altezza.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(altezza: value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Spaziatura
            TextField(
              decoration: const InputDecoration(labelText: 'Spaziatura tra etichette (mm)'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _config.spaziaturaTra.toString()),
              onChanged: (v) {
                final value = double.tryParse(v);
                if (value != null) {
                  _config = _config.copyWith(spaziaturaTra: value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Bordi
            const Text('Bordi (mm)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Superiore'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.bordoSuperiore.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(bordoSuperiore: value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Inferiore'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.bordoInferiore.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(bordoInferiore: value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Sinistro'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.bordoSinistro.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(bordoSinistro: value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Destro'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _config.bordoDestro.toString()),
                    onChanged: (v) {
                      final value = double.tryParse(v);
                      if (value != null) {
                        _config = _config.copyWith(bordoDestro: value);
                      }
                    },
                  ),
                ),
              ],
            ),

            // Impostazioni A4
            if (!_config.isCartaTermica) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text('Impostazioni A4', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Per riga'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _config.etichettaPerRiga.toString()),
                      onChanged: (v) {
                        final value = int.tryParse(v);
                        if (value != null) {
                          _config = _config.copyWith(etichettaPerRiga: value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Per colonna'),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _config.etichettaPerColonna.toString()),
                      onChanged: (v) {
                        final value = int.tryParse(v);
                        if (value != null) {
                          _config = _config.copyWith(etichettaPerColonna: value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Spazio laterale (mm)'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _config.spazioLateraleA4.toString()),
                onChanged: (v) {
                  final value = double.tryParse(v);
                  if (value != null) {
                    _config = _config.copyWith(spazioLateraleA4: value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_config);
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
