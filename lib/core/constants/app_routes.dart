import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_transport/data/providers/auth_provider.dart';

import 'package:smart_transport/presentation/screens/splash_screen.dart';
import 'package:smart_transport/presentation/screens/onboarding_screen.dart';
import 'package:smart_transport/presentation/screens/auth/login_screen.dart';
import 'package:smart_transport/presentation/screens/auth/register_screen.dart';
import 'package:smart_transport/presentation/screens/notifications_screen.dart';

import 'package:smart_transport/presentation/screens/passager/home_screen.dart';
import 'package:smart_transport/presentation/screens/passager/reservation_screen.dart';
import 'package:smart_transport/presentation/screens/passager/paiement_screen.dart';
import 'package:smart_transport/presentation/screens/passager/bagage_suivi_screen.dart';
import 'package:smart_transport/presentation/screens/passager/signalement_screen.dart';
import 'package:smart_transport/presentation/screens/passager/mes_voyages_screen.dart';
import 'package:smart_transport/presentation/screens/passager/profil_screen.dart';

import 'package:smart_transport/presentation/screens/agent/agent_home_screen.dart';
import 'package:smart_transport/presentation/screens/bagagiste/bagagiste_home_screen.dart';
import 'package:smart_transport/presentation/screens/admin/dashboard_screen.dart';
import 'package:smart_transport/presentation/screens/admin/rapport_screen.dart';

class AppRoutes {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(state, authProvider),
      routes: [
        GoRoute(path: '/splash',
            pageBuilder: (_, s) => _fade(const SplashScreen(), s)),
        GoRoute(path: '/onboarding',
            pageBuilder: (_, s) => _fade(const OnboardingScreen(), s)),
        GoRoute(path: '/login',
            pageBuilder: (_, s) => _fade(const LoginScreen(), s)),
        GoRoute(path: '/register',
            pageBuilder: (_, s) => _slide(const RegisterScreen(), s)),
        GoRoute(path: '/notifications',
            pageBuilder: (_, s) => _slide(const NotificationsScreen(), s)),

        GoRoute(path: '/home',
            pageBuilder: (_, s) => _fade(const HomeScreen(), s)),
        GoRoute(path: '/reservation',
            pageBuilder: (_, s) => _slide(const ReservationScreen(), s)),
        GoRoute(
          path: '/paiement',
          pageBuilder: (_, s) {
            final args = s.extra as Map<String, dynamic>? ?? {};
            return _slide(PaiementScreen(
              reservationId: args['reservationId'] ?? 0,
              montant:       args['montant'] ?? 0,
              origine:       args['origine'] ?? '',
              destination:   args['destination'] ?? '',
            ), s);
          },
        ),
        GoRoute(path: '/bagages',
            pageBuilder: (_, s) => _slide(const BagageSuiviScreen(), s)),
        GoRoute(path: '/signalement',
            pageBuilder: (_, s) => _slide(const SignalementScreen(), s)),
        GoRoute(path: '/voyages',
            pageBuilder: (_, s) => _slide(const MesVoyagesScreen(), s)),
        GoRoute(path: '/profil',
            pageBuilder: (_, s) => _slide(const ProfilScreen(), s)),

        GoRoute(path: '/agent',
            pageBuilder: (_, s) => _fade(const AgentHomeScreen(), s)),
        GoRoute(path: '/bagagiste',
            pageBuilder: (_, s) => _fade(const BagagisteHomeScreen(), s)),
        GoRoute(path: '/dashboard',
            pageBuilder: (_, s) => _fade(const DashboardScreen(), s)),
        GoRoute(path: '/rapports',
            pageBuilder: (_, s) => _slide(const RapportScreen(), s)),
      ],
    );
  }

  static String? _redirect(GoRouterState state, AuthProvider auth) {
    final loc      = state.matchedLocation;
    final connecte = auth.isConnecte;
    final role     = auth.userRole;

    // ── Routes qui ne nécessitent aucune authentification
    const publiques = ['/splash', '/onboarding', '/login', '/register'];

    // ⭐ RÈGLE PRIORITAIRE : Si le flag d'onboarding est levé, on force l'accès direct !
    if (connecte && auth.showOnboarding) {
      if (loc != '/onboarding') return '/onboarding';
      return null;
    }

    // 1. Gestion stricte et automatique de la sortie du Splash
    if (loc == '/splash') {
      if (connecte && role != null) {
        return _espaceParRole(role);
      }
      if (!connecte && !auth.isLoading) {
        return '/login';
      }
      return null; // Reste sur le splash tant que restaurerSession charge
    }

    if (loc == '/onboarding') {
      // Si on est sur l'onboarding mais que le flag est repassé à false (ex: clic sur Commencer)
      if (!auth.showOnboarding && role != null) return _espaceParRole(role);
      return null;
    }

    // 2. Pas connecté → login (sauf routes publiques)
    if (!connecte && !publiques.contains(loc)) return '/login';

    // 3. Connecté sur login/register (sans onboarding actif)
    if (connecte && (loc == '/login' || loc == '/register')) {
      return _espaceParRole(role);
    }

    // 4. Connecté sur une route protégée
    if (connecte && role != null) {
      // Routes accessibles à tous les rôles
      const communes = ['/notifications', '/profil'];
      if (communes.contains(loc)) return null;

      // Mauvais espace → redirige
      if (_mauvaisEspace(loc, role)) return _espaceParRole(role);
    }

    return null;
  }

  static String _espaceParRole(String? role) {
    switch (role) {
      case 'admin':     return '/dashboard';
      case 'agent':     return '/agent';
      case 'bagagiste': return '/bagagiste';
      default:          return '/home';
    }
  }

  static bool _mauvaisEspace(String loc, String role) {
    const passagerRoutes  = ['/home', '/reservation', '/paiement',
      '/bagages', '/signalement', '/voyages'];
    const agentRoutes     = ['/agent'];
    const bagagisteRoutes = ['/bagagiste'];
    const adminRoutes     = ['/dashboard', '/rapports'];

    final estPassager  = passagerRoutes.any((r)  => loc.startsWith(r));
    final estAgent     = agentRoutes.any((r)     => loc.startsWith(r));
    final estBagagiste = bagagisteRoutes.any((r) => loc.startsWith(r));
    final estAdmin     = adminRoutes.any((r)     => loc.startsWith(r));

    switch (role) {
      case 'passager':  return estAgent || estBagagiste || estAdmin;
      case 'agent':     return estPassager || estBagagiste || estAdmin;
      case 'bagagiste': return estPassager || estAgent || estAdmin;
      case 'admin':     return false;
      default:          return false;
    }
  }

  static CustomTransitionPage<void> _fade(Widget child, GoRouterState s) =>
      CustomTransitionPage(
        key: s.pageKey, child: child,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, c) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: c),
      );

  static CustomTransitionPage<void> _slide(Widget child, GoRouterState s) =>
      CustomTransitionPage(
        key: s.pageKey, child: child,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, c) => SlideTransition(
            position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
            child: c),
      );
}