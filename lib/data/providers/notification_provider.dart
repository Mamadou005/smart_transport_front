import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  int  _nonLues   = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int  get nonLues   => _nonLues;
  bool get isLoading => _isLoading;

  // ✅ Convertit n'importe quel Map en Map<String, dynamic>
  Map<String, dynamic> _toMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    return Map<String, dynamic>.from(item as Map);
  }

  Future<void> charger() async {
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _service.getNotifications();
      // ✅ Convertit chaque élément en Map<String, dynamic>
      _notifications = raw.map((n) => _toMap(n)).toList();
      _nonLues = _notifications
          .where((n) => n['lue'] == false).length;
    } catch (e) {
      print('Erreur chargement notifications: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> rafraichirCompte() async {
    try {
      _nonLues = await _service.getNonLues();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marquerLue(int id) async {
    try {
      await _service.marquerLue(id);
      _notifications = _notifications.map((n) {
        if (n['id'] == id) {
          return Map<String, dynamic>.from({...n, 'lue': true});
        }
        return n;
      }).toList();
      _nonLues = _notifications
          .where((n) => n['lue'] == false).length;
      notifyListeners();
    } catch (e) {
      print('Erreur marquerLue: $e');
    }
  }

  Future<void> marquerToutesLues() async {
    try {
      await _service.marquerToutesLues();
      // ✅ Convertit chaque notif en Map<String, dynamic> propre
      _notifications = _notifications.map((n) =>
      Map<String, dynamic>.from({...n, 'lue': true})
      ).toList();
      _nonLues = 0;
      notifyListeners();
    } catch (e) {
      print('Erreur marquerToutesLues: $e');
    }
  }
}