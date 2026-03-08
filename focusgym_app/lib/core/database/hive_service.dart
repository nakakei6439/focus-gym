import 'package:hive_flutter/hive_flutter.dart';
import '../models/training_session.dart';

class HiveService {
  static const String _sessionBoxName = 'training_sessions';
  static const String _settingsBoxName = 'settings';

  static const String keyDistanceAlertDisabled = 'distanceAlertDisabled';
  static const String keyDistanceAlertSkippedDate = 'distanceAlertSkippedDate';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();
  HiveService._();

  Box<TrainingSession> get _sessionBox => Hive.box<TrainingSession>(_sessionBoxName);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(_settingsBoxName);

  static Future<void> openBoxes() async {
    await Hive.openBox<TrainingSession>(_sessionBoxName);
    await Hive.openBox<dynamic>(_settingsBoxName);
  }

  // セッションの保存
  Future<void> saveSession(TrainingSession session) async {
    await _sessionBox.add(session);
  }

  // 全セッション取得（日付降順）
  List<TrainingSession> getAllSessions() {
    final sessions = _sessionBox.values.toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  // 特定日のセッション取得
  List<TrainingSession> getSessionsForDate(DateTime date) {
    return _sessionBox.values.where((s) {
      return s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day;
    }).toList();
  }

  // 今日完了済みか確認
  bool hasCompletedToday() {
    final today = DateTime.now();
    return getSessionsForDate(today).any((s) => s.completed);
  }

  // 連続達成日数を計算
  int getStreakDays() {
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final sessions = getSessionsForDate(checkDate);
      if (sessions.any((s) => s.completed)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // 今月のトレーニング実施日一覧
  Set<DateTime> getCompletedDaysThisMonth() {
    final now = DateTime.now();
    return _sessionBox.values
        .where((s) =>
            s.completed &&
            s.date.year == now.year &&
            s.date.month == now.month)
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();
  }

  // 累計トレーニング時間（秒）
  int getTotalDurationSeconds() {
    return _sessionBox.values
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  // 設定の保存・取得
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}
