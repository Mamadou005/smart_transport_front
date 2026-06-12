import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F8A), Color(0xFF00D4AA)],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Espace Agent',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Bonjour, $prenom',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ]),
                Row(children: [
                  GestureDetector(
                    onTap: _chargerStats,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ],
            ),

            const SizedBox(height: 14),

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
                  const Icon(Icons.circle,
                      color: AppColors.success, size: 8),
                  const SizedBox(width: 6),
                  const Text('Terminal actif',
                      style: TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            if (!_loadingStats)
              Row(children: [
                _AgentStat(
                  label: 'Réservations',
                  value: '${_stats['reservations_today'] ?? 0}',
                  icon: Icons.confirmation_num_rounded,
                  color: Colors.white,
                ),
                _AgentStat(
                  label: 'Bagages',
                  value: '${_stats['bagages_enregistres_today'] ?? 0}',
                  icon: Icons.luggage_rounded,
                  color: AppColors.accent,
                ),
                _AgentStat(
                  label: 'Perdus',
                  value: '${_stats['bagages_perdus'] ?? 0}',
                  icon: Icons.warning_rounded,
                  color: (_stats['bagages_perdus'] ?? 0) > 0
                      ? AppColors.error : Colors.white70,
                ),
              ]),

            const SizedBox(height: 16),

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
                labelColor: const Color(0xFF1B4F8A),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 11),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Scanner'),
                  Tab(text: 'Enregistrer'),
                  Tab(text: 'Réservations'),
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
              _ScannerTab(agentService: _agentService),
              _EnregistrerBagageTab(agentService: _agentService),
              _ReservationsTab(agentService: _agentService),
            ],
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════
//  ONGLET SCANNER
// ════════════════════════════════
class _ScannerTab extends StatefulWidget {
  final AgentService agentService;
  const _ScannerTab({required this.agentService});
  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  final _codeCtrl  = TextEditingController();
  bool _isScanning = false;
  Map<String, dynamic>? _resultat;
  final List<Map<String, dynamic>> _historique = [];

  Future<void> _scanner() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _isScanning = true; _resultat = null; });
    final code   = _codeCtrl.text.trim().toUpperCase();
    final result = await widget.agentService.scanner(code);
    setState(() {
      _resultat   = result;
      _isScanning = false;
      _historique.insert(0, {
        ...result,
        'heure': TimeOfDay.now().format(context),
      });
      if (_historique.length > 10) _historique.removeLast();
    });
  }

  // ✅ Ouvre le scanner caméra (mobile uniquement)
  void _ouvrirScannerCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScannerCameraScreen(
          onCodeDetecte: (code) {
            setState(() => _codeCtrl.text = code.toUpperCase());
            _scanner();
          },
        ),
      ),
    );
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Scanner un code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('QR Code de réservation ou de bagage',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 20),

            // ✅ Champ avec bouton Coller + Effacer
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Ex: RES-ABCD1234 ou BAG-EFGH5678',
                hintStyle: TextStyle(
                    color: AppColors.textLight, fontSize: 13),
                prefixIcon: const Icon(Icons.qr_code_rounded,
                    color: AppColors.accent),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Coller',
                      icon: const Icon(Icons.content_paste_rounded,
                          color: AppColors.accent, size: 18),
                      onPressed: () async {
                        final data =
                        await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          setState(() {
                            _codeCtrl.text =
                                data!.text!.trim().toUpperCase();
                          });
                        }
                      },
                    ),
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
            ),

            const SizedBox(height: 14),

            // ✅ Deux boutons : Valider + Caméra (mobile seulement)
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: AppColors.accent.withOpacity(0.35),
                          blurRadius: 12, offset: const Offset(0, 4))],
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
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.search_rounded,
                          color: Colors.white),
                      label: Text(
                        _isScanning ? 'Vérification...' : 'Valider',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ Bouton caméra uniquement sur mobile
              if (!kIsWeb) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _ouvrirScannerCamera,
                  child: Container(
                    height: 52, width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )],
                    ),
                    child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        if (_resultat != null) _ResultatScan(resultat: _resultat!),
        const SizedBox(height: 20),

        if (_historique.isNotEmpty) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scans récents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                TextButton(
                  onPressed: () => setState(() => _historique.clear()),
                  child: const Text('Effacer',
                      style: TextStyle(color: AppColors.textLight,
                          fontSize: 12)),
                ),
              ]),
          const SizedBox(height: 8),
          ..._historique.map((h) => _HistoriqueItem(scan: h)),
        ],
      ]),
    );
  }
}

