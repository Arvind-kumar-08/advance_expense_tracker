import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User model for authentication and profile data
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? lastSyncedAt;


  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastSyncedAt,

  });

  /// Create UserModel from Firebase Auth user
  factory UserModel.fromFirebase(
      String uid,
      String email,
      String name,

      ) {
    return UserModel(
      uid: uid,
      email: email,
      name: name,
      createdAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),

    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,

      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'])
          : null,
    );
  }

  /// Copy with method for updating fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,

    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ name.hashCode;
  }
}