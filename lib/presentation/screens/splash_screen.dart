import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_transport/core/constants/app_colors.dart';
import 'package:smart_transport/data/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Durée minimale d'affichage du splash
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Essaie de restaurer la session
    final sessionValide = await auth.restaurerSession();
    if (!mounted) return;

    if (sessionValide) {
      // ✅ Session valide → espace du rôle directement (pas d'onboarding)
      switch (auth.userRole) {
        case 'admin':
          context.go('/dashboard');
          break;
        case 'agent':
          context.go('/agent');
          break;
        case 'bagagiste':
          context.go('/bagagiste');
          break;
        default:
          context.go('/home');
          break;
      }
    } else {
      // Pas de session → login
      context.go('/login');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF0D3B6E)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 58),
                ),
                const SizedBox(height: 28),
                const Text('Smart Transport',
                    style: TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5,
                    )),
                const SizedBox(height: 8),
                Text('Traçabilité intelligente des voyages',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14)),
                const SizedBox(height: 60),
                SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2.5),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}