import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rapport_service.dart';

class RapportScreen extends StatefulWidget {
  const RapportScreen({super.key});
  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  final _rapportService = RapportService();
  Map<String, dynamic> _stats = {};
  bool _loading   = true;
  DateTime _debut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fin   = DateTime.now();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      _stats = await _rapportService.getStats(
        debut: _debut.toIso8601String().substring(0, 10),
        fin:   _fin.toIso8601String().substring(0, 10),
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _choisirPeriode() async {
    final debut = await showDatePicker(
      context: context,
      initialDate: _debut,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Date de début',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (debut == null || !mounted) return;

    final fin = await showDatePicker(
      context: context,
      initialDate: _fin,
      firstDate: debut,
      lastDate: DateTime.now(),
      helpText: 'Date de fin',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (fin == null) return;
    setState(() { _debut = debut; _fin = fin; });
    _charger();
  }

  String _fmt(DateTime d) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
      'Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${d.day} ${months[d.month-1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rapports',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Statistiques & analyses',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 12)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _charger,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Sélecteur période
            GestureDetector(
              onTap: _choisirPeriode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.date_range_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_fmt(_debut)}  →  ${_fmt(_fin)}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: Colors.white70, size: 20),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // Raccourcis période
            Row(children: [
              _PeriodeChip(label: 'Ce mois', onTap: () {
                final now = DateTime.now();
                setState(() {
                  _debut = DateTime(now.year, now.month, 1);
                  _fin   = now;
                });
                _charger();
              }),
              const SizedBox(width: 8),
              _PeriodeChip(label: '3 mois', onTap: () {
                setState(() {
                  _debut = DateTime.now().subtract(
                      const Duration(days: 90));
                  _fin   = DateTime.now();
                });
                _charger();
              }),
              const SizedBox(width: 8),
              _PeriodeChip(label: '6 mois', onTap: () {
                setState(() {
                  _debut = DateTime.now().subtract(
                      const Duration(days: 180));
                  _fin   = DateTime.now();
                });
                _charger();
              }),
              const SizedBox(width: 8),
              _PeriodeChip(label: 'Cette année', onTap: () {
                setState(() {
                  _debut = DateTime(DateTime.now().year, 1, 1);
                  _fin   = DateTime.now();
                });
                _charger();
              }),
            ]),
          ]),
        ),

        // ── Contenu
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF6C63FF)))
              : RefreshIndicator(
            color: const Color(0xFF6C63FF),
            onRefresh: _charger,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // ── KPIs principaux
                _SectionTitle(title: '📊 Vue d\'ensemble'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _KpiRapport(
                      label: 'Passagers',
                      value: '${_stats['total_passagers'] ?? 0}',
                      sub: '+${_stats['nouveaux_passagers'] ?? 0} ce mois',
                      icon: Icons.people_rounded,
                      color: AppColors.primary,
                    ),
                    _KpiRapport(
                      label: 'Voyages',
                      value: '${_stats['total_voyages'] ?? 0}',
                      sub: '${_stats['voyages_periode'] ?? 0} sur la période',
                      icon: Icons.directions_bus_rounded,
                      color: AppColors.accent,
                    ),
                    _KpiRapport(
                      label: 'Réservations',
                      value: '${_stats['total_reservations'] ?? 0}',
                      sub: '${_stats['reservations_periode'] ?? 0} sur la période',
                      icon: Icons.confirmation_num_rounded,
                      color: AppColors.accentOrange,
                    ),
                    _KpiRapport(
                      label: 'Bagages',
                      value: '${_stats['total_bagages'] ?? 0}',
                      sub: 'Taux perte: ${_stats['taux_perte'] ?? 0}%',
                      icon: Icons.luggage_rounded,
                      color: AppColors.error,
                      alert: (_stats['taux_perte'] ?? 0) > 5,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Bagages détail
                _SectionTitle(title: '🧳 Bagages'),
                const SizedBox(height: 12),
                Row(children: [
                  _MiniKpi(label: 'Perdus',
                      value: '${_stats['bagages_perdus'] ?? 0}',
                      color: AppColors.error),
                  const SizedBox(width: 12),
                  _MiniKpi(label: 'Récupérés',
                      value: '${_stats['bagages_recuperes'] ?? 0}',
                      color: AppColors.success),
                  const SizedBox(width: 12),
                  _MiniKpi(label: 'Signalements',
                      value: '${_stats['total_signalements'] ?? 0}',
                      color: AppColors.warning),
                ]),

                const SizedBox(height: 24),

                // ── Voyages par type
                _SectionTitle(title: '🚌 Voyages par type'),
                const SizedBox(height: 12),
                _ListeStats(
                  items: (_stats['voyages_par_type'] as List? ?? [])
                      .map((e) => _StatItem(
                    label: _typeLabel(e['type_transport']),
                    value: e['total'].toString(),
                    color: _typeColor(e['type_transport']),
                    total: _stats['total_voyages'] ?? 1,
                  )).toList(),
                ),

                const SizedBox(height: 24),

                // ── Voyages par statut
                _SectionTitle(title: '📋 Statuts des voyages'),
                const SizedBox(height: 12),
                _ListeStats(
                  items: (_stats['voyages_par_statut'] as List? ?? [])
                      .map((e) => _StatItem(
                    label: _statutVoyageLabel(e['statut']),
                    value: e['total'].toString(),
                    color: _statutVoyageColor(e['statut']),
                    total: _stats['total_voyages'] ?? 1,
                  )).toList(),
                ),

                const SizedBox(height: 24),

                // ── Réservations par statut
                _SectionTitle(title: '🎫 Statuts des réservations'),
                const SizedBox(height: 12),
                _ListeStats(
                  items: (_stats['reservations_par_statut'] as List? ?? [])
                      .map((e) => _StatItem(
                    label: _statutResLabel(e['statut']),
                    value: e['total'].toString(),
                    color: _statutResColor(e['statut']),
                    total: _stats['total_reservations'] ?? 1,
                  )).toList(),
                ),

                const SizedBox(height: 24),

                // ── Top destinations
                _SectionTitle(title: '📍 Top destinations'),
                const SizedBox(height: 12),
                ...(_stats['top_destinations'] as List? ?? [])
                    .asMap().entries.map((e) {
                  final i    = e.key;
                  final dest = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFFFFD700).withOpacity(0.2)
                              : i == 1
                              ? const Color(0xFFC0C0C0).withOpacity(0.2)
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: i == 0
                                ? const Color(0xFFFFB300)
                                : i == 1
                                ? const Color(0xFF9E9E9E)
                                : AppColors.textMedium,
                          ),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        dest['destination'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${dest['total']} voyage(s)',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: Color(0xFF6C63FF))),
                      ),
                    ]),
                  );
                }),

                const SizedBox(height: 24),

                // ── Signalements
                _SectionTitle(title: '🚨 Signalements'),
                const SizedBox(height: 12),
                Row(children: [
                  _MiniKpi(label: 'Ouverts',
                      value: '${_stats['signalements_ouverts'] ?? 0}',
                      color: AppColors.error),
                  const SizedBox(width: 12),
                  _MiniKpi(label: 'Résolus',
                      value: '${_stats['signalements_resolus'] ?? 0}',
                      color: AppColors.success),
                  const SizedBox(width: 12),
                  _MiniKpi(label: 'Total',
                      value: '${_stats['total_signalements'] ?? 0}',
                      color: AppColors.primary),
                ]),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  String _typeLabel(String? t) {
    switch (t) {
      case 'aerien':      return '✈️ Aérien';
      case 'ferroviaire': return '🚆 Ferroviaire';
      default:            return '🚌 Routier';
    }
  }

  Color _typeColor(String? t) {
    switch (t) {
      case 'aerien':      return const Color(0xFF6C63FF);
      case 'ferroviaire': return AppColors.accentOrange;
      default:            return AppColors.accent;
    }
  }

  String _statutVoyageLabel(String? s) {
    switch (s) {
      case 'planifie':     return '🗓 Planifié';
      case 'embarquement': return '🚪 Embarquement';
      case 'en_cours':     return '🚌 En route';
      case 'arrive':       return '✅ Arrivé';
      case 'annule':       return '❌ Annulé';
      default:             return s ?? '';
    }
  }

  Color _statutVoyageColor(String? s) {
    switch (s) {
      case 'planifie':     return AppColors.primary;
      case 'embarquement': return AppColors.warning;
      case 'en_cours':     return AppColors.accent;
      case 'arrive':       return AppColors.success;
      case 'annule':       return AppColors.error;
      default:             return AppColors.textLight;
    }
  }

  String _statutResLabel(String? s) {
    switch (s) {
      case 'confirmee':  return '✅ Confirmée';
      case 'embarquee':  return '🚪 Embarquée';
      case 'annulee':    return '❌ Annulée';
      default:           return '⏳ En attente';
    }
  }

  Color _statutResColor(String? s) {
    switch (s) {
      case 'confirmee':  return AppColors.success;
      case 'embarquee':  return AppColors.accent;
      case 'annulee':    return AppColors.error;
      default:           return AppColors.warning;
    }
  }
}

