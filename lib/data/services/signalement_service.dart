import '../models/signalement_model.dart';
import 'api_service.dart';

class SignalementService {
  final ApiService _api = ApiService();

  Future<List<SignalementModel>> getMesSignalements() async {
    final response = await _api.get('/signalements');
    return (response.data as List)
        .map((s) => SignalementModel.fromJson(s))
        .toList();
  }

  Future<SignalementModel> creerSignalement({
    required int bagageId,
    required String description,
    String? lieuDernierVu,
  }) async {
    final response = await _api.post('/signalements', {
      'bagage_id':       bagageId,
      'description':     description,
      'lieu_dernier_vu': lieuDernierVu ?? '',
    });
    return SignalementModel.fromJson(response.data);
  }
}