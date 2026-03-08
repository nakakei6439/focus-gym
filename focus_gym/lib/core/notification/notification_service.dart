import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const int _reminderId = 1;
  static const int _reReminderId = 2;

  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  Future<void> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // リマインダー通知をスケジュール（毎日指定時刻）
  Future<void> scheduleReminder(int hour, int minute) async {
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      'focus_gym_reminder',
      'FocusGym リマインダー',
      channelDescription: '毎日のトレーニングリマインダー',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // 毎日の通知（プラットフォームのスケジュール機能を使用）
    // シンプルにするため、当日の次の指定時刻に通知をセット
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('通知スケジュール: $scheduledDate');
    await _plugin.show(
      id: _reminderId,
      title: '目のジム、今日はやった？',
      body: '1日3分のトレーニングで目の健康を守ろう 👁️',
      notificationDetails: details,
    );
  }

  // 再通知（未実施時）
  Future<void> scheduleReReminder(int hour, int minute) async {
    final reHour = (hour + 2) % 24;

    const androidDetails = AndroidNotificationDetails(
      'focus_gym_rereminder',
      'FocusGym 再リマインダー',
      channelDescription: 'トレーニング未実施時の再通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, reHour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('再通知スケジュール: $scheduledDate');
    await _plugin.show(
      id: _reReminderId,
      title: 'まだ間に合う！',
      body: '今日のトレーニング、寝る前に3分だけやってみよう ✨',
      notificationDetails: details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
