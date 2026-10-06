

/// UserModel — mirrors public.users table
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String level;
  final String tier;
  final int totalCompetitionPoints;
  final int weeklyCompetitionPoints;
  final int audiencePoints;
  final int streakDays;
  final DateTime? lastPostDate;
  final bool isBanned;
  final bool isAdmin;
  final int redTierWins;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.tier,
    required this.totalCompetitionPoints,
    required this.weeklyCompetitionPoints,
    required this.audiencePoints,
    required this.streakDays,
    this.lastPostDate,
    required this.isBanned,
    required this.isAdmin,
    required this.redTierWins,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                       json['id'] as String,
    username:                 json['username'] as String,
    displayName:              json['display_name'] as String,
    avatarUrl:                json['avatar_url'] as String?,
    level:                    json['level'] as String? ?? 'مجهول',
    tier:                     json['tier'] as String? ?? 'blue',
    totalCompetitionPoints:   json['total_competition_points'] as int? ?? 0,
    weeklyCompetitionPoints:  json['weekly_competition_points'] as int? ?? 0,
    audiencePoints:           json['audience_points'] as int? ?? 0,
    streakDays:               json['streak_days'] as int? ?? 0,
    lastPostDate:             json['last_post_date'] != null
        ? DateTime.tryParse(json['last_post_date'] as String)
        : null,
    isBanned:    json['is_banned'] as bool? ?? false,
    isAdmin:     json['is_admin'] as bool? ?? false,
    redTierWins: json['red_tier_wins'] as int? ?? 0,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':                       id,
    'username':                 username,
    'display_name':             displayName,
    'avatar_url':               avatarUrl,
    'level':                    level,
    'tier':                     tier,
    'total_competition_points': totalCompetitionPoints,
    'weekly_competition_points':weeklyCompetitionPoints,
    'audience_points':          audiencePoints,
    'streak_days':              streakDays,
    'last_post_date':           lastPostDate?.toIso8601String().split('T').first,
    'is_banned':                isBanned,
    'is_admin':                 isAdmin,
    'red_tier_wins':            redTierWins,
    'created_at':               createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? level,
    String? tier,
    int? totalCompetitionPoints,
    int? weeklyCompetitionPoints,
    int? audiencePoints,
    int? streakDays,
    DateTime? lastPostDate,
    bool? isBanned,
    bool? isAdmin,
    int? redTierWins,
  }) => UserModel(
    id: id,
    username:                username  ?? this.username,
    displayName:             displayName ?? this.displayName,
    avatarUrl:               avatarUrl ?? this.avatarUrl,
    level:                   level ?? this.level,
    tier:                    tier ?? this.tier,
    totalCompetitionPoints:  totalCompetitionPoints ?? this.totalCompetitionPoints,
    weeklyCompetitionPoints: weeklyCompetitionPoints ?? this.weeklyCompetitionPoints,
    audiencePoints:          audiencePoints ?? this.audiencePoints,
    streakDays:              streakDays ?? this.streakDays,
    lastPostDate:            lastPostDate ?? this.lastPostDate,
    isBanned:                isBanned ?? this.isBanned,
    isAdmin:                 isAdmin ?? this.isAdmin,
    redTierWins:             redTierWins ?? this.redTierWins,
    createdAt:               createdAt,
  );

  /// Account age in hours (for anti-manipulation vote weight check)
  bool get isOlderThan48Hours =>
      DateTime.now().difference(createdAt).inHours >= 48;
}
