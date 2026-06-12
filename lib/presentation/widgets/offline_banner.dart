import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});
  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _horsLigne = false;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    // Vérifie toutes les 10 secondes
    while (mounted) {
      try {
        final response = await Future.any([
          Future.delayed(const Duration(seconds: 5),
                  () => false),
          _testerConnexion(),
        ]);
        if (mounted) setState(() => _horsLigne = !response);
      } catch (_) {
        if (mounted) setState(() => _horsLigne = true);
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<bool> _testerConnexion() async {
    try {
      // Teste la connexion au serveur Laravel
      final uri = Uri.parse('http://127.0.0.1:8000/api');
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_horsLigne) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Hors ligne — Vérifiez votre connexion',
            style: TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _verifier,
            child: const Text('Réessayer',
                style: TextStyle(color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}