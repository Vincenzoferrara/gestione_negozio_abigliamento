// barcode_scanner.dart
//
// Modulo centralizzato per barcode/QR.
// Gestisce grafica, fotocamera, lettura e restituisce al chiamante solo String?.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/theme.dart';

/// Schermata fullscreen per lo scanner di barcode/QR
class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });

      // Restituisci il codice e chiudi
      Navigator.of(context).pop(code);
    }
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.primaryColor,
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scansiona Barcode/QR',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scanner view
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onBarcodeDetected,
                  ),

                  // Overlay con area di scansione
                  CustomPaint(
                    painter: ScannerOverlayPainter(
                      primaryColor: theme.primaryColor,
                    ),
                    child: Container(),
                  ),

                  // Indicatore stato
                  if (!_isScanning)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.successColor,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Codice rilevato!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer con controlli
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bottone torcia
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      final bool isTorchAvailable =
                          value.torchState != TorchState.unavailable;
                      final bool isTorchOn = value.torchState == TorchState.on;

                      return IconButton.filled(
                        onPressed: isTorchAvailable ? _toggleTorch : null,
                        icon: Icon(
                          isTorchOn ? Icons.flash_on : Icons.flash_off,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isTorchOn
                              ? AppTheme.warningColor
                              : Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // Info
                  const Expanded(
                    child: Text(
                      'Inquadra il barcode o QR code del prodotto',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
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

/// Painter per l'overlay dello scanner con area di scansione
class ScannerOverlayPainter extends CustomPainter {
  final Color primaryColor;

  ScannerOverlayPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Disegna l'overlay scuro
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)));

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Disegna il bordo dell'area di scansione
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
      paint,
    );

    // Disegna gli angoli
    const double cornerLength = 30;
    final cornerPaint = Paint()
      ..color = AppTheme.successColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Angolo in alto a sinistra
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Angolo in alto a destra
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Angolo in basso a sinistra
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Angolo in basso a destra
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Funzione helper per aprire lo scanner a schermo intero.
Future<String?> showBarcodeScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (context) => const BarcodeScannerDialog(),
    ),
  );
}
