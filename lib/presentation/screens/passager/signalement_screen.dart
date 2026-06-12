import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/bagage_model.dart';
import '../../../data/models/signalement_model.dart';
import '../../../data/providers/bagage_provider.dart';
import '../../../data/services/signalement_service.dart';

class SignalementScreen extends StatefulWidget {
  const SignalementScreen({super.key});
  @override
  State<SignalementScreen> createState() => _SignalementScreenState();
}

class _SignalementScreenState extends State<SignalementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SignalementModel> _signalements = [];
  bool _loadingSignalements = false;
  final _signalementService = SignalementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BagageProvider>().chargerMesBagages();
      _chargerSignalements();
    });
  }

  Future<void> _chargerSignalements() async {
    setState(() => _loadingSignalements = true);
    try {
      final list = await _signalementService.getMesSignalements();
      setState(() => _signalements = list);
    } catch (_) {}
    setState(() => _loadingSignalements = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
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
                  Text('Signalements',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Déclarer une perte de bagage',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 12)),
                ],
              ),
            ]),
            const SizedBox(height: 20),
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
                labelColor: AppColors.accentOrange,
                unselectedLabelColor: Colors.white70,
                labelStyle:
                const TextStyle(fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Déclarer une perte'),
                  Tab(text: 'Mes signalements'),
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
              _DeclarerPerteTab(
                onSignalementCree: _chargerSignalements,
              ),
              _MesSignalementsTab(
                signalements: _signalements,
                isLoading:    _loadingSignalements,
                onRefresh:    _chargerSignalements,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Onglet Déclarer une perte
class _DeclarerPerteTab extends StatefulWidget {
  final VoidCallback onSignalementCree;
  const _DeclarerPerteTab({required this.onSignalementCree});
  @override
  State<_DeclarerPerteTab> createState() => _DeclarerPerteTabState();
}

class _DeclarerPerteTabState extends State<_DeclarerPerteTab> {
  final _formKey     = GlobalKey<FormState>();
  final _descCtrl    = TextEditingController();
  final _lieuCtrl    = TextEditingController();
  BagageModel? _selectedBagage;
  bool _isLoading = false;
  final _service  = SignalementService();

  @override
  void dispose() {
    _descCtrl.dispose();
    _lieuCtrl.dispose();
    super.dispose();
  }

  Future<void> _declarer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBagage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner un bagage'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.creerSignalement(
        bagageId:      _selectedBagage!.id,
        description:   _descCtrl.text.trim(),
        lieuDernierVu: _lieuCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onSignalementCree();
      _showSuccessDialog();
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

  void _showSuccessDialog() {
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
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.report_problem_rounded,
                    color: AppColors.warning, size: 48)),
            const SizedBox(height: 16),
            const Text('Signalement enregistré !',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Votre signalement a été transmis. '
                  'Vous serez notifié dès que votre bagage sera retrouvé.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13,
                  color: AppColors.textMedium, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _descCtrl.clear();
                  _lieuCtrl.clear();
                  setState(() => _selectedBagage = null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Compris',
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
  Widget build(BuildContext context) {
    final bagageProvider = context.watch<BagageProvider>();
    final bagagesActifs  = bagageProvider.bagages
        .where((b) => b.statut != 'perdu' && b.statut != 'recupere')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [

          // Alerte info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Signalez immédiatement tout bagage manquant. '
                      'Notre équipe sera alertée pour le retrouver.',
                  style: TextStyle(fontSize: 12,
                      color: AppColors.warning, height: 1.5),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Sélection bagage
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.luggage_rounded,
                        color: AppColors.accentOrange, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Sélectionner le bagage perdu',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ]),
                const SizedBox(height: 14),
                if (bagagesActifs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          color: AppColors.textLight, size: 16),
                      SizedBox(width: 8),
                      Text('Aucun bagage actif trouvé',
                          style: TextStyle(fontSize: 12,
                              color: AppColors.textLight)),
                    ]),
                  )
                else
                  ...bagagesActifs.map((b) => GestureDetector(
                    onTap: () =>
                        setState(() => _selectedBagage = b),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedBagage?.id == b.id
                            ? AppColors.accentOrange.withOpacity(0.06)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedBagage?.id == b.id
                              ? AppColors.accentOrange
                              : const Color(0xFFE2E8F0),
                          width: _selectedBagage?.id == b.id ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedBagage?.id == b.id
                                ? AppColors.accentOrange.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.luggage_rounded,
                              color: _selectedBagage?.id == b.id
                                  ? AppColors.accentOrange
                                  : AppColors.textLight,
                              size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedBagage?.id == b.id
                                      ? AppColors.accentOrange
                                      : AppColors.textDark,
                                )),
                            Text('${b.codeQr} • ${b.poids} kg',
                                style: const TextStyle(fontSize: 11,
                                    color: AppColors.textLight)),
                          ],
                        )),
                        if (_selectedBagage?.id == b.id)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accentOrange, size: 20),
                      ]),
                    ),
                  )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Formulaire
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Détails du signalement',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ]),
                const SizedBox(height: 16),

                // Lieu dernier vu
                TextFormField(
                  controller: _lieuCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lieu où il a été vu pour la dernière fois',
                    hintText: 'Ex: Terminal 2, Gare de Dakar...',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: AppColors.accent, size: 18),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description du problème',
                    hintText:
                    'Décrivez les circonstances de la perte...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(
                          left: 12, top: 14, right: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: AppColors.accentOrange, size: 18),
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Description requise' : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bouton déclarer
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: AppColors.accentOrange.withOpacity(0.35),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _declarer,
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
                    : const Icon(Icons.report_problem_rounded,
                    color: Colors.white),
                label: Text(
                  _isLoading ? 'Envoi en cours...'
                      : 'Déclarer la perte',
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

// ── Onglet Mes Signalements
class _MesSignalementsTab extends StatelessWidget {
  final List<SignalementModel> signalements;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _MesSignalementsTab({
    required this.signalements,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(
          color: AppColors.accentOrange));
    }

    if (signalements.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 48)),
            const SizedBox(height: 16),
            const Text('Aucun signalement',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('Tous vos bagages sont en ordre ✅',
                style: TextStyle(fontSize: 13,
                    color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: signalements.length,
        itemBuilder: (_, i) =>
            _SignalementCard(signalement: signalements[i]),
      ),
    );
  }
}

