// Fichier : lib/presentation/screens/bagagiste/bagagiste_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/bagagiste_provider.dart';

class BagagisteHomeScreen extends StatefulWidget {
  const BagagisteHomeScreen({super.key});
  @override
  State<BagagisteHomeScreen> createState() => _BagagisteHomeScreenState();
}

class _BagagisteHomeScreenState extends State<BagagisteHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BagagisteProvider>();
      p.chargerStats();
      p.chargerBagages();
      p.chargerSignalements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final prov = context.watch<BagagisteProvider>();
    final stats = prov.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── HEADER
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.bagagisteGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(children: [
            // Top bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Espace Bagagiste',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                    'Bonjour, ${user?['prenom'] ?? 'Bagagiste'} 👋',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ]),
              Row(children: [
                _HBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    prov.chargerStats();
                    prov.chargerBagages();
                    prov.chargerSignalements();
                  },
                ),
                const SizedBox(width: 8),
                _HBtn(
                  icon: Icons.logout_rounded,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (mounted) context.go('/login');
                  },
                ),
              ]),
            ]),

            const SizedBox(height: 10),

            // Badge service
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.luggage_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Service Bagages',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Stats du jour
            Row(children: [
              _StatItem(
                icon: Icons.luggage_rounded,
                value: '${stats['enregistres_aujourd_hui'] ?? 0}',
                label: 'Enregistrés',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.local_shipping_rounded,
                value: '${stats['en_transit'] ?? 0}',
                label: 'En transit',
                color: const Color(0xFF00D4AA),
              ),
              _StatItem(
                icon: Icons.check_circle_rounded,
                value: '${stats['recuperes_aujourd_hui'] ?? 0}',
                label: 'Récupérés',
                color: Colors.white70,
              ),
              _StatItem(
                icon: Icons.warning_rounded,
                value: '${stats['perdus'] ?? 0}',
                label: 'Perdus',
                color: (stats['perdus'] ?? 0) > 0
                    ? Colors.redAccent
                    : Colors.white54,
              ),
            ]),

            const SizedBox(height: 16),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                _Tab('Enregistrer', 0, Icons.add_box_rounded),
                _Tab('Mes bagages', 1, Icons.luggage_rounded),
                _Tab('Signalements', 2, Icons.report_problem_rounded),
              ]),
            ),

            const SizedBox(height: 16),
          ]),
        ),

        // ── CONTENU
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _Tab(String label, int index, IconData icon) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: _tabIndex == index ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 16,
              color: _tabIndex == index
                  ? AppColors.bagagisteAccent
                  : Colors.white70),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _tabIndex == index
                    ? AppColors.bagagisteAccent
                    : Colors.white70,
              )),
        ]),
      ),
    ),
  );

  Widget _buildContent() {
    switch (_tabIndex) {
      case 0:
        return const _EnregistrerTab();
      case 1:
        return const _BagagesTab();
      case 2:
        return const _SignalementsTab();
      default:
        return const SizedBox();
    }
  }
}

// ════════════════════════════════════════
// ONGLET 1 — ENREGISTRER UN BAGAGE
// ════════════════════════════════════════
class _EnregistrerTab extends StatefulWidget {
  const _EnregistrerTab({super.key});
  @override
  State<_EnregistrerTab> createState() => _EnregistrerTabState();
}

