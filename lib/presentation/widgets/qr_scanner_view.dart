import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';

class _QRScannerView extends StatefulWidget {
  final Function(String) onCodeDetecte;
  const _QRScannerView({required this.onCodeDetecte});
  @override
  State<_QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<_QRScannerView> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _detecte = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      MobileScanner(
        controller: _ctrl,
        onDetect: (capture) {
          if (_detecte) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final code = barcodes.first.rawValue;
          if (code == null) return;
          _detecte = true;
          widget.onCodeDetecte(code.toUpperCase());
        },
      ),
      // Overlay viseur
      Center(
        child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.accent, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      // Ligne de scan animée
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -100, end: 100),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (_, v, __) => Transform.translate(
            offset: Offset(0, v),
            child: Container(
              width: 200, height: 2,
              color: AppColors.accent.withOpacity(0.8),
            ),
          ),
          onEnd: () => setState(() {}),
        ),
      ),
    ],
  );
}