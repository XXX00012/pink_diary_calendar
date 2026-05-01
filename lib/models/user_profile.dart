class UserProfile {
  const UserProfile({
    required this.avatarPath,
    required this.nickname,
    required this.signature,
    required this.themeKey,
    required this.updatedAt,
  });

  static UserProfile defaults() {
    return UserProfile(
      avatarPath: '',
      nickname: '小桃子',
      signature: '今天也要好好生活',
      themeKey: 'pink',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String avatarPath;
  final String nickname;
  final String signature;
  final String themeKey;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? avatarPath,
    String? nickname,
    String? signature,
    String? themeKey,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      avatarPath: avatarPath ?? this.avatarPath,
      nickname: nickname ?? this.nickname,
      signature: signature ?? this.signature,
      themeKey: themeKey ?? this.themeKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatarPath': avatarPath,
      'nickname': nickname,
      'signature': signature,
      'themeKey': themeKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final defaults = UserProfile.defaults();
    return UserProfile(
      avatarPath: json['avatarPath'] as String? ?? defaults.avatarPath,
      nickname: json['nickname'] as String? ?? defaults.nickname,
      signature: json['signature'] as String? ?? defaults.signature,
      themeKey: json['themeKey'] as String? ?? defaults.themeKey,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          defaults.updatedAt,
    );
  }
}
