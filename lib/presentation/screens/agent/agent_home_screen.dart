import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/agent_service.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});
  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _agentService = AgentService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    // 3 onglets : Scanner | Réservations | Stats
    _tabController = TabController(length: 3, vsync: this);
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _loadingStats = true);
    try {
      _stats = await _agentService.getStats();
    } catch (_) {}
    setState(() => _loadingStats = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final prenom = auth.currentUser?['prenom'] ?? 'Agent';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [

        // ══════════════════════════════════════
        // HEADER — gradient bleu → teal
        // ══════════════════════════════════════
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.agentGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(children: [

            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Espace Agent Terminal',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('Bonjour, $prenom',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ]),
                Row(children: [
                  _HBtn(icon: Icons.refresh_rounded, onTap: _chargerStats),
                  const SizedBox(width: 8),
                  _HBtn(
                    icon: Icons.logout_rounded,
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ]),
              ],
            ),

            const SizedBox(height: 12),

            // Badge terminal actif
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Terminal actif',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Stats rapides
            if (!_loadingStats)
              Row(children: [
                _StatItem(
                  icon: Icons.confirmation_num_rounded,
                  value: '${_stats['reservations_aujourd_hui'] ?? 0}',
                  label: 'Réservations',
                  color: Colors.white,
                ),
                _StatItem(
                  icon: Icons.how_to_reg_rounded,
                  value: '${_stats['embarques_aujourd_hui'] ?? 0}',
                  label: 'Embarqués',
                  color: AppColors.accent,
                ),
                _StatItem(
                  icon: Icons.pending_actions_rounded,
                  value: '${_stats['en_attente'] ?? 0}',
                  label: 'En attente',
                  color: Colors.white70,
                ),
              ])
            else
              const SizedBox(height: 40),

            const SizedBox(height: 16),

            // Onglets : Scanner | Réservations | Stats
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
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 11),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 16),
                      text: 'Scanner'),
                  Tab(icon: Icon(Icons.list_alt_rounded, size: 16),
                      text: 'Réservations'),
                  Tab(icon: Icon(Icons.bar_chart_rounded, size: 16),
                      text: 'Stats'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        // ══════════════════════════════════════
        // CONTENU DES ONGLETS
        // ══════════════════════════════════════
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ScannerTab(agentService: _agentService),
              _ReservationsTab(agentService: _agentService),
              _StatsTab(agentService: _agentService, stats: _stats,
                  onRefresh: _chargerStats),
            ],
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════
// ONGLET 1 — SCANNER QR + VALIDER EMBARQUEMENT
// ════════════════════════════════════════
class _ScannerTab extends StatefulWidget {
  final AgentService agentService;
  const _ScannerTab({required this.agentService});
  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  final _codeCtrl = TextEditingController();
  bool _isScanning = false;
  Map<String, dynamic>? _resultat;
  final List<Map<String, dynamic>> _historique = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanner() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isScanning = true;
      _resultat = null;
    });
    final result = await widget.agentService.scanner(code);
    setState(() {
      _resultat   = {...result, 'code': code};
      _isScanning = false;
      _historique.insert(0, {
        ...result,
        'code':  code,
        'heure': TimeOfDay.now().format(context),
      });
      if (_historique.length > 20) _historique.removeLast();
    });
  }

  void _ouvrirCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScannerCameraPage(
          onCodeDetecte: (code) {
            _codeCtrl.text = code;
            _scanner();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // ── Card Scanner
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDeco(),
          child: Column(children: [
            // Icône QR
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.agentGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Scanner un QR Code',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Code de réservation du passager',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 20),

            // Champ saisie
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Ex: RES-ABCD1234',
                hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0),
                prefixIcon: const Icon(Icons.qr_code_rounded,
                    color: AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.accent, width: 2),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Coller',
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
                    if (_codeCtrl.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textLight, size: 18),
                        onPressed: () {
                          _codeCtrl.clear();
                          setState(() => _resultat = null);
                        },
                      ),
                  ],
                ),
              ),
              onSubmitted: (_) => _scanner(),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            Row(children: [
              // Bouton Valider
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.agentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isScanning
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.search_rounded,
                          color: Colors.white),
                      label: Text(
                        _isScanning ? 'Vérification...' : 'Valider',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),

              // Bouton caméra (mobile uniquement)
              if (!kIsWeb) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _ouvrirCamera,
                  child: Container(
                    height: 52, width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Résultat du scan
        if (_resultat != null) _ResultatScan(resultat: _resultat!),

        const SizedBox(height: 20),

        // Historique
        if (_historique.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scans récents',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              TextButton(
                onPressed: () => setState(() => _historique.clear()),
                child: const Text('Tout effacer',
                    style: TextStyle(
                        color: AppColors.textLight, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._historique.map((h) => _HistoriqueItem(scan: h)),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════
// PAGE SCANNER CAMÉRA
// ════════════════════════════════════════
class _ScannerCameraPage extends StatefulWidget {
  final Function(String) onCodeDetecte;
  const _ScannerCameraPage({required this.onCodeDetecte});
  @override
  State<_ScannerCameraPage> createState() => _ScannerCameraPageState();
}

class _ScannerCameraPageState extends State<_ScannerCameraPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.accent, size: 64),
                ),
                const SizedBox(height: 28),
                const Text('Scanner QR Code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'Sur un appareil physique, la caméra s\'ouvre ici.\n'
                      'Sur émulateur, utilisez la saisie manuelle ci-dessous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 14,
                      height: 1.5),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Code de réservation...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.keyboard_rounded,
                        color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_ctrl.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        widget.onCodeDetecte(
                            _ctrl.text.trim().toUpperCase());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Valider',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 56, left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════
// RÉSULTAT DU SCAN
// ════════════════════════════════════════
class _ResultatScan extends StatelessWidget {
  final Map<String, dynamic> resultat;
  const _ResultatScan({required this.resultat});

  bool get _valide => resultat['valide'] == true;

  @override
  Widget build(BuildContext context) {
    final reservation = resultat['reservation'];
    final user   = reservation?['user'];
    final voyage = reservation?['voyage'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (_valide ? AppColors.success : AppColors.error)
              .withOpacity(0.35),
          width: 2,
        ),
        boxShadow: [BoxShadow(
            color: (_valide ? AppColors.success : AppColors.error)
                .withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Statut
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_valide ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _valide
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: _valide ? AppColors.success : AppColors.error,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _valide ? 'Embarquement autorisé ✅'
                      : 'Accès refusé ❌',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _valide ? AppColors.success : AppColors.error),
                ),
                Text(resultat['message'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium)),
              ])),
        ]),

        if (_valide && reservation != null) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Infos passager
          if (user != null)
            _InfoRow(
                icon: Icons.person_rounded,
                label: 'Passager',
                value: '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.qr_code_rounded,
              label: 'Code',
              value: reservation['code_qr'] ?? ''),

          if (voyage != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.directions_bus_rounded,
                label: 'Voyage',
                value:
                '${voyage['origine']} → ${voyage['destination']}'),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Départ',
                value: voyage['date_depart']
                    ?.toString()
                    .substring(0, 16) ??
                    ''),
          ],

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Statut : ${reservation['statut'] ?? ''}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
          ),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════
