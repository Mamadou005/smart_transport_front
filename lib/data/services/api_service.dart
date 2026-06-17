import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ URL automatique selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api'; // Chrome
    } else {
      return 'http://10.0.2.2:8000/api';  // Émulateur Android
    }
  }

  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl        = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30); // ✅ 30s
    _dio.options.receiveTimeout = const Duration(seconds: 30); // ✅ 30s
    _dio.options.sendTimeout    = const Duration(seconds: 30); // ✅ ajoute ça
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept']        = 'application/json';
        options.headers['Content-Type']  = 'application/json'; // ✅ ajoute ça
        return handler.next(options);
      },
      // ✅ Ajoute un logger pour voir les erreurs
      onError: (error, handler) {
        print('❌ Dio Error: ${error.message}');
        print('❌ Response: ${error.response?.data}');
        print('❌ Status: ${error.response?.statusCode}');
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, Map<String, dynamic> data) =>
      _dio.post(path, data: data);
  Future<Response> put(String path, Map<String, dynamic> data) =>
      _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}