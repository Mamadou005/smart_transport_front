import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole;
  Map<String, dynamic>? _currentUser;

  bool get isLoading       => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole     => _userRole;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      final prefs  = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      _currentUser = Map<String, dynamic>.from(result['user']);
      _userRole    = _currentUser!['role'];
      _isLoading   = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        nom: nom, prenom: prenom, email: email,
        telephone: telephone, password: password,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      _currentUser = Map<String, dynamic>.from(result['user']);
      _userRole    = 'passager';
      _isLoading   = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _currentUser = null;
    _userRole    = null;
    notifyListeners();
  }

  void updateCurrentUser(Map<String, dynamic> user) {
    _currentUser = Map<String, dynamic>.from(user);
    notifyListeners();
  }
}