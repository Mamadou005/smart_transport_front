import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/voyage_model.dart';
import '../../../data/models/reservation_model.dart';
import '../../../data/providers/reservation_provider.dart';
import 'paiement_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _origineCtrl     = TextEditingController();
  final _destinationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().chargerVoyages();
      context.read<ReservationProvider>().chargerMesReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _origineCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Réservations',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Rechercher'),
                  Tab(text: 'Mes réservations'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RechercheTab(
                origineCtrl:     _origineCtrl,
                destinationCtrl: _destinationCtrl,
              ),
              const _MesReservationsTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════
//  ONGLET RECHERCHE
// ════════════════════════════════
class _RechercheTab extends StatelessWidget {
  final TextEditingController origineCtrl;
  final TextEditingController destinationCtrl;

  const _RechercheTab({
    required this.origineCtrl,
    required this.destinationCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Formulaire recherche
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24, offset: const Offset(0, 8),
            )],
          ),
          child: Column(children: [
            _SearchField(
              controller: origineCtrl,
              label: 'Ville de départ',
              hint: 'Ex: Dakar',
              icon: Icons.radio_button_checked,
              iconColor: AppColors.accent,
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            _SearchField(
              controller: destinationCtrl,
              label: 'Ville d\'arrivée',
              hint: 'Ex: Thiès',
              icon: Icons.location_on_rounded,
              iconColor: AppColors.accentOrange,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReservationProvider>().chargerVoyages(
                      origine:     origineCtrl.text,
                      destination: destinationCtrl.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text('Rechercher',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        if (provider.isLoading)
          const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
        else if (provider.voyages.isEmpty)
          _EmptyState(
            icon: Icons.directions_bus_outlined,
            message: 'Aucun voyage trouvé',
            subtitle: 'Modifiez vos critères de recherche',
          )
        else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${provider.voyages.length} voyage(s) trouvé(s)',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text('Résultats',
                    style: TextStyle(fontSize: 12,
                        color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.voyages.map((v) => _VoyageCard(voyage: v)),
          ],
      ]),
    );
  }
}

// ════════════════════════════════
//  CARTE VOYAGE ✅ avec prix
// ════════════════════════════════
class _VoyageCard extends StatelessWidget {
  final VoyageModel voyage;
  const _VoyageCard({required this.voyage});

  IconData get _transportIcon {
    switch (voyage.typeTransport) {
      case 'aerien':      return Icons.flight_rounded;
      case 'ferroviaire': return Icons.train_rounded;
      default:            return Icons.directions_bus_rounded;
    }
  }

  Color get _transportColor {
    switch (voyage.typeTransport) {
      case 'aerien':      return const Color(0xFF6C63FF);
      case 'ferroviaire': return AppColors.accentOrange;
      default:            return AppColors.accent;
    }
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

  // ✅ Formate le montant en XOF
  String _formatPrix(double? prix) {
    if (prix == null || prix == 0) return 'Gratuit';
    final formatted = prix.toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
    );
    return '$formatted XOF';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        // Header carte
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _transportColor.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _transportColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_transportIcon,
                  color: _transportColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(voyage.typeTransport.toUpperCase(),
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _transportColor,
                    letterSpacing: 1)),
            const Spacer(),
            // ✅ Prix affiché dans le header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                  _formatPrix(voyage.prix),
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${voyage.capacite} places',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Trajet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatHeure(voyage.dateDepart),
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text(voyage.origine,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500)),
                    ]),
                Column(children: [
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textLight, size: 20),
                  Text(_formatDate(voyage.dateDepart),
                      style: const TextStyle(fontSize: 10,
                          color: AppColors.textLight)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatHeure(voyage.dateArrivee),
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text(voyage.destination,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500)),
                    ]),
              ],
            ),
            const SizedBox(height: 16),
            // Bouton réserver
            SizedBox(
              width: double.infinity, height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () => _confirmerReservation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Réserver',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      if (voyage.prix != null && voyage.prix! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _formatPrix(voyage.prix),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _confirmerReservation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmationModal(voyage: voyage),
    );
  }
}

// ════════════════════════════════
//  MODAL CONFIRMATION ✅ avec prix + paiement
// ════════════════════════════════
class _ConfirmationModal extends StatelessWidget {
  final VoyageModel voyage;
  const _ConfirmationModal({required this.voyage});

