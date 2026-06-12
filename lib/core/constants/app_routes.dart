import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/passager/paiement_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/passager/home_screen.dart';
import '../../presentation/screens/passager/reservation_screen.dart';
import '../../presentation/screens/passager/bagage_suivi_screen.dart';
import '../../presentation/screens/passager/signalement_screen.dart';
import '../../presentation/screens/passager/mes_voyages_screen.dart';
import '../../presentation/screens/passager/profil_screen.dart';
import '../../presentation/screens/agent/agent_home_screen.dart';
import '../../presentation/screens/admin/dashboard_screen.dart';
import '../../presentation/screens/admin/rapport_screen.dart';
import '../../presentation/screens/notifications_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, s) => _fadePage(
            const SplashScreen(), s),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, s) => _fadePage(
            const OnboardingScreen(), s),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, s) => _fadePage(
            const LoginScreen(), s),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (ctx, s) => _slidePage(
            const RegisterScreen(), s),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (ctx, s) => _fadePage(
            const HomeScreen(), s),
      ),
      GoRoute(
        path: '/agent',
        pageBuilder: (ctx, s) => _fadePage(
            const AgentHomeScreen(), s),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (ctx, s) => _fadePage(
            const DashboardScreen(), s),
      ),
      GoRoute(
        path: '/reservation',
        pageBuilder: (ctx, s) => _slidePage(
            const ReservationScreen(), s),
      ),
      GoRoute(
        path: '/bagages',
        pageBuilder: (ctx, s) => _slidePage(
            const BagageSuiviScreen(), s),
      ),
      GoRoute(
        path: '/signalement',
        pageBuilder: (ctx, s) => _slidePage(
            const SignalementScreen(), s),
      ),
      GoRoute(
        path: '/voyages',
        pageBuilder: (ctx, s) => _slidePage(
            const MesVoyagesScreen(), s),
      ),
      GoRoute(
        path: '/profil',
        pageBuilder: (ctx, s) => _slidePage(
            const ProfilScreen(), s),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (ctx, s) => _slidePage(
            const NotificationsScreen(), s),
      ),
      GoRoute(
        path: '/rapports',
        pageBuilder: (ctx, s) => _slidePage(
            const RapportScreen(), s),
      ),
      GoRoute(
        path: '/paiement',
        pageBuilder: (ctx, s) {
          final args = s.extra as Map<String, dynamic>;
          return _slidePage(PaiementScreen(
            reservationId: args['reservationId'],
            montant:       args['montant'],
            origine:       args['origine'],
            destination:   args['destination'],
          ), s);
        },
      ),
    ],
  );

  static CustomTransitionPage _fadePage(
      Widget child, GoRouterState state) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration:
        const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut),
              child: child,
            ),
      );

  static CustomTransitionPage _slidePage(
      Widget child, GoRouterState state) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration:
        const Duration(milliseconds: 320),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(
              curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}