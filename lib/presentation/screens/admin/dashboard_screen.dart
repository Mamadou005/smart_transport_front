
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/api_service.dart';
import '../notifications_screen.dart';
import 'rapport_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _loading = true);
    try {
      final stats = await _adminService.getStats();
      setState(() => _stats = stats);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final prenom = auth.currentUser?['prenom'] ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _chargerStats,
        child: CustomScrollView(
          slivers: [
            // ── HEADER
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A2342), Color(0xFF0D3B6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tableau de bord',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13, letterSpacing: 1,
                                  )),
                              const SizedBox(height: 4),
                              Text('Bonjour, $prenom',
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ]),
                        Row(children: [
                          // Notifications
                          _HeaderBtn(
                            icon: Icons.notifications_outlined,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                const NotificationsScreen())),
                          ),
                          const SizedBox(width: 10),
                          _HeaderBtn(icon: Icons.refresh_rounded,
                              onTap: _chargerStats),
                          const SizedBox(width: 10),
                          _HeaderBtn(
                            icon: Icons.logout_rounded,
                            onTap: () async {
                              await context.read<AuthProvider>().logout();
                              if (context.mounted) context.go('/login');
                            },
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Badge Admin
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.shield_rounded,
                            color: AppColors.accent, size: 14),
                        const SizedBox(width: 6),
                        const Text('Administrateur',
                            style: TextStyle(color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // ── CONTENU
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ))
                  else ...[
                    // KPI Grid 2x2
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.4,
                      children: [
                        _KpiCard(
                          label: 'Passagers',
                          value: '${_stats['total_passagers'] ?? 0}',
                          icon: Icons.people_rounded,
                          color: AppColors.primaryLight,
                        ),
                        _KpiCard(
                          label: 'Voyages',
                          value: '${_stats['total_voyages'] ?? 0}',
                          icon: Icons.directions_bus_rounded,
                          color: AppColors.accent,
                        ),
                        _KpiCard(
                          label: 'Bagages',
                          value: '${_stats['total_bagages'] ?? 0}',
                          icon: Icons.luggage_rounded,
                          color: AppColors.accentOrange,
                        ),
                        _KpiCard(
                          label: 'Pertes',
                          value: '${_stats['bagages_perdus'] ?? 0}',
                          icon: Icons.report_problem_rounded,
                          color: AppColors.error,
                          alert: (_stats['bagages_perdus'] ?? 0) > 0,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Mini stats ligne
                    Row(children: [
                      _MiniStat(
                        label: 'Voyages planifiés',
                        value: '${_stats['voyages_planifies'] ?? 0}',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        label: 'En cours',
                        value: '${_stats['voyages_en_cours'] ?? 0}',
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        label: 'Signalements',
                        value:
                        '${(_stats['signalements_ouverts'] ?? 0) + (_stats['signalements_en_cours'] ?? 0)}',
                        color: AppColors.error,
                      ),
                    ]),
                  ],

                  const SizedBox(height: 32),
                  const Text('Gestion',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  // Menu tiles
                  _MenuTile(
                    icon: Icons.people_rounded,
                    label: 'Gérer les utilisateurs',
                    subtitle:
                    '${(_stats['total_passagers'] ?? 0) + (_stats['total_agents'] ?? 0)} comptes actifs',
                    color: AppColors.primaryLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const _UtilisateursScreen())),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.route_rounded,
                    label: 'Gérer les voyages',
                    subtitle:
                    '${_stats['voyages_planifies'] ?? 0} voyages planifiés',
                    color: AppColors.accent,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const _VoyagesAdminScreen())),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.report_problem_rounded,
                    label: 'Signalements bagages',
                    subtitle:
                    '${_stats['signalements_ouverts'] ?? 0} cas ouverts',
                    color: AppColors.error,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _SignalementsAdminScreen())),
                    badge: (_stats['signalements_ouverts'] ?? 0) > 0
                        ? '${_stats['signalements_ouverts']}'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.luggage_rounded,
                    label: 'Suivi des bagages',
                    subtitle:
                    '${_stats['bagages_perdus'] ?? 0} bagages perdus',
                    color: AppColors.accentOrange,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const _BagagesAdminScreen())),
                    badge: (_stats['bagages_perdus'] ?? 0) > 0
                        ? '${_stats['bagages_perdus']}'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Rapports & Statistiques',
                    subtitle: 'Analyses de la période',
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RapportScreen())),
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
}

