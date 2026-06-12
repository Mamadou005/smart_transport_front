import 'api_service.dart';

class RapportService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStats({
    String? debut,
    String? fin,
  }) async {
    final d = debut ?? _firstDayOfMonth();
    final f = fin   ?? _today();
    final response = await _api.get(
        '/admin/rapports/stats?debut=$d&fin=$f');
    return Map<String, dynamic>.from(response.data);
  }

  String _today() => DateTime.now()
      .toIso8601String().substring(0, 10);

  String _firstDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1)
        .toIso8601String().substring(0, 10);
  }
}