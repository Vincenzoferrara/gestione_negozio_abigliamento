import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'class_etichette.dart';

/// Controller per la gestione delle etichette
class EtichetteController {
  final List<Etichetta> _etichetteDaStampare = [];
  EtichetteSettings _settings = const EtichetteSettings();

  List<Etichetta> get etichetteDaStampare => List.unmodifiable(_etichetteDaStampare);
  EtichetteSettings get settings => _settings;

  /// Aggiunge un'etichetta alla coda di stampa
  void aggiungiEtichetta(Etichetta etichetta) {
    _etichetteDaStampare.add(etichetta);
  }

  /// Aggiunge multiple etichette
  void aggiungiEtichette(List<Etichetta> etichette) {
    _etichetteDaStampare.addAll(etichette);
  }

  /// Rimuove un'etichetta dalla coda
  void rimuoviEtichetta(int index) {
    if (index >= 0 && index < _etichetteDaStampare.length) {
      _etichetteDaStampare.removeAt(index);
    }
  }

  /// Svuota la coda di stampa
  void svuotaCoda() {
    _etichetteDaStampare.clear();
  }

  /// Aggiorna le impostazioni
  void aggiornaSettings(EtichetteSettings newSettings) {
    _settings = newSettings;
  }

  /// Genera il PDF delle etichette
  Future<Uint8List> generaPdf() async {
    final pdf = pw.Document();

    final pageFormat = PdfPageFormat(
      _settings.larghezzaEtichetta * PdfPageFormat.mm * _settings.etichettaPerRiga + 20 * PdfPageFormat.mm,
      _settings.altezzaEtichetta * PdfPageFormat.mm * _settings.etichettaPerColonna + 20 * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    );

    // Calcola quante etichette per pagina
    final etichettaPerPagina = _settings.etichettaPerRiga * _settings.etichettaPerColonna;
    final numPagine = (_etichetteDaStampare.length / etichettaPerPagina).ceil();

    for (int pagina = 0; pagina < numPagine; pagina++) {
      final startIndex = pagina * etichettaPerPagina;
      final endIndex = (startIndex + etichettaPerPagina).clamp(0, _etichetteDaStampare.length);
      final etichettePagina = _etichetteDaStampare.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: _settings.etichettaPerRiga,
              childAspectRatio: _settings.larghezzaEtichetta / _settings.altezzaEtichetta,
              children: etichettePagina.map((e) => _buildEtichettaPdf(e)).toList(),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Costruisce una singola etichetta per il PDF
  pw.Widget _buildEtichettaPdf(Etichetta etichetta) {
    return pw.Container(
      width: _settings.larghezzaEtichetta * PdfPageFormat.mm,
      height: _settings.altezzaEtichetta * PdfPageFormat.mm,
      padding: pw.EdgeInsets.only(
        top: _settings.margineSup * PdfPageFormat.mm,
        bottom: _settings.margineInf * PdfPageFormat.mm,
        left: _settings.margineSx * PdfPageFormat.mm,
        right: _settings.margineDx * PdfPageFormat.mm,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Nome prodotto
          pw.Text(
            etichetta.nome,
            style: pw.TextStyle(
              fontSize: _settings.fontSizeNome,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 2),

          // Riga con taglia e colore
          if (_settings.mostraTaglia || _settings.mostraColore)
            pw.Row(
              children: [
                if (_settings.mostraTaglia && etichetta.taglia != null)
                  pw.Text('Tg: ${etichetta.taglia}', style: const pw.TextStyle(fontSize: 8)),
                if (_settings.mostraTaglia && _settings.mostraColore && etichetta.taglia != null && etichetta.colore != null)
                  pw.Text(' | ', style: const pw.TextStyle(fontSize: 8)),
                if (_settings.mostraColore && etichetta.colore != null)
                  pw.Text('Col: ${etichetta.colore}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),

          // SKU
          if (_settings.mostraSku && etichetta.sku != null)
            pw.Text(
              'SKU: ${etichetta.sku}',
              style: const pw.TextStyle(fontSize: 7),
            ),

          pw.Spacer(),

          // Riga inferiore con prezzo e QR/Barcode
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (_settings.mostraPrezzo)
                pw.Text(
                  '${etichetta.prezzo.toStringAsFixed(2)} EUR',
                  style: pw.TextStyle(
                    fontSize: _settings.fontSizePrezzo,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (_settings.mostraQrCode)
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: etichetta.generaContenutoQr(),
                  width: _settings.dimensioneQr * PdfPageFormat.mm,
                  height: _settings.dimensioneQr * PdfPageFormat.mm,
                )
              else if (_settings.mostraBarcode && etichetta.sku != null)
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: etichetta.sku!,
                  width: _settings.dimensioneQr * PdfPageFormat.mm * 2,
                  height: _settings.dimensioneQr * PdfPageFormat.mm * 0.6,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stampa direttamente sulla stampante
  Future<void> stampa() async {
    final pdfData = await generaPdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Etichette_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Esporta il PDF come file
  Future<String> esportaPdf() async {
    final pdfData = await generaPdf();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/etichette_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfData);
    return filePath;
  }

  /// Condivide il PDF
  Future<void> condividiPdf() async {
    final filePath = await esportaPdf();
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Etichette Prodotti',
    );
  }

  /// Anteprima di stampa
  Future<void> mostraAnteprima(BuildContext context) async {
    final pdfData = await generaPdf();
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'etichette_anteprima.pdf',
    );
  }
}

/// Servizio singleton per la gestione delle etichette
class EtichetteService {
  static final EtichetteService _instance = EtichetteService._internal();
  factory EtichetteService() => _instance;
  EtichetteService._internal();

  final EtichetteController _controller = EtichetteController();
  EtichetteController get controller => _controller;
}
