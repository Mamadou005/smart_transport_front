import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_transport/data/providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl    = PageController();
  int  _pageCourante = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A2342), Color(0xFF1B4F8A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon:          Icons.directions_bus_rounded,
      iconColor:     Colors.white,
      titre:         'Bienvenue sur\nSmart Transport',
      description:   'La plateforme intelligente de gestion '
          'des voyages, bagages et passagers '
          'en Afrique de l\'Ouest.',
      couleurAccent: const Color(0xFF00D4AA),
    ),
    _OnboardingPage(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B4F8A), Color(0xFF00D4AA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon:          Icons.qr_code_rounded,
      iconColor:     Colors.white,
      titre:         'Réservez\nEn quelques clics',
      description:   'Réservez votre voyage, recevez '
          'un QR code unique et embarquez '
          'sans papier.',
      couleurAccent: Colors.white,
    ),
    _OnboardingPage(
      gradient: const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF00A8C8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon:          Icons.luggage_rounded,
      iconColor:     Colors.white,
      titre:         'Suivez vos bagages\nEn temps réel',
      description:   'Localisez vos bagages à tout moment, '
          'recevez des alertes et signalez '
          'une perte instantanément.',
      couleurAccent: Colors.white,
    ),
    _OnboardingPage(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon:          Icons.notifications_active_rounded,
      iconColor:     Colors.white,
      titre:         'Notifications\nInstantanées',
      description:   'Restez informé à chaque étape : '
          'confirmation, embarquement, '
          'arrivée de vos bagages.',
      couleurAccent: Colors.white,
    ),
  ];

  // ✅ Méthode adaptée pour travailler de concert avec AuthProvider et GoRouter
  Future<void> _terminer() async {
    // 1. Persistance en local (utile si tu veux t'en servir ailleurs ou au premier lancement global)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_vu', true);

    if (mounted) {
      context.read<AuthProvider>().clearOnboarding();
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(children: [
            // Pages
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) =>
                  setState(() => _pageCourante = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) =>
                  _OnboardingPageWidget(page: _pages[i]),
            ),

            // Bouton passer
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: AnimatedOpacity(
                opacity: _pageCourante < _pages.length - 1 ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _terminer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text('Passer',
                        style: TextStyle(color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),

            // Bas — dots + bouton avec padding dynamique
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    constraints.maxHeight < 700 ? 12 : 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots indicateur
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              width: _pageCourante == i ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _pageCourante == i
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                      ),

                      SizedBox(
                          height: constraints.maxHeight < 700 ? 12 : 24),

                      // Bouton suivant / commencer
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pageCourante == _pages.length - 1
                              ? _BtnCommencer(
                            key: const ValueKey('commencer'),
                            onTap: _terminer,
                          )
                              : _BtnSuivant(
                            key: const ValueKey('suivant'),
                            onTap: () => _pageCtrl.nextPage(
                              duration: const Duration(
                                  milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Bouton Commencer
class _BtnCommencer extends StatelessWidget {
  final VoidCallback onTap;
  const _BtnCommencer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20, offset: const Offset(0, 8),
      )],
    ),
    child: ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.arrow_forward_rounded,
          color: Color(0xFF0A2342)),
      label: const Text('Commencer',
          style: TextStyle(
            color: Color(0xFF0A2342),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          )),
    ),
  );
}

// ── Bouton Suivant
class _BtnSuivant extends StatelessWidget {
  final VoidCallback onTap;
  const _BtnSuivant({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 1.5,
      ),
    ),
    child: ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.arrow_forward_rounded,
          color: Colors.white),
      label: const Text('Suivant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
    ),
  );
}

class _OnboardingPage {
  final LinearGradient gradient;
  final IconData icon;
  final Color iconColor;
  final String titre;
  final String description;
  final Color couleurAccent;

  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.titre,
    required this.description,
    required this.couleurAccent,
  });
}

class _OnboardingPageWidget extends StatefulWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});
  @override
  State<_OnboardingPageWidget> createState() =>
      _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState
    extends State<_OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _iconAnim;
  late Animation<double>   _textAnim;
  late Animation<Offset>   _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700));

    _iconAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6,
            curve: Curves.elasticOut)));

    _textAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0,
            curve: Curves.easeOut)));

    _textSlide = Tween<Offset>(
        begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0,
            curve: Curves.easeOutCubic)));

    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall  = constraints.maxHeight < 700;
        final iconSize = isSmall ? 60.0 : 80.0;
        final boxSize  = isSmall ? 120.0 : 160.0;

        return Container(
          decoration: BoxDecoration(gradient: page.gradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isSmall ? 8 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmall ? 40 : 80),

                  // Illustration animée
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, child) => Transform.scale(
                      scale: _iconAnim.value,
                      child: Opacity(
                        opacity: _iconAnim.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: boxSize, height: boxSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 40, spreadRadius: 5,
                        )],
                      ),
                      child: Icon(page.icon,
                          color: page.iconColor, size: iconSize),
                    ),
                  ),

                  SizedBox(height: isSmall ? 24 : 48),

                  // Texte animé
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _textAnim,
                      child: SlideTransition(
                        position: _textSlide,
                        child: child,
                      ),
                    ),
                    child: Column(children: [
                      Text(page.titre,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 22 : 28,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.5,
                          )),
                      SizedBox(height: isSmall ? 10 : 16),
                      Text(page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmall ? 13 : 15,
                            height: 1.6,
                          )),
                    ]),
                  ),

                  SizedBox(height: isSmall ? 100 : 160),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}