import '../models/voyage_model.dart';
import 'api_service.dart';

class VoyageService {
  final ApiService _api = ApiService();

  Future<List<VoyageModel>> getVoyages({
    String? origine,
    String? destination,
    String? date,
  }) async {
    final params = <String, String>{};
    if (origine != null && origine.isNotEmpty)
      params['origine'] = origine;
    if (destination != null && destination.isNotEmpty)
      params['destination'] = destination;
    if (date != null && date.isNotEmpty)
      params['date_depart'] = date;

    final response = await _api.get(
      '/voyages${params.isNotEmpty ? '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&') : ''}',
    );

    return (response.data as List)
        .map((v) => VoyageModel.fromJson(v))
        .toList();
  }
}