// ════════════════════════════════
//  ÉCRAN SCANNER CAMÉRA (mobile)
// ════════════════════════════════
class _ScannerCameraScreen extends StatefulWidget {
  final Function(String) onCodeDetecte;
  const _ScannerCameraScreen({required this.onCodeDetecte});
  @override
  State<_ScannerCameraScreen> createState() =>
      _ScannerCameraScreenState();
}

class _ScannerCameraScreenState
    extends State<_ScannerCameraScreen> {
  bool _detecte = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Info caméra non disponible sur émulateur
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.accent, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Scanner QR Code',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'Sur un vrai appareil, la caméra\n'
                    's\'ouvre ici pour scanner le QR code.\n'
                    'Sur l\'émulateur, utilisez la saisie manuelle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              // Saisie manuelle de secours
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _SaisieManuelleScanner(
                  onValider: (code) {
                    if (!_detecte) {
                      _detecte = true;
                      Navigator.pop(context);
                      widget.onCodeDetecte(code);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Bouton retour
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
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SaisieManuelleScanner extends StatefulWidget {
  final Function(String) onValider;
  const _SaisieManuelleScanner({required this.onValider});
  @override
  State<_SaisieManuelleScanner> createState() =>
      _SaisieManuellesScannerState();
}

class _SaisieManuellesScannerState
    extends State<_SaisieManuelleScanner> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(children: [
    TextField(
      controller: _ctrl,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Saisir le code manuellement',
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
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          if (_ctrl.text.trim().isNotEmpty) {
            widget.onValider(_ctrl.text.trim().toUpperCase());
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Valider',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    ),
  ]);
}

// ════════════════════════════════
//  WIDGETS RÉSULTATS SCAN
// ════════════════════════════════
class _ResultatScan extends StatelessWidget {
  final Map<String, dynamic> resultat;
  const _ResultatScan({required this.resultat});
  bool get _isValide => resultat['valide'] == true;

  @override
  Widget build(BuildContext context) {
    final type    = resultat['type'] ?? 'inconnu';
    final message = resultat['message'] ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isValide
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [BoxShadow(
          color: (_isValide ? AppColors.success : AppColors.error)
              .withOpacity(0.1),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isValide ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isValide
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: _isValide ? AppColors.success : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isValide ? 'Accès autorisé' : 'Accès refusé',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _isValide
                              ? AppColors.success : AppColors.error)),
                  Text(message, style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium)),
                ],
              )),
            ]),
            if (_isValide) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (type == 'reservation' && resultat['reservation'] != null)
                _DetailReservation(reservation: resultat['reservation']),
              if (type == 'bagage' && resultat['bagage'] != null)
                _DetailBagage(bagage: resultat['bagage']),
            ],
          ]),
    );
  }
}

class _DetailReservation extends StatelessWidget {
  final Map<String, dynamic> reservation;
  const _DetailReservation({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final user   = reservation['user'];
    final voyage = reservation['voyage'];
    return Column(children: [
      _InfoRow(icon: Icons.person_rounded, label: 'Passager',
          value: '${user?['prenom']} ${user?['nom']}'),
      const SizedBox(height: 8),
      _InfoRow(icon: Icons.confirmation_num_rounded, label: 'Code',
          value: reservation['code_qr'] ?? ''),
      if (voyage != null) ...[
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.route_rounded, label: 'Voyage',
            value: '${voyage['origine']} → ${voyage['destination']}'),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.schedule_rounded, label: 'Départ',
            value: voyage['date_depart']
                ?.toString().substring(0, 16) ?? ''),
      ],
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Statut : ${reservation['statut']}',
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.success)),
      ),
    ]);
  }
}

