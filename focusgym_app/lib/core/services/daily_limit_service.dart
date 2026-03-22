import '../database/hive_service.dart';

/// 1日5分のトレーニング上限管理
class DailyLimitService {
  static const int maxDailySeconds = 5 * 60; // 300秒
  static const int warningSeconds = 4 * 60;  // 240秒（警告タイミング・残り1分以下）

  static DailyLimitService? _instance;
  static DailyLimitService get instance => _instance ??= DailyLimitService._();
  DailyLimitService._();

  final _db = HiveService.instance;

  /// 今日の累計トレーニング秒数
  int get todaySeconds {
    _resetIfNewDay();
    return _db.getSetting(HiveService.keyDailyTrainingSeconds, defaultValue: 0) as int;
  }

  /// 残り秒数
  int get remainingSeconds => (maxDailySeconds - todaySeconds).clamp(0, maxDailySeconds);

  /// 今日の上限に達しているか
  bool get isLimitReached => todaySeconds >= maxDailySeconds;

  /// 警告ゾーンか（残り1分以下）
  bool get isWarning => todaySeconds >= warningSeconds && !isLimitReached;

  /// トレーニング秒数を加算
  Future<void> addSeconds(int seconds) async {
    _resetIfNewDay();
    final current = todaySeconds;
    await _db.saveSetting(HiveService.keyDailyTrainingSeconds, current + seconds);
  }

  /// 日付が変わっていたらリセット
  void _resetIfNewDay() {
    final today = _todayString();
    final lastDate = _db.getSetting(HiveService.keyLastTrainingDate, defaultValue: '') as String;
    if (lastDate != today) {
      _db.saveSetting(HiveService.keyDailyTrainingSeconds, 0);
      _db.saveSetting(HiveService.keyLastTrainingDate, today);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get remainingLabel {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '$mins分${secs.toString().padLeft(2, '0')}秒';
  }
}
