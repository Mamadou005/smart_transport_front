import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  // ✅ GET /api/notifications
  Future<List<dynamic>> getNotifications() async {
    final response = await _api.get('/notifications');
    final data = response.data;
    // ✅ Fix LinkedMap → List
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) return data['data'] as List;
    return [];
  }

  // ✅ GET /api/notifications/non-lues
  Future<int> getNonLues() async {
    final response = await _api.get('/notifications/non-lues');
    final data = response.data;
    if (data is Map) return data['count'] ?? 0;
    if (data is List) return data.length;
    return 0;
  }

  // ✅ PUT /api/notifications/{id}/lue
  Future<void> marquerLue(int id) async {
    await _api.put('/notifications/$id/lue', <String, dynamic>{});
  }

  // ✅ PUT /api/notifications/toutes-lues
  Future<void> marquerToutesLues() async {
    await _api.put(
        '/notifications/toutes-lues', <String, dynamic>{});
  }
}