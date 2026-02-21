class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String roleName;
  final String roleKey;
  final String? gender;
  final Map<String, dynamic> extraData;
  final bool isVerified;
  final String createdAt;

  String? get avatar => extraData['avatar'] as String?;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.roleName,
    required this.roleKey,
    this.gender,
    this.extraData = const {},
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'role': roleName,
    'roleKey': roleKey,
    'gender': gender,
    'is_verified': isVerified,
    'createdAt': createdAt,
    ...extraData,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Extract base fields and leave the rest in extraData
    final baseFields = [
      'userId',
      'name',
      'email',
      'role',
      'roleKey',
      'gender',
      'is_verified',
      'createdAt',
    ];
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((key, value) => baseFields.contains(key));

    return UserProfile(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleName: json['role'] ?? '',
      roleKey: json['roleKey'] ?? '',
      gender: json['gender'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['createdAt'] ?? '',
      extraData: extra,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? roleName,
    String? roleKey,
    String? gender,
    Map<String, dynamic>? extraData,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      roleName: roleName ?? this.roleName,
      roleKey: roleKey ?? this.roleKey,
      gender: gender ?? this.gender,
      extraData: extraData ?? this.extraData,
      createdAt: createdAt,
    );
  }
}