// ════════════════════════════════════════
//  ÉCRAN UTILISATEURS
// ════════════════════════════════════════
class _UtilisateursScreen extends StatefulWidget {
  const _UtilisateursScreen();
  @override
  State<_UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<_UtilisateursScreen> {
  final _adminService         = AdminService();
  final _searchCtrl           = TextEditingController();
  List<dynamic> _users        = [];
  List<dynamic> _usersFiltres = [];
  bool   _loading             = true;
  String _filtreRole          = 'tous';

  @override
  void initState() {
    super.initState();
    _charger();
    _searchCtrl.addListener(_filtrerLocalement);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filtrerLocalement);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final role = _filtreRole == 'tous' ? null : _filtreRole;
      _users = await _adminService.getUtilisateurs(role: role);
      _filtrerLocalement();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filtrerLocalement() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _usersFiltres = q.isEmpty
          ? List.from(_users)
          : _users.where((u) {
        final nom    = (u['nom']       ?? '').toString().toLowerCase();
        final prenom = (u['prenom']    ?? '').toString().toLowerCase();
        final email  = (u['email']     ?? '').toString().toLowerCase();
        final tel    = (u['telephone'] ?? '').toString().toLowerCase();
        return nom.contains(q) || prenom.contains(q) ||
            email.contains(q) || tel.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(children: [
            Row(children: [
              _BackBtn(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 14),
              Text('Utilisateurs (${_usersFiltres.length})',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              _IconBtn(icon: Icons.refresh_rounded, onTap: _charger),
            ]),
            const SizedBox(height: 14),

            // Barre de recherche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.search, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nom, prénom, email...',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); _filtrerLocalement(); },
                    child: const Icon(Icons.clear_rounded,
                        color: Colors.white54, size: 18),
                  ),
              ]),
            ),
            const SizedBox(height: 12),

            // ✅ Filtres rôles — bagagiste inclus
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final r in ['tous', 'passager', 'agent', 'bagagiste', 'admin'])
                  GestureDetector(
                    onTap: () {
                      setState(() => _filtreRole = r);
                      _charger();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filtreRole == r
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r[0].toUpperCase() + r.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _filtreRole == r
                              ? AppColors.primary
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),

        // Badge résultats recherche
        if (_searchCtrl.text.isNotEmpty && !_loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_usersFiltres.length} résultat(s) pour "${_searchCtrl.text}"',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
            ]),
          ),

        // Liste
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
              : _usersFiltres.isEmpty
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_rounded,
                    color: AppColors.textLight.withOpacity(0.4),
                    size: 56),
                const SizedBox(height: 12),
                Text(
                    _searchCtrl.text.isNotEmpty
                        ? 'Aucun résultat pour "${_searchCtrl.text}"'
                        : 'Aucun utilisateur',
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 15)),
              ]))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _usersFiltres.length,
            itemBuilder: (_, i) => _UserCard(
              user: _usersFiltres[i],
              searchQuery: _searchCtrl.text,
              onDelete: () async {
                await _adminService.supprimerUtilisateur(
                    _usersFiltres[i]['id']);
                _charger();
              },
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreerUserDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ✅ Dialog création utilisateur avec rôle bagagiste
  void _showCreerUserDialog() {
    final nomCtrl    = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl  = TextEditingController();
    final telCtrl    = TextEditingController();
    final passCtrl   = TextEditingController();
    String role      = 'passager';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Créer un utilisateur',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 20),

                // Nom + Prénom
                Row(children: [
                  Expanded(child: _AdminField(ctrl: nomCtrl, label: 'Nom')),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminField(ctrl: prenomCtrl, label: 'Prénom')),
                ]),
                const SizedBox(height: 12),
                _AdminField(ctrl: emailCtrl, label: 'Email',
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _AdminField(ctrl: telCtrl, label: 'Téléphone',
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _AdminField(ctrl: passCtrl, label: 'Mot de passe',
                    obscure: true),
                const SizedBox(height: 12),

                // ✅ Dropdown rôle avec bagagiste
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      // ✅ bagagiste ajouté ici
                      items: [
                        'passager',
                        'agent',
                        'bagagiste',
                        'admin',
                      ].map((r) => DropdownMenuItem(
                        value: r,
                        child: Row(children: [
                          Icon(
                            _roleIcon(r),
                            size: 16,
                            color: _roleColor(r),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            r[0].toUpperCase() + r.substring(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _roleColor(r),
                            ),
                          ),
                        ]),
                      )).toList(),
                      onChanged: (v) => setModal(() => role = v!),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton créer
                SizedBox(
                  width: double.infinity, height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty ||
                            emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Remplissez tous les champs obligatoires'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        try {
                          await _adminService.creerUtilisateur({
                            'nom':       nomCtrl.text.trim(),
                            'prenom':    prenomCtrl.text.trim(),
                            'email':     emailCtrl.text.trim(),
                            'telephone': telCtrl.text.trim(),
                            'password':  passCtrl.text,
                            'role':      role,
                          });
                          if (context.mounted) Navigator.pop(context);
                          _charger();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erreur : ${e.toString()}'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Créer',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Couleur par rôle (bagagiste inclus)
  static Color _roleColor(String role) {
    switch (role) {
      case 'admin':     return AppColors.error;
      case 'agent':     return AppColors.accent;
      case 'bagagiste': return AppColors.bagagisteAccent;
      default:          return AppColors.primaryLight;
    }
  }

  // ✅ Icône par rôle
  static IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':     return Icons.shield_rounded;
      case 'agent':     return Icons.qr_code_scanner_rounded;
      case 'bagagiste': return Icons.luggage_rounded;
      default:          return Icons.person_rounded;
    }
  }
}

// ✅ UserCard — bagagiste inclus dans les couleurs et rôle affiché
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  final String searchQuery;
  const _UserCard({required this.user, required this.onDelete,
    this.searchQuery = ''});

  // ✅ Couleur selon rôle (bagagiste ajouté)
  Color get _roleColor {
    switch (user['role']) {
      case 'admin':     return AppColors.error;
      case 'agent':     return AppColors.accent;
      case 'bagagiste': return AppColors.bagagisteAccent; // ✅
      default:          return AppColors.primaryLight;
    }
  }

  Widget _highlight(String text, String q, TextStyle base) {
    if (q.isEmpty) return Text(text, style: base);
    final lower = text.toLowerCase();
    final idx   = lower.indexOf(q.toLowerCase());
    if (idx == -1) return Text(text, style: base);
    final hl = base.copyWith(
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withOpacity(0.1),
    );
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: text.substring(0, idx), style: base),
        TextSpan(text: text.substring(idx, idx + q.length), style: hl),
        TextSpan(text: text.substring(idx + q.length), style: base),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initiales =
    '${user['prenom']?[0] ?? ''}${user['nom']?[0] ?? ''}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: searchQuery.isNotEmpty
            ? Border.all(color: AppColors.primary.withOpacity(0.2))
            : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(initiales,
              style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800, color: _roleColor))),
        ),
        const SizedBox(width: 12),

        // Infos
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _highlight(
              '${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
              searchQuery,
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 2),
            _highlight(
              user['email'] ?? '',
              searchQuery,
              const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            if ((user['telephone'] ?? '').toString().isNotEmpty)
              _highlight(
                user['telephone'],
                searchQuery,
                const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
          ],
        )),

        // Badge rôle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(user['role'] ?? '',
              style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700, color: _roleColor)),
        ),
        const SizedBox(width: 8),

        // Supprimer
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Supprimer ?',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              content: Text(
                  'Supprimer ${user['prenom']} ${user['nom']} ?',
                  style: const TextStyle(color: AppColors.textMedium)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Non',
                        style: TextStyle(color: AppColors.textLight))),
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); onDelete(); },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Supprimer',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════
//  ÉCRAN VOYAGES ADMIN
// ════════════════════════════════════════
class _VoyagesAdminScreen extends StatefulWidget {
  const _VoyagesAdminScreen();
  @override
  State<_VoyagesAdminScreen> createState() => _VoyagesAdminScreenState();
}

