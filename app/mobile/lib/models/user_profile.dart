class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.city,
    this.avatarUrl,
    required this.isVerified,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String role;
  final String? city;
  final String? avatarUrl;
  final bool isVerified;

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: (map['role'] ?? 'user') as String,
      city: map['city'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isVerified: (map['is_verified'] ?? false) as bool,
    );
  }
}
