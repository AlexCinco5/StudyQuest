class ProfileEntity {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int totalXp;
  final int currentStreak;

  ProfileEntity({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.totalXp,
    required this.currentStreak,
  });

  factory ProfileEntity.fromMap(Map<String, dynamic> map) {
    return ProfileEntity(
      id: map['id'] as String,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      totalXp: map['total_xp'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
    );
  }
}