class _VoyagesAdminScreenState extends State<_VoyagesAdminScreen> {
  final _adminService    = AdminService();
  List<dynamic> _voyages = [];
  bool _loading          = true;

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try { _voyages = await _adminService.getVoyages(); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Row(children: [
            _BackBtn(onTap: () => Navigator.pop(context)),
            const SizedBox(width: 14),
            Text('Voyages (${_voyages.length})',
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            _IconBtn(icon: Icons.refresh_rounded, onTap: _charger),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _charger,
            child: _voyages.isEmpty
                ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined,
                      size: 56,
                      color: AppColors.accent.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Aucun voyage',
                      style: TextStyle(color: AppColors.textLight,
                          fontSize: 15)),
                ]))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _voyages.length,
              itemBuilder: (_, i) => _VoyageAdminCard(
                voyage: _voyages[i],
                onDelete: () async {
                  await _adminService.supprimerVoyage(_voyages[i]['id']);
                  _charger();
                },
                onUpdateStatut: (s) async {
                  await _adminService.updateVoyage(
                      _voyages[i]['id'], {'statut': s});
                  _charger();
                },
              ),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreerVoyageDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter voyage',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCreerVoyageDialog() {
    final origCtrl  = TextEditingController();
    final destCtrl  = TextEditingController();
    final capCtrl   = TextEditingController(text: '50');
    final prixCtrl  = TextEditingController();
    String type     = 'routier';
    DateTime? dateD;
    DateTime? dateA;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) {
          String fmtD(DateTime? d) {
            if (d == null) return 'Sélectionner';
            return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
          }
          String fmtA(DateTime? d) {
            if (d == null) return 'Sélectionner';
            const m = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
            return '${d.day} ${m[d.month - 1]} ${d.year}';
          }
          Future<void> pickD() async {
            final d = await showDatePicker(context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (c, ch) => Theme(data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppColors.accent)),
                    child: ch!));
            if (d == null) return;
            final t = await showTimePicker(context: ctx,
                initialTime: TimeOfDay.now(),
                builder: (c, ch) => Theme(data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppColors.accent)),
                    child: ch!));
            if (t == null) return;
            setM(() => dateD = DateTime(d.year, d.month, d.day, t.hour, t.minute));
          }
          Future<void> pickA() async {
            final d = await showDatePicker(context: ctx,
                initialDate: dateD ?? DateTime.now(),
                firstDate: dateD ?? DateTime.now(),
                lastDate: DateTime(2030),
                builder: (c, ch) => Theme(data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                    child: ch!));
            if (d == null) return;
            setM(() => dateA = d);
          }
          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24,
                24 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    const Text('Créer un voyage',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: _AdminField(ctrl: origCtrl, label: 'Origine')),
                      const SizedBox(width: 12),
                      Expanded(child: _AdminField(ctrl: destCtrl, label: 'Destination')),
                    ]),
                    const SizedBox(height: 12),
                    // Date départ
                    GestureDetector(
                      onTap: pickD,
                      child: _DatePickerField(
                        label: 'Date & heure de départ',
                        value: fmtD(dateD),
                        icon: Icons.flight_takeoff_rounded,
                        color: AppColors.accent,
                        selected: dateD != null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date arrivée
                    GestureDetector(
                      onTap: pickA,
                      child: _DatePickerField(
                        label: 'Date d\'arrivée estimée',
                        value: fmtA(dateA),
                        icon: Icons.flight_land_rounded,
                        color: AppColors.primary,
                        selected: dateA != null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _AdminField(ctrl: capCtrl,
                          label: 'Capacité', type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: prixCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Prix (XOF)',
                            hintText: 'Ex: 5000',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.payments_rounded,
                                  color: AppColors.accent, size: 16),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: type, isExpanded: true,
                          items: ['routier', 'ferroviaire', 'aerien']
                              .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(children: [
                                Icon(t == 'aerien' ? Icons.flight_rounded
                                    : t == 'ferroviaire' ? Icons.train_rounded
                                    : Icons.directions_bus_rounded,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Text(t[0].toUpperCase() + t.substring(1)),
                              ])))
                              .toList(),
                          onChanged: (v) => setM(() => type = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(14)),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (origCtrl.text.isEmpty || destCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Remplissez origine et destination'),
                                  backgroundColor: AppColors.error));
                              return;
                            }
                            if (dateD == null || dateA == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Sélectionnez les dates'),
                                  backgroundColor: AppColors.error));
                              return;
                            }
                            final prix = double.tryParse(
                                prixCtrl.text.isEmpty ? '0' : prixCtrl.text) ?? 0;
                            await _adminService.creerVoyage({
                              'origine': origCtrl.text.trim(),
                              'destination': destCtrl.text.trim(),
                              'date_depart': dateD!.toIso8601String()
                                  .substring(0, 16).replaceAll('T', ' '),
                              'date_arrivee': dateA!.toIso8601String().substring(0, 10),
                              'capacite': int.tryParse(capCtrl.text) ?? 50,
                              'type_transport': type,
                              'statut': 'planifie',
                              'prix': prix,
                            });
                            if (context.mounted) Navigator.pop(context);
                            _charger();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('Créer le voyage',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ]),
            ),
          );
        },
      ),
    );
  }
}

