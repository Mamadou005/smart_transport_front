import 'api_service.dart';

class DashboardService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStatistiquesPassager() async {
    final futures = await Future.wait([
      _api.get('/reservations'),
      _api.get('/bagages'),
      _api.get('/signalements'),
    ]);

    final reservations = futures[0].data as List;
    final bagages      = futures[1].data as List;
    final signalements = futures[2].data as List;

    // Voyages à venir
    final aVenir = reservations.where((r) =>
    r['statut'] == 'confirmee' || r['statut'] == 'en_attente').toList();

    // Bagages actifs
    final bagagesActifs = bagages.where((b) =>
    b['statut'] != 'arrive' && b['statut'] != 'recupere').toList();

    // Alertes ouvertes
    final alertes = signalements.where((s) =>
    s['statut'] == 'ouvert' || s['statut'] == 'en_cours').toList();

    return {
      'total_reservations': reservations.length,
      'voyages_a_venir':    aVenir.length,
      'bagages_actifs':     bagagesActifs.length,
      'alertes':            alertes.length,
      'prochains_voyages':  aVenir.take(3).toList(),
    };
  }
}