class _EnregistrerTabState extends State<_EnregistrerTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  bool _recherche = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _poidsCtrl.dispose();
    super.dispose();
  }

  Future<void> _chercherReservation() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _recherche = true);
    final ok = await context
        .read<BagagisteProvider>()
        .chercherReservation(_codeCtrl.text.trim().toUpperCase());
    setState(() => _recherche = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<BagagisteProvider>().errorMessage ??
            'Réservation introuvable'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<BagagisteProvider>();
    if (prov.reservationTrouvee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cherchez d\'abord une réservation'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await prov.enregistrerBagage(
      reservationId: prov.reservationTrouvee!['id'],
      poids: double.parse(_poidsCtrl.text),
      description: _descCtrl.text.isEmpty ? 'Bagage' : _descCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _showSucces(prov.bagages.isNotEmpty ? prov.bagages.first : {});
      _codeCtrl.clear();
      _descCtrl.clear();
      _poidsCtrl.clear();
      prov.clearReservationTrouvee();
      prov.chargerBagages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(prov.errorMessage ?? 'Erreur enregistrement'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSucces(Map<String, dynamic> bagage) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bagagisteAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.luggage_rounded,
                  color: AppColors.bagagisteAccent, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Bagage enregistré !',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Text(bagage['code_qr'] ?? '',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.bagagisteAccent)),
                const SizedBox(height: 4),
                Text(
                    '${bagage['poids'] ?? _poidsCtrl.text} kg · ${bagage['description'] ?? 'Bagage'}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bagagisteAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Parfait !',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BagagisteProvider>();
    final res = prov.reservationTrouvee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [

          // ── Chercher réservation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                      icon: Icons.confirmation_num_rounded,
                      label: 'Code de réservation',
                      color: AppColors.primaryLight),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Ex: RES-ABCD1234',
                          hintStyle: const TextStyle(
                              color: AppColors.textLight, fontSize: 13),
                          prefixIcon: const Icon(Icons.qr_code_rounded,
                              color: AppColors.primaryLight),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_rounded,
                                color: AppColors.textLight, size: 18),
                            onPressed: () async {
                              final d = await Clipboard.getData('text/plain');
                              if (d?.text != null) {
                                setState(() => _codeCtrl.text =
                                    d!.text!.trim().toUpperCase());
                              }
                            },
                          ),
                        ),
                        onSubmitted: (_) => _chercherReservation(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _recherche ? null : _chercherReservation,
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.bagagisteDark, AppColors.bagagisteLight],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _recherche
                            ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.search_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ]),

                  // Résultat de la recherche
                  if (res != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bagagisteAccent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.bagagisteAccent.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bagagisteAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: AppColors.bagagisteAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${res['user']?['prenom'] ?? ''} ${res['user']?['nom'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark)),
                                  if (res['voyage'] != null)
                                    Text(
                                        '${res['voyage']['origine']} → ${res['voyage']['destination']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textLight)),
                                  Text('Code: ${res['code_qr'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w600)),
                                ])),
                        GestureDetector(
                          onTap: () => context
                              .read<BagagisteProvider>()
                              .clearReservationTrouvee(),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textLight, size: 20),
                        ),
                      ]),
                    ),
                  ],
                ]),
          ),

          const SizedBox(height: 16),

          // ── Infos du bagage
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                      icon: Icons.luggage_rounded,
                      label: 'Informations du bagage',
                      color: AppColors.bagagisteAccent),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: _inputDeco(
                        label: 'Description',
                        hint: 'Ex: Valise bleue, sac à dos...',
                        icon: Icons.description_outlined,
                        iconColor: AppColors.bagagisteAccent),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _poidsCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDeco(
                        label: 'Poids (kg)',
                        hint: 'Ex: 23.5',
                        icon: Icons.monitor_weight_outlined,
                        iconColor: AppColors.accentOrange),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Poids requis';
                      if (double.tryParse(v) == null) return 'Nombre invalide';
                      if (double.parse(v) <= 0) return 'Poids invalide';
                      return null;
                    },
                  ),
                ]),
          ),

          const SizedBox(height: 24),

          // ── Bouton enregistrer
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.bagagisteDark, AppColors.bagagisteLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bagagisteAccent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: prov.isLoading ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: prov.isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.luggage_rounded, color: Colors.white),
                label: Text(
                  prov.isLoading
                      ? 'Enregistrement...'
                      : 'Enregistrer le bagage',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════
// ONGLET 2 — MES BAGAGES DU JOUR
// ════════════════════════════════════════
class _BagagesTab extends StatefulWidget {
  const _BagagesTab({super.key});
  @override
  State<_BagagesTab> createState() => _BagagesTabState();
}

class _BagagesTabState extends State<_BagagesTab> {
  String _filtre = 'tous';

  final List<Map<String, String>> _filtres = [
    {'key': 'tous', 'label': 'Tous'},
    {'key': 'enregistre', 'label': 'Enregistré'},
    {'key': 'en_transit', 'label': 'En transit'},
    {'key': 'arrive', 'label': 'Arrivé'},
    {'key': 'recupere', 'label': 'Récupéré'},
    {'key': 'perdu', 'label': 'Perdu'},
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BagagisteProvider>();
    final bagages = _filtre == 'tous'
        ? prov.bagages
        : prov.bagages.where((b) => b['statut'] == _filtre).toList();

    return Column(children: [
      // Filtres de statut
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filtres.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filtres[i];
            final isOn = _filtre == f['key'];
            return GestureDetector(
              onTap: () {
                setState(() => _filtre = f['key']!);
                if (f['key'] != 'tous') {
                  context
                      .read<BagagisteProvider>()
                      .chargerBagages(statut: f['key']);
                } else {
                  context.read<BagagisteProvider>().chargerBagages();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isOn
                      ? AppColors.bagagisteAccent
                      : AppColors.bagagisteAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f['label']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOn ? Colors.white : AppColors.bagagisteAccent)),
              ),
            );
          },
        ),
      ),

      Expanded(
        child: prov.isLoading
            ? const Center(
            child: CircularProgressIndicator(
                color: AppColors.bagagisteAccent))
            : RefreshIndicator(
          color: AppColors.bagagisteAccent,
          onRefresh: () => prov.chargerBagages(
              statut: _filtre == 'tous' ? null : _filtre),
          child: bagages.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.luggage_outlined,
                    size: 56,
                    color: AppColors.bagagisteAccent
                        .withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text('Aucun bagage',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: bagages.length,
            itemBuilder: (_, i) => _BagageCard(
              bagage: bagages[i],
              onUpdateStatut: (statut) async {
                final ok = await context
                    .read<BagagisteProvider>()
                    .updateStatutBagage(
                    bagages[i]['id'], statut);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content: Text('Erreur mise à jour'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ),
        ),
      ),
    ]);
  }
}

