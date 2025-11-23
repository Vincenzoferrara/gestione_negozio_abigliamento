// Report Viewer - Visualizzazione report generati
//
// Mostra i dati del report secondo la configurazione
// Supporta stampa PDF e invio diretto a stampante

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'report_builder.dart';
import '../log_viewer/app_logger.dart';

/// Widget per visualizzare il report
class ReportViewerPage extends StatefulWidget {
  final ReportConfig config;
  final List<Map<String, dynamic>> data;

  const ReportViewerPage({
    super.key,
    required this.config,
    required this.data,
  });

  @override
  State<ReportViewerPage> createState() => _ReportViewerPageState();
}

class _ReportViewerPageState extends State<ReportViewerPage> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/${widget.config.name}_$timestamp.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF salvato: ${file.path.split('/').last}'),
            action: SnackBarAction(
              label: 'Apri',
              onPressed: () => Printing.sharePdf(bytes: pdfBytes, filename: file.path.split('/').last),
            ),
          ),
        );
      }
      log.i('PDF esportato: ${file.path}');
    } catch (e) {
      log.e('Errore export PDF', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _print() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      log.e('Errore stampa', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore stampa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final selectedFields = widget.config.selectedFields;
    final etichetta = widget.config.etichetta;

    switch (widget.config.layoutType) {
      case 'etichetta':
        await _generateEtichettePdf(pdf, selectedFields, etichetta);
        break;
      case 'tabella':
        _generateTabellaPdf(pdf, selectedFields);
        break;
      case 'fattura':
        _generateFatturaPdf(pdf, selectedFields);
        break;
      default:
        _generateListaPdf(pdf, selectedFields);
    }

    return pdf.save();
  }

  Future<void> _generateEtichettePdf(
    pw.Document pdf,
    List<ReportField> fields,
    EtichettaConfig config,
  ) async {
    if (config.isCartaTermica) {
      // Carta termica: una etichetta per pagina
      for (final item in widget.data) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              config.larghezza * PdfPageFormat.mm,
              config.altezza * PdfPageFormat.mm,
              marginAll: 0,
            ),
            build: (context) => _buildEtichettaContent(item, fields, config),
          ),
        );
      }
    } else {
      // A4: multiple etichette per pagina
      final etichettaPerPagina = config.etichettaPerRiga * config.etichettaPerColonna;
      final pagine = (widget.data.length / etichettaPerPagina).ceil();

      for (int p = 0; p < pagine; p++) {
        final startIndex = p * etichettaPerPagina;
        final endIndex = (startIndex + etichettaPerPagina).clamp(0, widget.data.length);
        final pageData = widget.data.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.only(
              top: config.bordoSuperiore * PdfPageFormat.mm,
              bottom: config.bordoInferiore * PdfPageFormat.mm,
              left: config.spazioLateraleA4 * PdfPageFormat.mm,
              right: config.spazioLateraleA4 * PdfPageFormat.mm,
            ),
            build: (context) => _buildA4EtichetteGrid(pageData, fields, config),
          ),
        );
      }
    }
  }

  pw.Widget _buildEtichettaContent(
    Map<String, dynamic> item,
    List<ReportField> fields,
    EtichettaConfig config,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.only(
        top: config.bordoSuperiore * PdfPageFormat.mm,
        bottom: config.bordoInferiore * PdfPageFormat.mm,
        left: config.bordoSinistro * PdfPageFormat.mm,
        right: config.bordoDestro * PdfPageFormat.mm,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: fields.map((field) {
          final value = item[field.name];
          if (value == null) return pw.SizedBox.shrink();
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(
              '${field.label}: ${_formatValue(value, field.type)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildA4EtichetteGrid(
    List<Map<String, dynamic>> data,
    List<ReportField> fields,
    EtichettaConfig config,
  ) {
    final rows = <pw.TableRow>[];

    for (int r = 0; r < config.etichettaPerColonna; r++) {
      final cells = <pw.Widget>[];

      for (int c = 0; c < config.etichettaPerRiga; c++) {
        final index = r * config.etichettaPerRiga + c;
        if (index < data.length) {
          cells.add(
            pw.Container(
              width: config.larghezza * PdfPageFormat.mm,
              height: config.altezza * PdfPageFormat.mm,
              margin: pw.EdgeInsets.all(config.spaziaturaTra / 2 * PdfPageFormat.mm),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: _buildEtichettaContent(data[index], fields, config),
            ),
          );
        } else {
          cells.add(pw.SizedBox(
            width: config.larghezza * PdfPageFormat.mm,
            height: config.altezza * PdfPageFormat.mm,
          ));
        }
      }

      rows.add(pw.TableRow(children: cells));
    }

    return pw.Table(children: rows);
  }

  void _generateTabellaPdf(pw.Document pdf, List<ReportField> fields) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              widget.config.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: fields.map((f) => f.label).toList(),
            data: widget.data.map((item) {
              return fields.map((f) {
                final value = item[f.name];
                return value != null ? _formatValue(value, f.type) : '-';
              }).toList();
            }).toList(),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  void _generateListaPdf(pw.Document pdf, List<ReportField> fields) {
    for (final item in widget.data) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  widget.config.name,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 16),
              ...fields.map((field) {
                final value = item[field.name];
                if (value == null) return pw.SizedBox.shrink();
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 150,
                        child: pw.Text(
                          '${field.label}:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(_formatValue(value, field.type)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }
  }

  void _generateFatturaPdf(pw.Document pdf, List<ReportField> fields) {
    for (final item in widget.data) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Intestazione fattura
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FATTURA',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        widget.config.name,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Contenuto
              ...fields.map((field) {
                final value = item[field.name];
                if (value == null) return pw.SizedBox.shrink();
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        field.label,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        _formatValue(value, field.type),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generato il ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatValue(dynamic value, Type type) {
    if (value == null) return '-';
    if (type == DateTime && value is DateTime) {
      return DateFormat('dd/MM/yyyy').format(value);
    }
    if (type == double && value is num) {
      return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(value);
    }
    if (type == bool) {
      return value == true ? 'Sì' : 'No';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFields = widget.config.selectedFields;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
            tooltip: 'Esporta PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _print,
            tooltip: 'Stampa',
          ),
        ],
      ),
      body: widget.data.isEmpty
          ? const Center(child: Text('Nessun dato da visualizzare'))
          : Column(
              children: [
                // Navigazione pagine
                if (widget.data.length > 1 && widget.config.layoutType != 'tabella')
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        Text(
                          '${_currentPage + 1} / ${widget.data.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < widget.data.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),

                // Contenuto
                Expanded(
                  child: widget.config.layoutType == 'tabella'
                      ? _buildTableView(selectedFields)
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: widget.data.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildPageView(widget.data[index], selectedFields);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTableView(List<ReportField> fields) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: fields.map((f) => DataColumn(label: Text(f.label))).toList(),
          rows: widget.data.map((item) {
            return DataRow(
              cells: fields.map((f) {
                final value = item[f.name];
                return DataCell(
                  Text(value != null ? _formatValue(value, f.type) : '-'),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPageView(Map<String, dynamic> item, List<ReportField> fields) {
    switch (widget.config.layoutType) {
      case 'etichetta':
        return _buildEtichettaPreview(item, fields);
      case 'fattura':
        return _buildFatturaPreview(item, fields);
      default:
        return _buildListaPreview(item, fields);
    }
  }

  Widget _buildEtichettaPreview(Map<String, dynamic> item, List<ReportField> fields) {
    final config = widget.config.etichetta;
    return Center(
      child: Container(
        width: config.larghezza * 3, // Scale per preview
        height: config.altezza * 3,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.all(config.bordoSinistro * 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: fields.map((field) {
            final value = item[field.name];
            if (value == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${field.label}: ${_formatValue(value, field.type)}',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFatturaPreview(Map<String, dynamic> item, List<ReportField> fields) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FATTURA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  widget.config.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Campi
            ...fields.map((field) {
              final value = item[field.name];
              if (value == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(field.label),
                    Text(
                      _formatValue(value, field.type),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListaPreview(Map<String, dynamic> item, List<ReportField> fields) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields.map((field) {
              final value = item[field.name];
              if (value == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${field.label}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(value, field.type),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
