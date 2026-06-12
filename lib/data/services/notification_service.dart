import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getNotifications() async {
    final response = await _api.get('/notifications');
    return response.data as List;
  }

  Future<int> getNonLues() async {
    final response = await _api.get('/notifications/non-lues');
    return response.data['count'] ?? 0;
  }

  Future<void> marquerLue(int id) async {
    await _api.put('/notifications/$id/lue', {});
  }

  Future<void> marquerToutesLues() async {
    await _api.put('/notifications/toutes-lues', {});
  }
}