class _BagageCard extends StatelessWidget {
  final Map<String, dynamic> bagage;
  final Function(String) onUpdateStatut;
  const _BagageCard({required this.bagage, required this.onUpdateStatut});

  Color get _couleur {
    switch (bagage['statut']) {
      case 'enregistre':
        return AppColors.primaryLight;
      case 'en_transit':
        return AppColors.warning;
      case 'arrive':
        return AppColors.success;
      case 'recupere':
        return AppColors.bagagisteAccent;
      case 'perdu':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  String get _statutLabel {
    switch (bagage['statut']) {
      case 'enregistre':
        return '📦 Enregistré';
      case 'en_transit':
        return '🚌 En transit';
      case 'arrive':
        return '✅ Arrivé';
      case 'recupere':
        return '🎉 Récupéré';
      case 'perdu':
        return '⚠️ Perdu';
      default:
        return bagage['statut'] ?? '';
    }
  }

  List<Map<String, String>> get _actionsDisponibles {
    switch (bagage['statut']) {
      case 'enregistre':
        return [
          {'statut': 'en_transit', 'label': '🚌 En transit'},
        ];
      case 'en_transit':
        return [
          {'statut': 'arrive', 'label': '✅ Arrivé'},
          {'statut': 'perdu', 'label': '⚠️ Perdu'},
        ];
      case 'arrive':
        return [
          {'statut': 'recupere', 'label': '🎉 Récupéré'},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = bagage['reservation'];
    final user = res?['user'];
    final voyage = res?['voyage'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.luggage_rounded, color: _couleur, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bagage['description'] ?? 'Bagage',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text(bagage['code_qr'] ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600)),
                  ])),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statutLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _couleur)),
          ),
        ]),

        if (user != null || voyage != null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            if (user != null)
              Expanded(
                child: Row(children: [
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                        '${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            if (bagage['poids'] != null)
              Text('${bagage['poids']} kg',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight)),
          ]),
          if (voyage != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.route_rounded,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                  '${voyage['origine'] ?? ''} → ${voyage['destination'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
            ]),
          ],
        ],

        // Boutons d'action
        if (_actionsDisponibles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ..._actionsDisponibles.map((a) => GestureDetector(
              onTap: () => onUpdateStatut(a['statut']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _couleur.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _couleur.withOpacity(0.3)),
                ),
                child: Text(a['label']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _couleur)),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════
// ONGLET 3 — SIGNALEMENTS
// ════════════════════════════════════════
class _SignalementsTab extends StatefulWidget {
  const _SignalementsTab({super.key});
  @override
  State<_SignalementsTab> createState() => _SignalementsTabState();
}

class _SignalementsTabState extends State<_SignalementsTab> {
  String _filtre = 'tous';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<BagagisteProvider>().chargerSignalements();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BagagisteProvider>();
    final sigs = _filtre == 'tous'
        ? prov.signalements
        : prov.signalements
        .where((s) => s['statut'] == _filtre)
        .toList();

    return Column(children: [
      // Filtres
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final items = [
              {'key': 'tous', 'label': 'Tous'},
              {'key': 'ouvert', 'label': '🔴 Ouverts'},
              {'key': 'en_cours', 'label': '🔍 En cours'},
            ];
            final f = items[i];
            final isOn = _filtre == f['key'];
            return GestureDetector(
              onTap: () => setState(() => _filtre = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isOn
                      ? AppColors.accentOrange
                      : AppColors.accentOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f['label']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOn ? Colors.white : AppColors.accentOrange)),
              ),
            );
          },
        ),
      ),

      Expanded(
        child: prov.isLoading
            ? const Center(
            child: CircularProgressIndicator(
                color: AppColors.accentOrange))
            : RefreshIndicator(
          color: AppColors.accentOrange,
          onRefresh: () => prov.chargerSignalements(),
          child: sigs.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 56,
                    color: AppColors.success.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Aucun signalement',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium)),
                const SizedBox(height: 6),
                const Text('Tous les bagages sont en ordre',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: sigs.length,
            itemBuilder: (_, i) => _SignalementCard(
              signalement: sigs[i],
              onPrendreEnCharge: () => _action(
                  context, prov.prendreEnCharge, sigs[i]['id']),
              onRetrouve: () => _action(
                  context, prov.marquerRetrouve, sigs[i]['id']),
              onPerdu: () => _confirmerPerdu(context, prov, sigs[i]),
            ),
          ),
        ),
      ),
    ]);
  }

  Future<void> _action(BuildContext context,
      Future<bool> Function(int) fn, int id) async {
    final ok = await fn(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la mise à jour'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmerPerdu(BuildContext context, BagagisteProvider prov,
      Map<String, dynamic> sig) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer la perte ?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Le bagage ${sig['bagage']?['code_qr'] ?? ''} sera marqué '
                'comme définitivement perdu et le passager sera notifié.',
            style: const TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textLight))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _action(
                  context, prov.confirmerPerteDefinitive, sig['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SignalementCard extends StatelessWidget {
  final Map<String, dynamic> signalement;
  final VoidCallback onPrendreEnCharge;
  final VoidCallback onRetrouve;
  final VoidCallback onPerdu;
  const _SignalementCard({
    required this.signalement,
    required this.onPrendreEnCharge,
    required this.onRetrouve,
    required this.onPerdu,
  });

  Color get _statutColor {
    switch (signalement['statut']) {
      case 'ouvert':
        return AppColors.error;
      case 'en_cours':
        return AppColors.warning;
      case 'resolu':
        return AppColors.success;
      default:
        return AppColors.textLight;
    }
  }

  String get _statutLabel {
    switch (signalement['statut']) {
      case 'ouvert':
        return '🔴 Ouvert';
      case 'en_cours':
        return '🔍 En recherche';
      case 'resolu':
        return '✅ Résolu';
      default:
        return signalement['statut'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = signalement['user'];
    final bagage = signalement['bagage'];
    final isResolu = signalement['statut'] == 'resolu';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statutColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statutLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statutColor)),
          ),
          const Spacer(),
          Text(
              signalement['created_at']?.toString().substring(0, 10) ?? '',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight)),
        ]),

        const SizedBox(height: 10),

        // Passager
        if (user != null)
          Text('${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),

        const SizedBox(height: 6),

        // Bagage
        if (bagage != null)
          Row(children: [
            const Icon(Icons.luggage_rounded,
                size: 16, color: AppColors.textLight),
            const SizedBox(width: 6),
            Text(bagage['code_qr'] ?? '',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight)),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('● Perdu',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
            ),
          ]),

        const SizedBox(height: 6),

        // Description
        if (signalement['description'] != null &&
            signalement['description'].toString().isNotEmpty)
          Text(signalement['description'],
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium)),

        // Boutons d'action (seulement si pas résolu)
        if (!isResolu) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Column(children: [
            if (signalement['statut'] == 'ouvert')
              _ActionBtn(
                label: '🔍 Prendre en charge',
                color: AppColors.warning,
                onTap: onPrendreEnCharge,
              ),
            const SizedBox(height: 8),
            _ActionBtn(
              label: '✅ Bagage retrouvé',
              color: AppColors.success,
              onTap: onRetrouve,
            ),
            if (signalement['statut'] == 'en_cours') ...[
              const SizedBox(height: 8),
              _ActionBtn(
                label: '❌ Confirmer perdu définitivement',
                color: AppColors.error,
                onTap: onPerdu,
              ),
            ],
          ]),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════
// WIDGETS COMMUNS
// ════════════════════════════════════════
class _HBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem(
      {required this.icon,
        required this.value,
        required this.label,
        required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900)),
      Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark)),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color)),
    ),
  );
}

BoxDecoration _cardDeco() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 16,
        offset: const Offset(0, 4))
  ],
);

InputDecoration _inputDeco({
  required String label,
  required String hint,
  required IconData icon,
  required Color iconColor,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle:
      const TextStyle(color: AppColors.textLight, fontSize: 13),
      prefixIcon: Icon(icon, color: iconColor),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: iconColor, width: 2),
      ),
    );