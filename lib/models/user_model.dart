import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return UserModel(
      uid: (map['uid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      photoUrl: (map['photoUrl'] ?? '') as String,
      isOnline: (map['isOnline'] ?? false) as bool,
      lastSeen: parseTs(map['lastSeen']),
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseTs(map['createdAt']),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap({...data, 'uid': data['uid'] ?? doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'fcmToken': fcmToken ?? '',
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }

  /// Zego userID must be alphanumeric + underscore, <= 32 chars.
  /// Firebase UID already satisfies this, but sanitize defensively.
  String get zegoUserId {
    final sanitized = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return sanitized.length <= 32
        ? sanitized
        : sanitized.substring(0, 32);
  }
}
