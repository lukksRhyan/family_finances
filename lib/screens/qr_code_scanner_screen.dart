import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class QRCodeScannerScreen extends StatelessWidget {
  const QRCodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code da NFC-e')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates, // Evita detecções repetidas
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? url = barcodes.first.rawValue;
            // Garante que o URL não é nulo e que o ecrã ainda está ativo
            if (url != null && context.mounted) {
              // Fecha o scanner e devolve o URL como resultado
              Navigator.of(context).pop(url);
            }
          }
        },
      ),
    );
  }
}