class _DetailBagage extends StatelessWidget {
  final Map<String, dynamic> bagage;
  const _DetailBagage({required this.bagage});

  @override
  Widget build(BuildContext context) {
    final reservation = bagage['reservation'];
    final user        = reservation?['user'];
    return Column(children: [
      _InfoRow(icon: Icons.luggage_rounded, label: 'Bagage',
          value: bagage['description'] ?? 'Bagage'),
      const SizedBox(height: 8),
      _InfoRow(icon: Icons.qr_code_rounded, label: 'Code',
          value: bagage['code_qr'] ?? ''),
      const SizedBox(height: 8),
      _InfoRow(icon: Icons.monitor_weight_outlined, label: 'Poids',
          value: '${bagage['poids']} kg'),
      if (user != null) ...[
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.person_rounded, label: 'Propriétaire',
            value: '${user['prenom']} ${user['nom']}'),
      ],
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Statut : ${bagage['statut']}',
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent)),
      ),
    ]);
  }
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
    Text('$label : ', style: const TextStyle(
        fontSize: 12, color: AppColors.textLight)),
    Expanded(child: Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textDark))),
  ]);
}

class _HistoriqueItem extends StatelessWidget {
  final Map<String, dynamic> scan;
  const _HistoriqueItem({required this.scan});

  @override
  Widget build(BuildContext context) {
    final isValide = scan['valide'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isValide ? AppColors.success : AppColors.error)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isValide ? Icons.check_rounded : Icons.close_rounded,
            color: isValide ? AppColors.success : AppColors.error,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scan['code'] ?? '', style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
            Text(scan['type'] ?? '', style: const TextStyle(
                fontSize: 11, color: AppColors.textLight)),
          ],
        )),
        Text(scan['heure'] ?? '', style: const TextStyle(
            fontSize: 11, color: AppColors.textLight)),
      ]),
    );
  }
}

// ════════════════════════════════
//  ONGLET ENREGISTRER BAGAGE
// ════════════════════════════════
class _EnregistrerBagageTab extends StatefulWidget {
  final AgentService agentService;
  const _EnregistrerBagageTab({required this.agentService});
  @override
  State<_EnregistrerBagageTab> createState() =>
      _EnregistrerBagageTabState();
}

class _EnregistrerBagageTabState
    extends State<_EnregistrerBagageTab> {
  final _formKey     = GlobalKey<FormState>();
  final _codeResCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _poidsCtrl   = TextEditingController();
  bool _isLoading    = false;
  Map<String, dynamic>? _reservationTrouvee;
  final _agentService = AgentService();

  Future<void> _chercherReservation() async {
    if (_codeResCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final code   = _codeResCtrl.text.trim().toUpperCase();
    final result = await _agentService.scanner(code);
    setState(() {
      _isLoading = false;
      if (result['type'] == 'reservation' &&
          result['valide'] == true) {
        _reservationTrouvee = result['reservation'];
      } else {
        _reservationTrouvee = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Réservation non trouvée'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reservationTrouvee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cherchez d\'abord une réservation'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final bagage = await widget.agentService.enregistrerBagage(
        reservationId: _reservationTrouvee!['id'],
        poids:         double.parse(_poidsCtrl.text),
        description:   _descCtrl.text.isEmpty
            ? 'Bagage' : _descCtrl.text,
      );
      if (!mounted) return;
      _showSuccessDialog(bagage);
      _codeResCtrl.clear();
      _descCtrl.clear();
      _poidsCtrl.clear();
      setState(() => _reservationTrouvee = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : ${e.toString()}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
    setState(() => _isLoading = false);
  }

  void _showSuccessDialog(Map<String, dynamic> bagage) {
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
                child: const Icon(Icons.luggage_rounded,
                    color: AppColors.success, size: 40)),
            const SizedBox(height: 16),
            const Text('Bagage enregistré !',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text(bagage['code_qr'] ?? '',
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('${bagage['poids']} kg',
                    style: const TextStyle(fontSize: 13,
                        color: AppColors.textMedium)),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Parfait !',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeResCtrl.dispose();
    _descCtrl.dispose();
    _poidsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.confirmation_num_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Code de réservation',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _codeResCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Ex: RES-ABCD1234',
                          hintStyle: TextStyle(
                              color: AppColors.textLight, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _chercherReservation,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.search_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                  if (_reservationTrouvee != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${_reservationTrouvee!['user']?['prenom']}'
                                    ' ${_reservationTrouvee!['user']?['nom']}',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark)),
                            if (_reservationTrouvee!['voyage'] != null)
                              Text(
                                  '${_reservationTrouvee!['voyage']['origine']}'
                                      ' → ${_reservationTrouvee!['voyage']['destination']}',
                                  style: const TextStyle(fontSize: 11,
                                      color: AppColors.textLight)),
                          ],
                        )),
                      ]),
                    ),
                  ],
                ]),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.luggage_rounded,
                          color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Informations du bagage',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Ex: Valise bleue, sac à dos noir...',
                      prefixIcon: const Icon(Icons.description_outlined,
                          color: AppColors.accent),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _poidsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Poids (kg)',
                      hintText: 'Ex: 23.5',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined,
                          color: AppColors.accentOrange),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Poids requis';
                      if (double.tryParse(v) == null)
                        return 'Poids invalide';
                      return null;
                    },
                  ),
                ]),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.luggage_rounded,
                    color: Colors.white),
                label: Text(
                  _isLoading
                      ? 'Enregistrement...'
                      : 'Enregistrer le bagage',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700),
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