class _VoyageAdminCard extends StatelessWidget {
  final Map<String, dynamic> voyage;
  final VoidCallback onDelete;
  final Function(String) onUpdateStatut;
  const _VoyageAdminCard({required this.voyage,
    required this.onDelete, required this.onUpdateStatut});

  Color get _typeColor {
    switch (voyage['type_transport']) {
      case 'aerien':      return const Color(0xFF6C63FF);
      case 'ferroviaire': return AppColors.accentOrange;
      default:            return AppColors.accent;
    }
  }
  IconData get _typeIcon {
    switch (voyage['type_transport']) {
      case 'aerien':      return Icons.flight_rounded;
      case 'ferroviaire': return Icons.train_rounded;
      default:            return Icons.directions_bus_rounded;
    }
  }
  Color get _statutColor {
    switch (voyage['statut']) {
      case 'planifie':     return AppColors.primary;
      case 'embarquement': return AppColors.warning;
      case 'en_cours':     return AppColors.accent;
      case 'arrive':       return AppColors.success;
      case 'annule':       return AppColors.error;
      default:             return AppColors.textLight;
    }
  }
  String get _statutLabel {
    switch (voyage['statut']) {
      case 'planifie':     return '🗓 Planifié';
      case 'embarquement': return '🚪 Embarquement';
      case 'en_cours':     return '🚌 En route';
      case 'arrive':       return '✅ Arrivé';
      case 'annule':       return '❌ Annulé';
      default:             return voyage['statut'] ?? '';
    }
  }
  String _formatPrix(dynamic prix) {
    if (prix == null) return 'N/A';
    final p = double.tryParse(prix.toString()) ?? 0;
    return p == 0 ? 'Gratuit' : '${p.toStringAsFixed(0)} XOF';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_typeIcon, color: _typeColor, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${voyage['origine']} → ${voyage['destination']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Row(children: [
                Text(voyage['date_depart']?.toString().substring(0, 16) ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(_formatPrix(voyage['prix']),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
              ]),
            ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_statutLabel, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, color: _statutColor))),
        const SizedBox(width: 8),
        GestureDetector(onTap: onDelete,
            child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 16))),
      ]),
      if ((voyage['reservations_count'] ?? 0) > 0) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.people_rounded, color: AppColors.textLight, size: 14),
          const SizedBox(width: 4),
          Text('${voyage['reservations_count']} réservation(s)',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ]),
      ],
      if (voyage['statut'] != 'annule' && voyage['statut'] != 'arrive') ...[
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            if (voyage['statut'] == 'planifie')
              _StatutBtn(label: '🚪 Embarquement',
                  color: AppColors.warning,
                  onTap: () => onUpdateStatut('embarquement')),
            if (voyage['statut'] == 'embarquement') ...[
              _StatutBtn(label: '🚌 Démarrer', color: AppColors.accent,
                  onTap: () => onUpdateStatut('en_cours')),
              const SizedBox(width: 8),
            ],
            if (voyage['statut'] == 'en_cours')
              _StatutBtn(label: '✅ Marquer arrivé', color: AppColors.success,
                  onTap: () => onUpdateStatut('arrive')),
            if (voyage['statut'] != 'en_cours') ...[
              const SizedBox(width: 8),
              _StatutBtn(label: '❌ Annuler', color: AppColors.error,
                  onTap: () => onUpdateStatut('annule')),
            ],
          ]),
        ),
      ],
    ]),
  );
}

