import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/reservation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().chargerStats();
      context.read<ReservationProvider>().chargerMesReservations();
      context.read<NotificationProvider>().rafraichirCompte();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final res     = context.watch<ReservationProvider>();
    final notifs  = context.watch<NotificationProvider>();
    final user    = auth.currentUser;
    final prenom  = user?['prenom'] ?? 'Passager';
    final stats   = res.stats;
    final width   = MediaQuery.of(context).size.width;

    final prochains = res.reservations
        .where((r) => r.statut == 'confirmee' || r.statut == 'en_attente')
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await context.read<ReservationProvider>().chargerStats();
          await context.read<ReservationProvider>().chargerMesReservations();
          await context.read<NotificationProvider>().rafraichirCompte();
        },
        child: CustomScrollView(
          slivers: [
            // ── Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour, $prenom 👋',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                )),
                            const SizedBox(height: 4),
                            Text('Bon voyage !',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                )),
                          ],
                        ),
                        Row(children: [
                          // Bouton notifications avec badge
                          GestureDetector(
                            onTap: () => context.go('/notifications'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(children: [
                                const Icon(Icons.notifications_outlined,
                                    color: Colors.white, size: 20),
                                if (notifs.nonLues > 0)
                                  Positioned(
                                    right: 0, top: 0,
                                    child: Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bouton profil
                          GestureDetector(
                            onTap: () => context.go('/profil'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Déconnexion
                          GestureDetector(
                            onTap: () async {
                              await context.read<AuthProvider>().logout();
                              if (context.mounted) context.go('/login');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.logout_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Barre de recherche
                    GestureDetector(
                      onTap: () => context.go('/reservation'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.search,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Text('Rechercher un voyage...',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Chercher',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.all(width < 360 ? 16 : 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Stats animées
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: Row(children: [
                      _StatCard(
                        icon:  Icons.luggage_rounded,
                        label: 'Bagages',
                        value: '${stats['bagages_actifs'] ?? 0}',
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon:  Icons.confirmation_num_rounded,
                        label: 'Réservations',
                        value: '${stats['total_reservations'] ?? 0}',
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon:  Icons.notifications_rounded,
                        label: 'Alertes',
                        value: '${notifs.nonLues}',
                        color: notifs.nonLues > 0
                            ? AppColors.error : AppColors.primaryLight,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Actions rapides animées
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: Column(children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Actions rapides',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                      ),
                      const SizedBox(height: 16),
                      // ✅ GridView complet avec itemCount et itemBuilder
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:   2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing:  14,
                          mainAxisExtent:   width < 360 ? 110 : 130,
                        ),
                        itemCount: 4,
                        itemBuilder: (_, i) {
                          final cards = [
                            _ActionCard(
                              icon:     Icons.add_circle_outline_rounded,
                              label:    'Nouvelle\nRéservation',
                              gradient: AppColors.primaryGradient,
                              onTap:    () => context.go('/reservation'),
                              badge:    null,
                            ),
                            _ActionCard(
                              icon:     Icons.luggage_rounded,
                              label:    'Suivi\nBagage',
                              gradient: AppColors.accentGradient,
                              onTap:    () => context.go('/bagages'),
                              badge:    (stats['bagages_actifs'] ?? 0) > 0
                                  ? '${stats['bagages_actifs']}' : null,
                            ),
                            _ActionCard(
                              icon:     Icons.report_problem_outlined,
                              label:    'Signaler\nune perte',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B35),
                                  Color(0xFFFF8C42)
                                ],
                              ),
                              onTap:    () => context.go('/signalement'),
                              badge:    notifs.nonLues > 0
                                  ? '${notifs.nonLues}' : null,
                            ),
                            _ActionCard(
                              icon:     Icons.history_rounded,
                              label:    'Mes\nVoyages',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF9B8FFF)
                                ],
                              ),
                              onTap:    () => context.go('/voyages'),
                              badge:    (stats['voyages_a_venir'] ?? 0) > 0
                                  ? '${stats['voyages_a_venir']}' : null,
                            ),
                          ];
                          // Animation par carte avec délai
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                                milliseconds: 400 + i * 100),
                            curve: Curves.easeOutBack,
                            builder: (_, v, child) => Transform.scale(
                              scale: v.clamp(0.0, 1.0),
                              child: Opacity(
                                  opacity: v.clamp(0.0, 1.0),
                                  child: child),
                            ),
                            child: cards[i],
                          );
                        },
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Voyages à venir animés
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Voyages à venir',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          TextButton(
                            onPressed: () => context.go('/voyages'),
                            child: const Text('Voir tout',
                                style: TextStyle(color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (res.isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ))
                      else if (prochains.isEmpty)
                        _EmptyVoyages(
                            onTap: () => context.go('/reservation'))
                      else
                        ...prochains.map((r) => _VoyageCard(
                          origine:     r.voyage?.origine ?? '--',
                          destination: r.voyage?.destination ?? '--',
                          date:        r.voyage?.dateDepart != null
                              ? _formatDate(r.voyage!.dateDepart) : '--',
                          heure:       r.voyage?.dateDepart != null
                              ? _formatHeure(r.voyage!.dateDepart) : '--',
                          type:        r.voyage?.typeTransport ?? '--',
                          statut:      r.statut,
                          codeQr:      r.codeQr,
                        )),
                    ]),
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatHeure(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.hour.toString().padLeft(2,'0')}:'
        '${date.minute.toString().padLeft(2,'0')}';
  }
}

// ════════════════════════════════
//  WIDGETS INTERNES
// ════════════════════════════════

class _EmptyVoyages extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyVoyages({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.flight_takeoff_rounded,
              color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 12),
        const Text('Aucun voyage à venir',
            style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('Appuyez pour réserver',
            style: TextStyle(fontSize: 13,
                color: AppColors.primary.withOpacity(0.7))),
      ]),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final String? badge;
  const _ActionCard({required this.icon, required this.label,
    required this.gradient, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6),
            )],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Text(label, style: const TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700, height: 1.3,
              )),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: gradient.colors.first,
              )),
            ),
          ),
      ],
    ),
  );
}

class _VoyageCard extends StatelessWidget {
  final String origine, destination, date, heure, type, statut, codeQr;
  const _VoyageCard({required this.origine, required this.destination,
    required this.date, required this.heure, required this.type,
    required this.statut, required this.codeQr});

  @override
  Widget build(BuildContext context) {
    final isConfirme = statut == 'confirmee';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.circle, color: AppColors.accent, size: 10),
                const SizedBox(width: 8),
                Text(origine, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: AppColors.textDark)),
              ]),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.textLight, size: 18),
              Row(children: [
                Text(destination, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: AppColors.textDark)),
                const SizedBox(width: 8),
                const Icon(Icons.circle,
                    color: AppColors.accentOrange, size: 10),
              ]),
            ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(icon: Icons.calendar_today_outlined, label: date),
              _InfoChip(icon: Icons.access_time_rounded, label: heure),
              _InfoChip(icon: Icons.directions_bus_rounded, label: type),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirme
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    isConfirme ? 'Confirmé' : 'En attente',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isConfirme
                          ? AppColors.success : AppColors.warning,
                    )),
              ),
            ]),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 12, color: AppColors.textLight),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11,
        color: AppColors.textMedium,
        fontWeight: FontWeight.w500)),
  ]);
}