// ════════════════════════════════
//  ONGLET RÉSERVATIONS avec filtre date
// ════════════════════════════════
class _ReservationsTab extends StatefulWidget {
  final AgentService agentService;
  const _ReservationsTab({required this.agentService});
  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  List<dynamic> _reservations = [];
  bool _loading               = true;
  DateTime _selectedDate      = DateTime.now();

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final dateStr =
      _selectedDate.toIso8601String().substring(0, 10);
      _reservations = await widget.agentService
          .getReservationsDuJour(date: dateStr);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _charger();
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    final now = DateTime.now();
    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day) return "Aujourd'hui";
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Sélecteur de date
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedDate = _selectedDate
                  .subtract(const Duration(days: 1)));
              _charger();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _choisirDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(_formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.textLight, size: 18),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _selectedDate =
                  _selectedDate.add(const Duration(days: 1)));
              _charger();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _selectedDate = DateTime.now());
              _charger();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Auj.',
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
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
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_reservations.length} réservation(s)',
              style: const TextStyle(fontSize: 12,
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
              ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_busy_rounded,
                      color: AppColors.accent, size: 48)),
              const SizedBox(height: 16),
              const Text('Aucune réservation ce jour',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text('Sélectionnez une autre date',
                  style: TextStyle(fontSize: 13,
                      color: AppColors.textLight)),
            ],
          ))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reservations.length,
            itemBuilder: (_, i) =>
                _ReservationAgentCard(
                    reservation: _reservations[i]),
          ),
        ),
      ),
    ]);
  }
}

class _ReservationAgentCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  const _ReservationAgentCard({required this.reservation});

  Color get _statutColor {
    switch (reservation['statut']) {
      case 'confirmee': return AppColors.success;
      case 'embarquee': return AppColors.accent;
      case 'annulee':   return AppColors.error;
      default:          return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user   = reservation['user'];
    final voyage = reservation['voyage'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(
            user != null
                ? '${user['prenom'][0]}${user['nom'][0]}'
                : '?',
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user != null
                ? '${user['prenom']} ${user['nom']}' : 'Inconnu',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            Text(reservation['code_qr'] ?? '',
                style: const TextStyle(fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            if (voyage != null)
              Text('${voyage['origine']} → ${voyage['destination']}',
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.textLight)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statutColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(reservation['statut'] ?? '',
              style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _statutColor)),
        ),
      ]),
    );
  }
}

class _AgentStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AgentStat({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color,
          fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color.withOpacity(0.8),
              fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}