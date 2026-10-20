import 'task.dart';

/// Reward types deliberately remain independent of the task-category taxonomy.
class AchievementType {
  const AchievementType(this.id, this.label, this.name, this.pattern);
  final String id, label, name, pattern;
}

const achievementTypes = [
  AchievementType('code', '写代码', '代码火花', r'写代码|编程|开发|代码|程序|debug'),
  AchievementType('cooking', '做美食', '厨房灵感', r'做饭|做菜|烹饪|烘焙|做美食|下厨|煮|炒菜'),
  AchievementType('travel', '旅游', '远方足迹', r'旅游|旅行|出游|机票|酒店|景点'),
  AchievementType('swimming', '游泳', '水中畅游', r'游泳|泳池|蛙泳|自由泳'),
  AchievementType('fitness', '健身', '力量时刻', r'健身|力量训练|举铁|哑铃|瑜伽|锻炼'),
  AchievementType('photo', '拍照', '光影收藏', r'拍照|摄影|拍摄|照相'),
  AchievementType('dining', '吃饭', '美味时光', r'吃饭|吃好吃的|吃美食|聚餐|晚餐|午餐|早餐|餐厅'),
  AchievementType('makeup', '化妆', '色彩心情', r'化妆|上妆|口红|眼妆'),
  AchievementType('life', '生活', '生活一角', r'打扫|清洁|买|购物|收拾|房间|家务|生活|日常'),
  AchievementType('fun', '娱乐', '轻松片刻', r'娱乐|游戏|电影|音乐|休闲|玩|追剧'),
  AchievementType('sport', '运动', '活力脚印', r'运动|跑步|散步|走走|骑行|球|健康'),
  AchievementType('work', '工作', '认真一笔', r'工作|报告|申请|邮件|会议|项目|办公'),
  AchievementType('social', '社交', '连接时刻', r'社交|朋友|电话|聚会|联系|聊天|小林'),
  AchievementType('general', '通用成就', '行动印记', ''),
];

AchievementType achievementType(String id) => achievementTypes.firstWhere(
  (type) => type.id == id,
  orElse: () => achievementTypes.last,
);

AchievementType matchAchievement(Task task) {
  // Match the action title, not advice/obstacles that may mention other actions.
  for (final type in achievementTypes.take(8)) {
    if (RegExp(type.pattern, caseSensitive: false).hasMatch(task.title)) {
      return type;
    }
  }
  for (final type in achievementTypes.skip(8).take(5)) {
    if (RegExp(type.pattern).hasMatch(task.title)) return type;
  }
  // Only broad fallbacks consult the migrated category; activity recognition
  // above never loses travel/social rewards when task categories are merged.
  return achievementType(switch (task.category) {
    '生活' => 'life',
    '工作' => 'work',
    '健康' => 'sport',
    _ => 'general',
  });
}

class Achievement {
  const Achievement({
    required this.typeId,
    required this.taskId,
    required this.obtainedAt,
    required this.snapshot,
  });
  final String typeId, taskId;
  final DateTime obtainedAt;
  final Task snapshot;
  Map<String, Object?> toJson() => {
    'typeId': typeId,
    'taskId': taskId,
    'obtainedAt': obtainedAt.toUtc().toIso8601String(),
    'snapshot': snapshot.toJson(),
  };
  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    typeId: json['typeId'] as String,
    taskId: json['taskId'] as String,
    obtainedAt: DateTime.parse(json['obtainedAt'] as String).toUtc(),
    snapshot: Task.fromJson(json['snapshot'] as Map<String, dynamic>),
  );
}
