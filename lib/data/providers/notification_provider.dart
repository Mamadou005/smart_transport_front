import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<dynamic> _notifications = [];
  int  _nonLues   = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int  get nonLues   => _nonLues;
  bool get isLoading => _isLoading;

  Future<void> charger() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _service.getNotifications();
      _nonLues = _notifications
          .where((n) => n['lue'] == false).length;
    } catch (_) {}
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
        if (n['id'] == id) return {...n, 'lue': true};
        return n;
      }).toList();
      _nonLues = _notifications
          .where((n) => n['lue'] == false).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marquerToutesLues() async {
    try {
      await _service.marquerToutesLues();
      _notifications = _notifications.map((n) =>
      {...n, 'lue': true}).toList();
      _nonLues = 0;
      notifyListeners();
    } catch (_) {}
  }
}