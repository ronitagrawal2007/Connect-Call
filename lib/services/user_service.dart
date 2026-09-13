import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Firestore users directory.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all users (caller filters out self + applies search).
  Stream<List<UserModel>> usersStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromDoc).toList());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((d) => d.exists ? UserModel.fromDoc(d) : null);
  }
}
