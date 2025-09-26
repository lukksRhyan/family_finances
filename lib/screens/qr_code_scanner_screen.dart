import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class QRCodeScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: MobileScanner(
        onDetect: (barcode) {
          final String code = barcode.toString();
          print('Barcode found: $code');
        },
      ),
    );
  }
}