// ── Widgets
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w800,
        color: AppColors.textDark)),
  );
}

class _PeriodeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PeriodeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 11,
          fontWeight: FontWeight.w600)),
    ),
  );
}

class _KpiRapport extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final bool alert;
  const _KpiRapport({required this.label, required this.value,
    required this.sub, required this.icon, required this.color,
    this.alert = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: alert ? Border.all(
          color: color.withOpacity(0.4), width: 1.5) : null,
      boxShadow: [BoxShadow(color: color.withOpacity(0.1),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 16)),
                if (alert)
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
              ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
                Text(sub, style: const TextStyle(fontSize: 10,
                    color: AppColors.textLight)),
              ]),
        ]),
  );
}

class _MiniKpi extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniKpi({required this.label, required this.value,
    required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11,
            color: AppColors.textLight)),
      ]),
    ),
  );
}

class _StatItem {
  final String label, value;
  final Color color;
  final int total;
  const _StatItem({required this.label, required this.value,
    required this.color, required this.total});
}

class _ListeStats extends StatelessWidget {
  final List<_StatItem> items;
  const _ListeStats({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(
      children: items.map((item) {
        final pct = item.total > 0
            ? int.parse(item.value) / item.total
            : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
                  Text(item.value, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: item.color)),
                ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.toDouble().clamp(0.0, 1.0),
                backgroundColor: item.color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(item.color),
                minHeight: 6,
              ),
            ),
          ]),
        );
      }).toList(),
    ),
  );
}