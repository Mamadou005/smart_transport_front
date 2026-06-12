import '../models/bagage_model.dart';
import 'api_service.dart';

class BagageService {
  final ApiService _api = ApiService();

  Future<List<BagageModel>> getMesBagages() async {
    final response = await _api.get('/bagages');
    return (response.data as List)
        .map((b) => BagageModel.fromJson(b))
        .toList();
  }

  Future<BagageModel> enregistrerBagage({
    required int reservationId,
    required double poids,
    String? description,
  }) async {
    final response = await _api.post('/bagages', {
      'reservation_id': reservationId,
      'poids':          poids,
      'description':    description ?? 'Bagage',
    });
    return BagageModel.fromJson(response.data);
  }

  Future<BagageModel> getBagageDetail(int id) async {
    final response = await _api.get('/bagages/$id');
    return BagageModel.fromJson(response.data);
  }
}