// ONGLET 2 — RÉSERVATIONS DU JOUR
// ════════════════════════════════════════
class _ReservationsTab extends StatefulWidget {
  final AgentService agentService;
  const _ReservationsTab({required this.agentService});
  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final dateStr = _date.toIso8601String().substring(0, 10);
      _reservations =
      await widget.agentService.getReservationsDuJour(date: dateStr);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _charger();
    }
  }

  String _formatDate(DateTime d) {
    const mois = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) {
      return "Aujourd'hui";
    }
    return '${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Sélecteur de date
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: _cardDeco(),
        child: Row(children: [
          _DateBtn(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              setState(() => _date =
                  _date.subtract(const Duration(days: 1)));
              _charger();
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: _choisirDate,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Text(_formatDate(_date),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textLight),
                  ]),
            ),
          ),
          _DateBtn(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              setState(() =>
              _date = _date.add(const Duration(days: 1)));
              _charger();
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _date = DateTime.now());
              _charger();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Auj.',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight)),
            ),
          ),
        ]),
      ),

      // Badge compteur
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_reservations.length} réservation(s)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent),
            ),
          ),
        ]),
      ),

      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
            color: AppColors.accent))
            : RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _charger,
          child: _reservations.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 56,
                    color: AppColors.accent.withOpacity(0.3)),
                const SizedBox(height: 14),
                const Text('Aucune réservation',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium)),
                const SizedBox(height: 6),
                const Text('Sélectionnez une autre date',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reservations.length,
            itemBuilder: (_, i) =>
                _ReservationCard(res: _reservations[i]),
          ),
        ),
      ),
    ]);
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> res;
  const _ReservationCard({required this.res});

  Color get _couleur {
    switch (res['statut']) {
      case 'confirmee': return AppColors.success;
      case 'embarquee': return AppColors.accent;
      case 'annulee':   return AppColors.error;
      default:          return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user   = res['user'];
    final voyage = res['voyage'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user != null
                  ? '${user['prenom']?[0] ?? ''}${user['nom']?[0] ?? ''}'
                  : '?',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryLight),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user != null
                  ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'
                  : 'Inconnu',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Text(res['code_qr'] ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600)),
              if (voyage != null)
                Text(
                    '${voyage['origine'] ?? ''} → ${voyage['destination'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
            ])),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(res['statut'] ?? '',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _couleur)),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════