// ════════════════════════════════════════
//  ÉCRAN SIGNALEMENTS ADMIN
// ════════════════════════════════════════
class _SignalementsAdminScreen extends StatefulWidget {
  const _SignalementsAdminScreen();
  @override
  State<_SignalementsAdminScreen> createState() =>
      _SignalementsAdminScreenState();
}

class _SignalementsAdminScreenState extends State<_SignalementsAdminScreen> {
  final _adminService         = AdminService();
  List<dynamic> _signalements = [];
  bool _loading               = true;

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try { _signalements = await _adminService.getSignalements(); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Row(children: [
            _BackBtn(onTap: () => Navigator.pop(context)),
            const SizedBox(width: 14),
            Text('Signalements (${_signalements.length})',
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            _IconBtn(icon: Icons.refresh_rounded, onTap: _charger),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.accentOrange))
              : RefreshIndicator(
            color: AppColors.accentOrange,
            onRefresh: _charger,
            child: _signalements.isEmpty
                ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 56,
                      color: AppColors.success.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('Aucun signalement',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 15)),
                ]))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _signalements.length,
              itemBuilder: (_, i) => _SignalementAdminCard(
                signalement: _signalements[i],
                onUpdate: (action) async {
                  try {
                    if (action == 'confirmer_perdu') {
                      final api = ApiService();
                      await api.put(
                          '/admin/signalements/${_signalements[i]['id']}/confirmer-perdu',
                          {});
                    } else {
                      await _adminService.updateSignalement(
                          _signalements[i]['id'], action);
                    }
                    _charger();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SignalementAdminCard extends StatelessWidget {
  final Map<String, dynamic> signalement;
  final Function(String) onUpdate;
  const _SignalementAdminCard({required this.signalement, required this.onUpdate});

  Color get _statusColor {
    switch (signalement['statut']) {
      case 'ouvert':   return AppColors.error;
      case 'en_cours': return AppColors.warning;
      case 'resolu':   return AppColors.success;
      default:         return AppColors.textLight;
    }
  }
  String get _statusLabel {
    switch (signalement['statut']) {
      case 'ouvert':   return '🔴 Ouvert';
      case 'en_cours': return '🔍 En recherche';
      case 'resolu':   return '✅ Résolu';
      default:         return signalement['statut'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_statusLabel, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, color: _statusColor))),
        const Spacer(),
        Text(signalement['created_at']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ]),
      const SizedBox(height: 10),
      if (signalement['user'] != null)
        Text('${signalement['user']['prenom']} ${signalement['user']['nom']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      if (signalement['bagage'] != null) ...[
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.luggage_rounded, color: AppColors.textLight, size: 14),
          const SizedBox(width: 4),
          Text(signalement['bagage']['code_qr'] ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (signalement['bagage']['statut'] == 'perdu'
                  ? AppColors.error : AppColors.success)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              signalement['bagage']['statut'] == 'perdu' ? '🔴 Perdu' : '✅ Récupéré',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: signalement['bagage']['statut'] == 'perdu'
                      ? AppColors.error : AppColors.success),
            ),
          ),
        ]),
      ],
      const SizedBox(height: 6),
      Text(signalement['description'] ?? '',
          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
      if (signalement['statut'] != 'resolu') ...[
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (signalement['statut'] == 'ouvert')
            _ActionBtn(label: '🔍 Prendre en charge',
                color: AppColors.warning,
                onTap: () => onUpdate('en_cours')),
          _ActionBtn(label: '✅ Bagage retrouvé',
              color: AppColors.success,
              onTap: () => onUpdate('resolu')),
          if (signalement['statut'] == 'en_cours')
            _ActionBtn(label: '❌ Confirmer perdu',
                color: AppColors.error,
                onTap: () => _confirmerPerdu(context)),
        ]),
      ],
    ]),
  );

  void _confirmerPerdu(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirmer la perte ?',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Le bagage sera marqué comme définitivement perdu '
          'et le passager sera notifié.',
          style: TextStyle(color: AppColors.textMedium)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textLight))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); onUpdate('confirmer_perdu'); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: const Text('Confirmer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════
//  ÉCRAN BAGAGES ADMIN
// ════════════════════════════════════════
class _BagagesAdminScreen extends StatefulWidget {
  const _BagagesAdminScreen();
  @override
  State<_BagagesAdminScreen> createState() => _BagagesAdminScreenState();
}

class _BagagesAdminScreenState extends State<_BagagesAdminScreen> {
  final _api          = ApiService();
  List<dynamic> _bags = [];
  bool _loading       = true;
  String _filtre      = 'tous';

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/admin/bagages');
      _bags = r.data as List? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtres =>
      _filtre == 'tous' ? _bags : _bags.where((b) => b['statut'] == _filtre).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
          child: Column(children: [
            Row(children: [
              _BackBtn(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 14),
              Text('Bagages (${_bags.length})',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              _IconBtn(icon: Icons.refresh_rounded, onTap: _charger),
            ]),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final s in ['tous', 'enregistre', 'en_transit',
                  'arrive', 'perdu', 'recupere'])
                  GestureDetector(
                    onTap: () => setState(() => _filtre = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filtre == s
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: _filtre == s
                                  ? AppColors.accentOrange : Colors.white)),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.accentOrange))
              : RefreshIndicator(
            color: AppColors.accentOrange,
            onRefresh: _charger,
            child: _filtres.isEmpty
                ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.luggage_outlined, size: 56,
                      color: AppColors.accentOrange.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Aucun bagage',
                      style: TextStyle(color: AppColors.textLight,
                          fontSize: 15)),
                ]))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtres.length,
              itemBuilder: (_, i) => _BagageAdminCard(
                bagage: _filtres[i],
                onUpdateStatut: (s) async {
                  await _api.put(
                      '/admin/bagages/${_filtres[i]['id']}/statut',
                      {'statut': s});
                  _charger();
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BagageAdminCard extends StatelessWidget {
  final Map<String, dynamic> bagage;
  final Function(String) onUpdateStatut;
  const _BagageAdminCard({required this.bagage, required this.onUpdateStatut});

  Color get _c {
    switch (bagage['statut']) {
      case 'enregistre': return AppColors.primaryLight;
      case 'en_transit': return AppColors.warning;
      case 'arrive':     return AppColors.success;
      case 'perdu':      return AppColors.error;
      case 'recupere':   return AppColors.accent;
      default:           return AppColors.textLight;
    }
  }
  String get _l {
    switch (bagage['statut']) {
      case 'enregistre': return '📦 Enregistré';
      case 'en_transit': return '🚌 En transit';
      case 'arrive':     return '✅ Arrivé';
      case 'perdu':      return '⚠️ Perdu';
      case 'recupere':   return '🎉 Récupéré';
      default:           return bagage['statut'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.luggage_rounded, size: 18, color: _c)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bagage['description'] ?? 'Bagage',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Text(bagage['code_qr'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600)),
              if (bagage['reservation']?['user'] != null)
                Text('${bagage['reservation']['user']['prenom']} '
                    '${bagage['reservation']['user']['nom']}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_l, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, color: _c))),
      ]),
      if (bagage['statut'] == 'perdu') ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionBtn(label: 'En transit',
              color: AppColors.warning, onTap: () => onUpdateStatut('en_transit'))),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(label: 'Récupéré',
              color: AppColors.success, onTap: () => onUpdateStatut('recupere'))),
        ]),
      ],
    ]),
  );
}