  String _formatPrix(double? prix) {
    if (prix == null || prix == 0) return 'Gratuit';
    final formatted = prix.toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
    );
    return '$formatted XOF';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final hasPrix  = voyage.prix != null && voyage.prix! > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24,
          24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Confirmer la réservation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _ModalRow(label: 'Départ',    value: voyage.origine),
            _ModalRow(label: 'Arrivée',   value: voyage.destination),
            _ModalRow(label: 'Date',
                value: voyage.dateDepart.substring(0, 10)),
            _ModalRow(label: 'Transport',
                value: voyage.typeTransport),
            // ✅ Ligne prix
            if (hasPrix) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prix du billet',
                      style: TextStyle(fontSize: 13,
                          color: AppColors.textLight)),
                  Text(_formatPrix(voyage.prix),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      )),
                ],
              ),
            ],
          ]),
        ),

        // ✅ Note paiement
        if (hasPrix) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1DA1F2).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1DA1F2).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.payment_rounded,
                  color: Color(0xFF1DA1F2), size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'Paiement par Wave, Orange Money ou espèces '
                    'après la réservation.',
                style: TextStyle(fontSize: 12,
                    color: AppColors.textMedium, height: 1.4),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () async {
                final res = await context
                    .read<ReservationProvider>()
                    .creerReservation(voyage.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res != null) {
                  // ✅ Si voyage payant → aller au paiement
                  if (hasPrix) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaiementScreen(
                          reservationId: res.id,
                          montant:       voyage.prix!,
                          origine:       voyage.origine,
                          destination:   voyage.destination,
                        ),
                      ),
                    );
                  } else {
                    // Gratuit → afficher QR directement
                    _showSuccessDialog(context, res);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(
                  color: Colors.white)
                  : Text(
                  hasPrix
                      ? 'Réserver & Payer ${_formatPrix(voyage.prix)}'
                      : 'Confirmer',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: AppColors.textLight)),
        ),
      ]),
    );
  }

  void _showSuccessDialog(
      BuildContext context, ReservationModel res) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48)),
            const SizedBox(height: 16),
            const Text('Réservation confirmée !',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Code : ${res.codeQr}',
                style: const TextStyle(fontSize: 13,
                    color: AppColors.textMedium)),
            const SizedBox(height: 16),
            QrImageView(
              data: res.codeQr,
              version: QrVersions.auto,
              size: 150,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retour à l\'accueil',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ModalRow extends StatelessWidget {
  final String label, value;
  const _ModalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(
            fontSize: 13, color: AppColors.textLight)),
        Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textDark)),
      ],
    ),
  );
}

// ════════════════════════════════
//  ONGLET MES RÉSERVATIONS
// ════════════════════════════════
class _MesReservationsTab extends StatelessWidget {
  const _MesReservationsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return provider.isLoading
        ? const Center(child: CircularProgressIndicator(
        color: AppColors.primary))
        : provider.reservations.isEmpty
        ? _EmptyState(
      icon: Icons.confirmation_num_outlined,
      message: 'Aucune réservation',
      subtitle: 'Vos réservations apparaîtront ici',
    )
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.reservations.length,
      itemBuilder: (_, i) => _ReservationCard(
          reservation: provider.reservations[i]),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  Color get _statusColor {
    switch (reservation.statut) {
      case 'confirmee': return AppColors.success;
      case 'annulee':   return AppColors.error;
      case 'embarquee': return AppColors.accent;
      default:          return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (reservation.statut) {
      case 'confirmee': return '✅ Confirmée';
      case 'annulee':   return '❌ Annulée';
      case 'embarquee': return '🚪 Embarquée';
      default:          return '⏳ En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = reservation.voyage;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(reservation.codeQr,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor)),
                  ),
                ]),
            if (v != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${v.origine} → ${v.destination}',
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    Text(v.dateDepart.substring(0, 10),
                        style: const TextStyle(fontSize: 12,
                            color: AppColors.textLight)),
                  ]),
              // ✅ Prix de la réservation
              if (v.prix != null && v.prix! > 0) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                      '${v.prix!.toStringAsFixed(0)} XOF',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      )),
                ]),
              ],
            ],
            const SizedBox(height: 12),
            // Bouton voir QR
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reservation.codeQr,
                              style: const TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: reservation.codeQr,
                            version: QrVersions.auto,
                            size: 200,
                          ),
                          const SizedBox(height: 8),
                          Text('Montrez ce code à l\'agent',
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textLight)),
                        ]),
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.qr_code_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  const Text('Voir QR Code',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ]),
              ),
            ),
          ]),
    );
  }
}

// ── Widgets communs
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final Color iconColor;
  const _SearchField({required this.controller, required this.label,
    required this.hint, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: iconColor, size: 18),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, subtitle;
  const _EmptyState({required this.icon,
    required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(
            fontSize: 13, color: AppColors.textLight)),
      ],
    ),
  );
}