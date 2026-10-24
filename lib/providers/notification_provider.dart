import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';
import '../data/models/notification_model.dart';
import 'auth_provider.dart';

/// Provider untuk manajemen notifikasi pengguna.
class NotificationProvider extends ChangeNotifier {
  final StorageService? _storage;
  final AuthProvider? _auth;

  static const String _kKeyPrefix = 'linakan_notifications_';

  String? _userId;
  List<NotificationModel> _notifications = [];

  NotificationProvider(this._storage, this._auth) {
    _userId = _auth?.currentUserId;
    _load();
    _auth?.addListener(_onAuthChanged);
  }

  /// Constructor ringan untuk pengujian / widget tanpa storage.
  NotificationProvider.empty()
      : _storage = null,
        _auth = null {
    _userId = 'guest';
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String get _key => '$_kKeyPrefix${_userId ?? 'guest'}';

  void _onAuthChanged() {
    final newId = _auth?.currentUserId;
    if (newId == _userId) return;
    _userId = newId;
    _load();
    notifyListeners();
  }

  void add({
    required String title,
    required String message,
    required String type,
  }) {
    final notif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId ?? 'guest',
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _persist();
    notifyListeners();
  }

  void markAllRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _persist();
    notifyListeners();
  }

  void markRead(String id) {
    _notifications = _notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    _persist();
    notifyListeners();
  }

  void delete(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persist();
    notifyListeners();
  }

  void _load() {
    final raw = _storage?.getString(_key);
    if (raw == null) {
      _notifications = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _notifications = list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _notifications = [];
    }
  }

  void _persist() {
    _storage?.setString(
      _key,
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }
}
