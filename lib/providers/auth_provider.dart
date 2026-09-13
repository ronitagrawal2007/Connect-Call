import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/calling_service.dart';

/// Auth state for UI via Consumer<AuthProvider> / context.watch/read.
/// Calls notifyListeners() after each state change per spec.
class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Splash: resolve Firebase session -> Firestore profile -> init Zego.
  Future<void> checkAuth() async {
    _setLoading(true);
    _setError(null);
    try {
      final fb = _service.firebaseUser;
      if (fb == null) {
        _currentUser = null;
      } else {
        final model = await _service.fetchUserModel(fb.uid);
        _currentUser = model;
        if (model != null) {
          await _service.updatePresence(model.uid, true);
          await _initCalling(model);
        }
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Authentication failed');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      final model =
          await _service.signIn(email: email, password: password);
      _currentUser = model;
      if (model != null) {
        await _initCalling(model);
      }
      notifyListeners();
      return model != null;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e));
      notifyListeners();
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final model = await _service.signUp(
          name: name, email: email, password: password);
      _currentUser = model;
      await _initCalling(model);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e));
      notifyListeners();
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _service.signOut(_currentUser?.uid);
      await CallingService.instance.uninit();
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> updatePresence(bool online) async {
    if (_currentUser == null) return;
    try {
      await _service.updatePresence(_currentUser!.uid, online);
      _currentUser = _currentUser!.copyWith(
        isOnline: online,
        lastSeen: DateTime.now(),
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateName(String name) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      await _service.updateName(_currentUser!.uid, name);
      _currentUser = _currentUser!.copyWith(name: name.trim());
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initCalling(UserModel model) async {
    try {
      await CallingService.instance.initZego(
        uid: model.zegoUserId,
        userName: model.name,
      );
    } catch (_) {
      // Never crash app if Zego init fails; calling will surface error later.
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