// ONGLET 3 — STATS DU JOUR
// ════════════════════════════════════════
class _StatsTab extends StatelessWidget {
  final AgentService agentService;
  final Map<String, dynamic> stats;
  final VoidCallback onRefresh;
  const _StatsTab({
    required this.agentService,
    required this.stats,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final res       = stats['reservations_aujourd_hui'] ?? 0;
    final embarques = stats['embarques_aujourd_hui'] ?? 0;
    final attente   = stats['en_attente'] ?? 0;
    final taux      = res > 0
        ? ((embarques / res) * 100).toStringAsFixed(0)
        : '0';

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // KPI grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.3,
            children: [
              _KpiCard(
                label: 'Réservations',
                value: '$res',
                icon: Icons.confirmation_num_rounded,
                color: AppColors.primaryLight,
              ),
              _KpiCard(
                label: 'Embarqués',
                value: '$embarques',
                icon: Icons.how_to_reg_rounded,
                color: AppColors.success,
              ),
              _KpiCard(
                label: 'En attente',
                value: '$attente',
                icon: Icons.pending_rounded,
                color: AppColors.warning,
              ),
              _KpiCard(
                label: 'Taux emb.',
                value: '$taux%',
                icon: Icons.percent_rounded,
                color: AppColors.accent,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barre progression
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDeco(),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progression embarquement',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  _ProgressRow(
                    label: 'Embarqués',
                    count: embarques,
                    total: res,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: 'En attente',
                    count: attente,
                    total: res,
                    color: AppColors.warning,
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Voyage du jour',
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textLight)),
                        Text(
                          stats['voyage_actif'] != null
                              ? '${stats['voyage_actif']['origine']} → '
                              '${stats['voyage_actif']['destination']}'
                              : 'Pas de voyage actif',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark),
                        ),
                      ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _ProgressRow({required this.label, required this.count,
    required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12,
            color: AppColors.textMedium)),
        Text('$count / $total',
            style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
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
  final String value, label;
  final Color color;
  const _StatItem({required this.icon, required this.value,
    required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 20,
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

class _DateBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DateBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryLight, size: 20),
    ),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value,
    required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 4))],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500)),
          ]),
        ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label,
    required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.textLight, size: 16),
    const SizedBox(width: 8),
    Text('$label : ',
        style: const TextStyle(
            fontSize: 12, color: AppColors.textLight)),
    Expanded(
      child: Text(value,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
    ),
  ]);
}

class _HistoriqueItem extends StatelessWidget {
  final Map<String, dynamic> scan;
  const _HistoriqueItem({required this.scan});
  @override
  Widget build(BuildContext context) {
    final ok = scan['valide'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (ok ? AppColors.success : AppColors.error)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            color: ok ? AppColors.success : AppColors.error,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scan['code'] ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Text(scan['message'] ?? '',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])),
        Text(scan['heure'] ?? '',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textLight)),
      ]),
    );
  }
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