
enum PlayerRole { normal, struggling }
enum PlayerType { human, bot }

class PlayerModel {
  final String id;
  final String name;
  final PlayerRole role;
  final PlayerType type;
  final int friendshipPoints;
  final bool isReady;
  
  // حقول الدعم الثنائي (1-on-1)
  final int empathyPoints;
  final int sessionsCompleted;
  final String avatarId;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    this.type = PlayerType.human,
    this.friendshipPoints = 0,
    this.isReady = false,
    this.empathyPoints = 0,
    this.sessionsCompleted = 0,
    this.avatarId = '👤',
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String? ?? map['uid'] as String? ?? '',
      name: (map['name'] as String? ?? map['nickname'] as String? ?? '').trim(),
      role: map['role'] == 'struggling' ? PlayerRole.struggling : PlayerRole.normal,
      type: map['type'] == 'bot' ? PlayerType.bot : PlayerType.human,
      friendshipPoints: (map['friendshipPoints'] as int?) ?? 0,
      isReady: (map['isReady'] as bool?) ?? false,
      empathyPoints: (map['empathyPoints'] as int?) ?? 0,
      sessionsCompleted: (map['sessionsCompleted'] as int?) ?? 0,
      avatarId: map['avatarId'] as String? ?? '👤',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role == PlayerRole.struggling ? 'struggling' : 'normal',
    'type': type == PlayerType.bot ? 'bot' : 'human',
    'friendshipPoints': friendshipPoints,
    'isReady': isReady,
    'empathyPoints': empathyPoints,
    'sessionsCompleted': sessionsCompleted,
    'avatarId': avatarId,
  };

  PlayerModel copyWith({
    String? id,
    String? name,
    PlayerRole? role,
    PlayerType? type,
    int? friendshipPoints,
    bool? isReady,
    int? empathyPoints,
    int? sessionsCompleted,
    String? avatarId,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      type: type ?? this.type,
      friendshipPoints: friendshipPoints ?? this.friendshipPoints,
      isReady: isReady ?? this.isReady,
      empathyPoints: empathyPoints ?? this.empathyPoints,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}
