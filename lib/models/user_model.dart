import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username; // Unchangeable @username format
  String nickname;        // Changeable display name
  String profileImageUrl;
  String bannerImageUrl;
  final bool isModerator;
  final bool isVerified;
  final DateTime createdAt;
  DateTime lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.nickname,
    this.profileImageUrl = '',
    this.bannerImageUrl = '',
    this.isModerator = false,
    this.isVerified = false,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      bannerImageUrl: map['bannerImageUrl'] ?? '',
      isModerator: map['isModerator'] ?? false,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'isModerator': isModerator,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  UserModel copyWith({
    String? nickname,
    String? profileImageUrl,
    String? bannerImageUrl,
    bool? isModerator,
    bool? isVerified,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isModerator: isModerator ?? this.isModerator,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}