// ════════════════════════════════════════
//  WIDGETS COMMUNS
// ════════════════════════════════════════
class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20)),
  );
}

class _StatutBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatutBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: color)),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
    ),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool alert;
  const _KpiCard({required this.label, required this.value,
    required this.icon, required this.color, this.alert = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: alert ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
      boxShadow: [BoxShadow(color: color.withOpacity(0.12),
          blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            if (alert) Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12,
                color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ]),
        ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _MenuTile({required this.icon, required this.label,
    required this.subtitle, required this.color,
    required this.onTap, this.badge});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12,
                  color: AppColors.textLight)),
            ])),
        if (badge != null)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(badge!, style: const TextStyle(fontSize: 11,
                  color: Colors.white, fontWeight: FontWeight.w800)))
        else
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLight, size: 20),
      ]),
    ),
  );
}

class _AdminField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  final bool obscure;
  const _AdminField({required this.ctrl, required this.label,
    this.type = TextInputType.text, this.obscure = false});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _DatePickerField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool selected;
  const _DatePickerField({required this.label, required this.value,
    required this.icon, required this.color, required this.selected});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: selected ? color : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1),
    ),
    child: Row(children: [
      Icon(icon, color: selected ? color : AppColors.textLight, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: selected ? AppColors.textDark : AppColors.textLight)),
          ])),
      Icon(Icons.edit_calendar_rounded, color: color, size: 18),
    ]),
  );
}