import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reservation_model.dart';
import '../../../data/providers/reservation_provider.dart';

class MesVoyagesScreen extends StatefulWidget {
  const MesVoyagesScreen({super.key});
  @override
  State<MesVoyagesScreen> createState() => _MesVoyagesScreenState();
}

class _MesVoyagesScreenState extends State<MesVoyagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().chargerMesReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    // Filtrer par statut
    final aVenir  = provider.reservations
        .where((r) => r.statut == 'confirmee' || r.statut == 'en_attente')
        .toList();
    final enCours = provider.reservations
        .where((r) => r.statut == 'embarquee')
        .toList();
    final termines = provider.reservations
        .where((r) => r.statut == 'annulee')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(children: [
            // Titre + retour
            Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes Voyages',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Historique & réservations',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              // Compteur total
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.reservations.length} voyage(s)',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Stats rapides
            Row(children: [
              _HeaderStat(
                  label: 'À venir',
                  value: '${aVenir.length}',
                  color: Colors.white),
              _HeaderDivider(),
              _HeaderStat(
                  label: 'En cours',
                  value: '${enCours.length}',
                  color: AppColors.accent),
              _HeaderDivider(),
              _HeaderStat(
                  label: 'Annulés',
                  value: '${termines.length}',
                  color: Colors.white70),
            ]),

            const SizedBox(height: 20),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: const Color(0xFF6C63FF),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'À venir (${aVenir.length})'),
                  Tab(text: 'En cours (${enCours.length})'),
                  Tab(text: 'Annulés'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        // ── Contenu
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF6C63FF)))
              : TabBarView(
            controller: _tabController,
            children: [
              _VoyagesListe(
                reservations: aVenir,
                emptyIcon:    Icons.flight_takeoff_rounded,
                emptyMsg:     'Aucun voyage à venir',
                emptySub:     'Faites une réservation pour voyager',
                showCancel:   true,
              ),
              _VoyagesListe(
                reservations: enCours,
                emptyIcon:    Icons.directions_bus_rounded,
                emptyMsg:     'Aucun voyage en cours',
                emptySub:     'Vos voyages actifs apparaîtront ici',
                showCancel:   false,
              ),
              _VoyagesListe(
                reservations: termines,
                emptyIcon:    Icons.history_rounded,
                emptyMsg:     'Aucun voyage annulé',
                emptySub:     'Votre historique sera ici',
                showCancel:   false,
              ),
            ],
          ),
        ),
      ]),

      // FAB nouvelle réservation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/reservation'),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouvelle réservation',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Stat dans le header
class _HeaderStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderStat({required this.label, required this.value,
    required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(color: color,
          fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(
          color: color.withOpacity(0.8), fontSize: 11)),
    ]),
  );
}

class _HeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 30,
    color: Colors.white.withOpacity(0.3),
  );
}

// ── Liste des voyages
class _VoyagesListe extends StatelessWidget {
  final List<ReservationModel> reservations;
  final IconData emptyIcon;
  final String emptyMsg, emptySub;
  final bool showCancel;

  const _VoyagesListe({
    required this.reservations,
    required this.emptyIcon,
    required this.emptyMsg,
    required this.emptySub,
    required this.showCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon,
                    color: const Color(0xFF6C63FF), size: 48)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(emptySub, style: const TextStyle(fontSize: 13,
                color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      onRefresh: () => context.read<ReservationProvider>()
          .chargerMesReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: reservations.length,
        itemBuilder: (_, i) => _VoyageDetailCard(
          reservation: reservations[i],
          showCancel:  showCancel,
        ),
      ),
    );
  }
}

