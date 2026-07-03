import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool    _isLoading      = false;
  String? _errorMessage;
  String? _userRole;
  Map<String, dynamic>? _currentUser;
  bool    _showOnboarding = false;

  bool    get isLoading      => _isLoading;
  String? get errorMessage   => _errorMessage;
  String? get userRole       => _userRole;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool    get isConnecte     => _currentUser != null && _userRole != null;

  // ✅ Vrai seulement si passager venant de s'inscrire
  bool get showOnboarding => _showOnboarding;

  static const List<String> rolesValides = [
    'passager', 'agent', 'bagagiste', 'admin',
  ];

  // ════════════════════════════════════════
  // LOGIN
  // ════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    _isLoading      = true;
    _errorMessage   = null;
    _showOnboarding = false; // reset à chaque tentative
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      final prefs  = await SharedPreferences.getInstance();

      await prefs.setString('token', result['token']);

      final user = Map<String, dynamic>.from(result['user'] as Map);
      final role = user['role'] as String? ?? 'passager';
      await prefs.setString('user_role', role);

      _currentUser    = user;
      _userRole       = role;
      // ✅ Login normal → jamais d'onboarding
      _showOnboarding = false;

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════
  // REGISTER
  // ════════════════════════════════════════
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    _isLoading      = true;
    _errorMessage   = null;
    _showOnboarding = false;
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

      // ✅ Nouveau passager inscrit → onboarding
      _showOnboarding = true;

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════
  // RESTAURER SESSION (démarrage de l'app)
  // ════════════════════════════════════════
  Future<bool> restaurerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role  = prefs.getString('user_role');

      if (token == null || token.isEmpty) return false;
      if (role == null || !rolesValides.contains(role)) return false;

      final user = await _authService.me();
      _currentUser    = user;
      _userRole       = user['role'] as String? ?? role;

      // ── Maintien du flag si l'utilisateur est déjà identifié comme nouveau passager
      if (_userRole != 'passager' || !_showOnboarding) {
        _showOnboarding = false;
      }

      await prefs.setString('user_role', _userRole!);
      notifyListeners();
      return true;

    } catch (_) {
      await logout();
      return false;
    }
  }

  // ════════════════════════════════════════
  // LOGOUT
  // ════════════════════════════════════════
  Future<void> logout() async {
    try { await _authService.logout(); } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_role');

    _currentUser    = null;
    _userRole       = null;
    _showOnboarding = false;
    notifyListeners();
  }

  // ✅ Appelé par OnboardingScreen quand l'utilisateur clique "Commencer"
  void clearOnboarding() {
    _showOnboarding = false;
    notifyListeners();
  }

  void updateCurrentUser(Map<String, dynamic> user) {
    _currentUser = Map<String, dynamic>.from(user);
    if (user.containsKey('role')) _userRole = user['role'] as String?;
    notifyListeners();
  }

  bool get isAdmin     => _userRole == 'admin';
  bool get isAgent     => _userRole == 'agent';
  bool get isBagagiste => _userRole == 'bagagiste';
  bool get isPassager  => _userRole == 'passager';

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