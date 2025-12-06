/// User model for Sawn App
class UserModel {
  final String id;
  final String googleId;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? driveFolderId;
  final bool pinEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.googleId,
    required this.email,
    this.name,
    this.avatarUrl,
    this.driveFolderId,
    this.pinEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      googleId: json['google_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      driveFolderId: json['drive_folder_id'] as String?,
      pinEnabled: json['pin_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_id': googleId,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'drive_folder_id': driveFolderId,
      'pin_enabled': pinEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? googleId,
    String? email,
    String? name,
    String? avatarUrl,
    String? driveFolderId,
    bool? pinEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