// ── Carte voyage détaillée
class _VoyageDetailCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool showCancel;
  const _VoyageDetailCard({
    required this.reservation, required this.showCancel});

  Color get _statutColor {
    switch (reservation.statut) {
      case 'confirmee':  return AppColors.success;
      case 'embarquee':  return AppColors.accent;
      case 'annulee':    return AppColors.error;
      default:           return AppColors.warning;
    }
  }

  String get _statutLabel {
    switch (reservation.statut) {
      case 'confirmee':  return 'Confirmée';
      case 'embarquee':  return 'Embarquée';
      case 'annulee':    return 'Annulée';
      default:           return 'En attente';
    }
  }

  IconData get _transportIcon {
    switch (reservation.voyage?.typeTransport) {
      case 'aerien':      return Icons.flight_rounded;
      case 'ferroviaire': return Icons.train_rounded;
      default:            return Icons.directions_bus_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    final date = DateTime.parse(dateStr);
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatHeure(String? dateStr) {
    if (dateStr == null) return '--';
    final date = DateTime.parse(dateStr);
    return '${date.hour.toString().padLeft(2,'0')}h'
        '${date.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final v = reservation.voyage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Column(children: [

        // ── Header avec transport et statut
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_transportIcon,
                  color: const Color(0xFF6C63FF), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              v?.typeTransport.toUpperCase() ?? 'TRANSPORT',
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6C63FF),
                  letterSpacing: 1),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_statutLabel,
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statutColor)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [

            // ── Trajet principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Départ
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatHeure(v?.dateDepart),
                          style: const TextStyle(fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark)),
                      Text(v?.origine ?? '--',
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text(_formatDate(v?.dateDepart),
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textLight)),
                    ]),

                // Ligne avec avion/bus
                Expanded(
                  child: Column(children: [
                    Row(children: [
                      const Expanded(child: Divider(
                          color: Color(0xFFE2E8F0), thickness: 1.5)),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_transportIcon,
                            color: const Color(0xFF6C63FF), size: 14),
                      ),
                      const Expanded(child: Divider(
                          color: Color(0xFFE2E8F0), thickness: 1.5)),
                    ]),
                    if (v != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _calculerDuree(v.dateDepart, v.dateArrivee),
                        style: const TextStyle(fontSize: 10,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ]),
                ),

                // Arrivée
                Column(crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatHeure(v?.dateArrivee),
                          style: const TextStyle(fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark)),
                      Text(v?.destination ?? '--',
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text(_formatDate(v?.dateArrivee),
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textLight)),
                    ]),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),

            // ── Infos réservation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoBadge(
                  icon: Icons.confirmation_num_outlined,
                  label: 'Code',
                  value: reservation.codeQr,
                  color: const Color(0xFF6C63FF),
                ),
                _InfoBadge(
                  icon: Icons.event_seat_rounded,
                  label: 'Capacité',
                  value: '${v?.capacite ?? '--'} places',
                  color: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Actions
            Row(children: [
              // Voir QR Code
              Expanded(
                child: GestureDetector(
                  onTap: () => _showQrDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_rounded,
                            color: Color(0xFF6C63FF), size: 16),
                        SizedBox(width: 6),
                        Text('QR Code',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C63FF))),
                      ],
                    ),
                  ),
                ),
              ),

              if (showCancel) ...[
                const SizedBox(width: 10),
                // Annuler
                Expanded(
                  child: GestureDetector(
                    onTap: () => _confirmerAnnulation(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: AppColors.error, size: 16),
                          SizedBox(width: 6),
                          Text('Annuler',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 10),
              // Voir bagages
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/bagages'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.luggage_rounded,
                            color: AppColors.accent, size: 16),
                        SizedBox(width: 6),
                        Text('Bagages',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _calculerDuree(String depart, String arrivee) {
    final d = DateTime.parse(depart);
    final a = DateTime.parse(arrivee);
    final diff = a.difference(d);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2,'0')}';
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Votre billet',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(reservation.codeQr,
                style: const TextStyle(fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: reservation.codeQr,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            if (reservation.voyage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.route_rounded,
                        color: Color(0xFF6C63FF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${reservation.voyage!.origine} → '
                          '${reservation.voyage!.destination}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Fermer',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler ce voyage ?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Êtes-vous sûr de vouloir annuler la réservation '
                '${reservation.codeQr} ?',
            style: const TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ReservationProvider>()
                  .annulerReservation(reservation.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation annulée'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Badge info
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoBadge({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 12,
                color: color, fontWeight: FontWeight.w800)),
          ]),
    ]),
  );
}