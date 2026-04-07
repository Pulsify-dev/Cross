class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImageUrl:
          json['avatar_url']?.toString() ?? json['profileImageUrl']?.toString(),
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}