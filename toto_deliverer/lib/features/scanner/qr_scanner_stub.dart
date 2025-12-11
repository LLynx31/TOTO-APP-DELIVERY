// Stub file for platforms that don't support qr_code_scanner
import 'package:flutter/material.dart';
import 'dart:async';

class Barcode {
  final String? code;
  Barcode(this.code);
}

class QRViewController {
  Stream<Barcode> get scannedDataStream => Stream.empty();

  void pauseCamera() {}
  void resumeCamera() {}
  Future<void> toggleFlash() async {}
  Future<bool?> getFlashStatus() async => false;
  void dispose() {}
}

class QrScannerOverlayShape {
  QrScannerOverlayShape({
    required dynamic borderColor,
    required double borderRadius,
    required int borderLength,
    required int borderWidth,
    required double cutOutSize,
  });
}

class QRView extends StatelessWidget {
  const QRView({
    super.key,
    required this.onQRViewCreated,
    required this.overlay,
  });

  final Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape overlay;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
