import 'package:dio/dio.dart';

class ConnectivityService {
  static Future<bool> isConnected() async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);

      // ✅ Teste la connexion au serveur Laravel
      final response = await dio.get('http://127.0.0.1:8000/api');

      return response.statusCode != null;
    } catch (_) {
      return false;
    }
  }

  // ✅ Teste avec une URL personnalisée
  static Future<bool> isServerReachable(String url) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);

      await dio.get(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}