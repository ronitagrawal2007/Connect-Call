import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Directory of users via Firestore Stream.
/// Screens use Consumer<UsersProvider> / context.watch.
class UsersProvider extends ChangeNotifier {
  final UserService _service = UserService();
  StreamSubscription<List<UserModel>>? _sub;

  List<UserModel> _allUsers = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  String? _selfUid;

  List<UserModel> get users {
    final q = _searchQuery.trim().toLowerCase();
    Iterable<UserModel> list =
        _allUsers.where((u) => u.uid != _selfUid);
    if (q.isNotEmpty) {
      list = list.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q));
    }
    return list.toList();
  }

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSelfUid(String? uid) {
    _selfUid = uid;
    notifyListeners();
  }

  /// Subscribe to Firestore users stream. Call once after login.
  void fetchUsers() {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _sub?.cancel();
    _sub = _service.usersStream().listen(
      (list) {
        _allUsers = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
