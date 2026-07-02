
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  Map<String, dynamic>? get currentUser => _currentUser;

  // ── Rôles reconnus par l'application
  static const List<String> _rolesValides = [
    'passager',
    'agent',
    'bagagiste', // ✅ nouveau rôle
    'admin',
  ];

  // ── Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      final prefs  = await SharedPreferences.getInstance();

      // Stocke le token
      await prefs.setString('token', result['token']);

      // Stocke le rôle pour la restauration de session
      final user = Map<String, dynamic>.from(result['user'] as Map);
      final role = user['role'] as String? ?? 'passager';
      await prefs.setString('user_role', role);

      _currentUser = user;
      _userRole    = role;
      _isLoading   = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ── Register (passager uniquement depuis l'app publique)
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
      await prefs.setString('user_role', 'passager');

      final user = result['user'] is Map
          ? Map<String, dynamic>.from(result['user'] as Map)
          : <String, dynamic>{};

      _currentUser = user;
      _userRole    = 'passager';
      _isLoading   = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ── Restaurer la session depuis SharedPreferences (au démarrage)
  Future<bool> restaurerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role  = prefs.getString('user_role');

      if (token == null || token.isEmpty) return false;
      if (role == null || !_rolesValides.contains(role)) return false;

      // Récupère le profil depuis l'API pour vérifier que le token est valide
      final user = await _authService.me();
      _currentUser = user;
      _userRole    = user['role'] as String? ?? role;

      // Met à jour le rôle stocké si changé par l'admin
      await prefs.setString('user_role', _userRole!);

      notifyListeners();
      return true;

    } catch (_) {
      // Token expiré ou invalide → on déconnecte proprement
      await logout();
      return false;
    }
  }

  // ── Logout
  Future<void> logout() async {
    try { await _authService.logout(); } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_role');

    _currentUser = null;
    _userRole    = null;
    notifyListeners();
  }

  // ── Mise à jour du profil en local (après modification)
  void updateCurrentUser(Map<String, dynamic> user) {
    _currentUser = Map<String, dynamic>.from(user);
    // Met à jour le rôle si l'admin l'a changé
    if (user.containsKey('role')) {
      _userRole = user['role'] as String?;
    }
    notifyListeners();
  }

  // ── Helpers de rôle (utilisés dans l'UI)
  bool get isAdmin      => _userRole == 'admin';
  bool get isAgent      => _userRole == 'agent';
  bool get isBagagiste  => _userRole == 'bagagiste'; // ✅ nouveau
  bool get isPassager   => _userRole == 'passager';
  bool get isConnecte   => _currentUser != null && _userRole != null;

  String get nomComplet =>
      '${_currentUser?['prenom'] ?? ''} ${_currentUser?['nom'] ?? ''}'.trim();

  String get initiales {
    final p = (_currentUser?['prenom'] as String? ?? '').isNotEmpty
        ? (_currentUser!['prenom'] as String)[0].toUpperCase() : '';
    final n = (_currentUser?['nom'] as String? ?? '').isNotEmpty
        ? (_currentUser!['nom'] as String)[0].toUpperCase() : '';
    return '$p$n';
  }
}