// ── Carte signalement
class _SignalementCard extends StatelessWidget {
  final SignalementModel signalement;
  const _SignalementCard({required this.signalement});

  Color get _statusColor {
    switch (signalement.statut) {
      case 'ouvert':    return AppColors.error;
      case 'en_cours':  return AppColors.warning;
      case 'resolu':    return AppColors.success;
      default:          return AppColors.textLight;
    }
  }

  String get _statusLabel {
    switch (signalement.statut) {
      case 'ouvert':    return 'Ouvert';
      case 'en_cours':  return 'En cours';
      case 'resolu':    return 'Résolu';
      default:          return signalement.statut;
    }
  }

  IconData get _statusIcon {
    switch (signalement.statut) {
      case 'ouvert':    return Icons.error_outline_rounded;
      case 'en_cours':  return Icons.search_rounded;
      case 'resolu':    return Icons.check_circle_rounded;
      default:          return Icons.help_outline;
    }
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
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon,
                    color: _statusColor, size: 16)),
            const SizedBox(width: 8),
            Text(_statusLabel,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _statusColor)),
            const Spacer(),
            Text(
              signalement.createdAt.substring(0, 10),
              style: const TextStyle(fontSize: 11,
                  color: AppColors.textLight),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (signalement.bagage != null) ...[
                Row(children: [
                  const Icon(Icons.luggage_rounded,
                      color: AppColors.textLight, size: 14),
                  const SizedBox(width: 6),
                  Text(signalement.bagage!.description,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const Spacer(),
                  Text(signalement.bagage!.codeQr,
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],

              Text(signalement.description,
                  style: const TextStyle(fontSize: 13,
                      color: AppColors.textMedium, height: 1.5)),

              if (signalement.lieuDernierVu != null &&
                  signalement.lieuDernierVu!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 6),
                    Text(signalement.lieuDernierVu!,
                        style: const TextStyle(fontSize: 12,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],

              // Timeline statut
              const SizedBox(height: 14),
              _StatutTimeline(statut: signalement.statut),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Timeline statut signalement
class _StatutTimeline extends StatelessWidget {
  final String statut;
  const _StatutTimeline({required this.statut});

  int get _step {
    switch (statut) {
      case 'ouvert':   return 0;
      case 'en_cours': return 1;
      case 'resolu':   return 2;
      default:         return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps  = ['Déclaré', 'En recherche', 'Résolu'];
    final colors = [AppColors.error, AppColors.warning, AppColors.success];
    final step   = _step;

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive  = i <= step;
        final isCurrent = i == step;
        return Expanded(
          child: Row(children: [
            Column(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? colors[i]
                      : const Color(0xFFE2E8F0),
                  boxShadow: isCurrent ? [BoxShadow(
                    color: colors[i].withOpacity(0.4),
                    blurRadius: 8,
                  )] : null,
                ),
                child: isActive
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(steps[i],
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: isActive ? colors[i] : AppColors.textLight,
                  )),
            ]),
            if (i < steps.length - 1)
              Expanded(child: Container(
                height: 2,
                color: i < step
                    ? colors[i + 1]
                    : const Color(0xFFE2E8F0),
              )),
          ]),
        );
      }),
    );
  }
}