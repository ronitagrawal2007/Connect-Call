import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Thin wrapper over FirebaseAuth + Firestore `users` doc.
/// Presence (isOnline/lastSeen) + FCM token managed here.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get firebaseUser => _auth.currentUser;

  CollectionReference get _users =>
      _db.collection(AppConstants.usersCollection);

  Future<UserModel?> fetchUserModel(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Stream<UserModel?> userDocStream(String uid) {
    return _users.doc(uid).snapshots().map(
        (d) => d.exists ? UserModel.fromDoc(d) : null);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name.trim());

    String fcmToken = '';
    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    } catch (_) {}

    final model = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      photoUrl: '',
      isOnline: true,
      lastSeen: DateTime.now(),
      fcmToken: fcmToken,
      createdAt: DateTime.now(),
    );
    await _users.doc(uid).set(model.toMap(), SetOptions(merge: true));
    return model;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    String fcmToken = '';
    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    } catch (_) {}

    await _users.doc(uid).set({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      if (fcmToken.isNotEmpty) 'fcmToken': fcmToken,
    }, SetOptions(merge: true));

    return fetchUserModel(uid);
  }

  Future<void> signOut(String? uid) async {
    if (uid != null && uid.isNotEmpty) {
      try {
        await _users.doc(uid).set({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> updatePresence(String uid, bool online) async {
    await _users.doc(uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateName(String uid, String name) async {
    await _users.doc(uid).set({'name': name.trim()}, SetOptions(merge: true));
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name.trim());
    }
  }
}
