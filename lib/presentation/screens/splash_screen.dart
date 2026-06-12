import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _bgCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset>  _textSlide;
  late Animation<double> _bgScale;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200));
    _logoCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700));

    _bgScale = Tween<double>(begin: 1.3, end: 1.0)
        .animate(CurvedAnimation(
        parent: _bgCtrl, curve: Curves.easeOutCubic));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5,
            curve: Curves.easeIn)));

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _textCtrl, curve: Curves.easeOutCubic));

    _demarrerAnimations();
  }

  Future<void> _demarrerAnimations() async {
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _naviguer();
  }

  Future<void> _naviguer() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ En mode debug : toujours montrer l'onboarding
      // Supprime ce bloc en production
      if (kDebugMode) {
        await prefs.setBool('onboarding_vu', false);
      }

      final onboardingVu = prefs.getBool('onboarding_vu') ?? false;
      if (!mounted) return;

      if (!onboardingVu) {
        context.go('/onboarding');
        return;
      }

      final token = prefs.getString('token');
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        context.go('/login');
        return;
      }

      // Token existe → login pour re-authentifier
      context.go('/login');

    } catch (e) {
      if (mounted) context.go('/login');
    }
  }

  // ✅ Reset complet des préférences (dev uniquement)
  Future<void> _resetPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Préférences réinitialisées — Relancez l\'app'),
        ]),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation:
        Listenable.merge([_bgCtrl, _logoCtrl, _textCtrl]),
        builder: (_, __) => Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond animé
            Transform.scale(
              scale: _bgScale.value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A2342),
                      Color(0xFF1B4F8A),
                      Color(0xFF00D4AA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Cercles décoratifs
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -120, left: -60,
              child: Container(
                width: 350, height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              top: 120, left: -40,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                ),
              ),
            ),

            // ── Contenu central
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animé
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA)
                                .withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Texte animé
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(children: [
                      const Text(
                        'Smart Transport',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Traçabilité intelligente des voyages',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),

            // ── Indicateur chargement en bas
            Positioned(
              bottom: 60,
              left: 0, right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(children: [
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(
                          Colors.white),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Chargement...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      )),
                ]),
              ),
            ),

            // ✅ Bouton reset visible uniquement en mode debug
            if (kDebugMode)
              Positioned(
                bottom: 20, right: 20,
                child: GestureDetector(
                  onTap: _resetPrefs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 4),
                        Text('Reset (dev)',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}