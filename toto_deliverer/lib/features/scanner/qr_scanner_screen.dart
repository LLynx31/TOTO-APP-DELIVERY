import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/widgets.dart';

// Conditional import for QR scanner
import 'qr_scanner_stub.dart'
    if (dart.library.io) 'package:qr_code_scanner/qr_code_scanner.dart';

enum ScannerMode {
  pickup, // Scan client's QR at pickup - QR ONLY
  delivery; // Scan recipient's QR at delivery - QR OR 4-digit code

  bool get allowManualCode {
    switch (this) {
      case ScannerMode.pickup:
        return false; // QR scan ONLY at pickup
      case ScannerMode.delivery:
        return true; // QR scan OR manual 4-digit code at delivery
    }
  }
}

class QRScannerScreen extends StatefulWidget {
  final ScannerMode mode;
  final String deliveryId;

  const QRScannerScreen({
    super.key,
    required this.mode,
    required this.deliveryId,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  // Manual code entry
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late bool _showManualEntry;

  @override
  void initState() {
    super.initState();
    // Start with manual entry on web only if mode allows it
    // For pickup mode, manual entry is NEVER allowed (QR only)
    // For delivery mode, manual entry is allowed
    _showManualEntry = kIsWeb && widget.mode.allowManualCode;
  }

  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb && Platform.isAndroid) {
      controller?.pauseCamera();
    }
    if (!kIsWeb) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _handleScannedCode(scanData.code!);
      }
    });
  }

  void _handleScannedCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Pause camera while processing
    controller?.pauseCamera();

    // Validate the code
    bool isValid = await _validateCode(code);

    if (!mounted) return;

    if (isValid) {
      _showSuccessDialog();
    } else {
      _showErrorDialog();
    }
  }

  Future<bool> _validateCode(String code) async {
    // Simulate API call to validate the code
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, this would:
    // 1. Send code to backend
    // 2. Verify it matches the delivery
    // 3. Update delivery status

    // For now, accept any code that contains the delivery ID or is a 4-digit number
    return code.contains(widget.deliveryId) ||
           (code.length == 4 && int.tryParse(code) != null);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 64,
          ),
          title: Text(
            widget.mode == ScannerMode.pickup
                ? 'Colis récupéré !'
                : 'Livraison confirmée !',
            textAlign: TextAlign.center,
          ),
          content: Text(
            widget.mode == ScannerMode.pickup
                ? 'Vous pouvez maintenant vous rendre au point de livraison'
                : 'Le destinataire a confirmé la réception du colis',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          actions: [
            CustomButton(
              text: 'Continuer',
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return success to tracking screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 64,
          ),
          title: const Text(
            'Code invalide',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Le code QR scanné ne correspond pas à cette livraison. Veuillez réessayer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          actions: [
            CustomButton(
              text: 'Réessayer',
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = false;
                });
                controller?.resumeCamera();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleFlash() async {
    await controller?.toggleFlash();
    final flashState = await controller?.getFlashStatus();
    setState(() {
      _isFlashOn = flashState ?? false;
    });
  }

  void _handleManualEntry() {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    _handleScannedCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textWhite,
        title: Text(
          widget.mode == ScannerMode.pickup
              ? AppStrings.scanCustomerQR
              : AppStrings.scanRecipientQR,
          style: const TextStyle(color: AppColors.textWhite),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: AppColors.textWhite,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner (only on mobile)
          if (!_showManualEntry && !kIsWeb)
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: AppSizes.radiusMd,
                borderLength: 40,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),

          // Manual Entry Mode
          if (_showManualEntry)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dialpad,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSizes.spacingLg),
                  Text(
                    AppStrings.enterCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textWhite,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingXl),
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      controller: _codeController,
                      label: 'Code à 4 chiffres',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le code';
                        }
                        if (value.length != 4) {
                          return 'Le code doit contenir 4 chiffres';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Le code doit contenir uniquement des chiffres';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingLg),
                  CustomButton(
                    text: AppStrings.validate,
                    onPressed: _handleManualEntry,
                    isLoading: _isProcessing,
                  ),
                ],
              ),
            ),

          // Bottom Info and Actions
          if (!_isProcessing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: AppSizes.paddingLg,
                  right: AppSizes.paddingLg,
                  top: AppSizes.paddingLg,
                  bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingLg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    if (!_showManualEntry) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.mode == ScannerMode.pickup
                              ? 'Demandez au client de vous montrer son code QR'
                              : 'Demandez au destinataire de vous montrer son code QR',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textWhite,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingMd),
                    ],
                    // Only show toggle button on mobile AND if manual code is allowed
                    // For pickup mode, manual entry is disabled (QR only)
                    if (!kIsWeb && widget.mode.allowManualCode)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showManualEntry = !_showManualEntry;
                          });
                          if (_showManualEntry) {
                            controller?.pauseCamera();
                          } else {
                            controller?.resumeCamera();
                            _codeController.clear();
                          }
                        },
                        icon: Icon(
                          _showManualEntry ? Icons.qr_code_scanner : Icons.dialpad,
                        ),
                        label: Text(
                          _showManualEntry
                              ? 'Scanner un code QR'
                              : AppStrings.manualCode,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textWhite,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Processing Overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: AppSizes.spacingLg),
                      Text(
                        'Vérification du code...',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
