class User {
  final String? id;
  final String username;
  final String email;
  final String? fullName;
  final String? phone;
  final String? role;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.profileImage,
    this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['fullName']?.toString(),
      phone: map['phone']?.toString(),
      role: map['role']?.toString(),
      profileImage: map['profileImage']?.toString(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : null,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin'].toString()) : null,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
