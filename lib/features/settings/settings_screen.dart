import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/hive_service.dart';
import '../../core/notification/notification_service.dart';
import '../../core/services/purchase_service.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = HiveService.instance;
  final _purchase = PurchaseService.instance;

  bool _notificationEnabled = false;
  int _notifyHour = 20;
  int _notifyMinute = 0;

  @override
  void initState() {
    super.initState();
    _notificationEnabled =
        _db.getSetting('notification_enabled', defaultValue: false) as bool;
    _notifyHour = _db.getSetting('notify_hour', defaultValue: 20) as int;
    _notifyMinute = _db.getSetting('notify_minute', defaultValue: 0) as int;
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) await NotificationService.instance.requestPermission();
    await _db.saveSetting('notification_enabled', value);
    if (value) {
      await NotificationService.instance
          .scheduleReminder(_notifyHour, _notifyMinute);
    } else {
      await NotificationService.instance.cancelAll();
    }
    setState(() => _notificationEnabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifyHour, minute: _notifyMinute),
      helpText: 'リマインダーの時刻を選択',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _db.saveSetting('notify_hour', picked.hour);
    await _db.saveSetting('notify_minute', picked.minute);
    setState(() {
      _notifyHour = picked.hour;
      _notifyMinute = picked.minute;
    });
    if (_notificationEnabled) {
      await NotificationService.instance
          .scheduleReminder(picked.hour, picked.minute);
    }
  }

  String get _timeLabel {
    final h = _notifyHour.toString().padLeft(2, '0');
    final m = _notifyMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _restorePurchases() async {
    await _purchase.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('購入の復元を実行しました')),
      );
      setState(() {});
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 通知設定
            Text('通知設定',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('リマインダー通知',
                        style: TextStyle(fontSize: 17)),
                    subtitle: const Text('毎日のトレーニングをお知らせします'),
                    value: _notificationEnabled,
                    onChanged: _toggleNotification,
                    activeThumbColor: AppTheme.primary,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  ),
                  if (_notificationEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('通知時刻',
                          style: TextStyle(fontSize: 17)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_timeLabel,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                      onTap: _pickTime,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 課金・購入
            Text('プレミアム機能',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _purchase.isPurchased
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      color: _purchase.isPurchased
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      _purchase.isPurchased
                          ? '全機能アンロック済み'
                          : _purchase.isInTrial
                              ? 'トライアル中（残り${_purchase.trialRemainingDays}日）'
                              : '全機能をアンロック（300円）',
                      style: const TextStyle(fontSize: 17),
                    ),
                    subtitle: _purchase.isPurchased
                        ? const Text('すべてのトレーニングが使えます')
                        : null,
                    trailing: _purchase.isPurchased
                        ? null
                        : ElevatedButton(
                            onPressed: () async {
                              await _purchase.purchase();
                              if (mounted) setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                            ),
                            child: const Text('購入'),
                          ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded,
                        color: AppTheme.textSecondary),
                    title: const Text('購入を復元する',
                        style: TextStyle(fontSize: 17)),
                    subtitle: const Text('以前の購入を復元します'),
                    onTap: _restorePurchases,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // アプリについて
            Text('アプリについて',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('バージョン',
                        style: TextStyle(fontSize: 17)),
                    trailing: const Text('1.0.0',
                        style:
                            TextStyle(color: AppTheme.textSecondary)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('サポート',
                        style: TextStyle(fontSize: 17)),
                    trailing: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onTap: () => _launchUrl(
                        'https://nakakei6439.github.io/focus-gym/'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('プライバシーポリシー',
                        style: TextStyle(fontSize: 17)),
                    trailing: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onTap: () => _launchUrl(
                        'https://nakakei6439.github.io/focus-gym/privacy.html'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const Divider(height: 1),
                  const _DisclaimerTile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerTile extends StatelessWidget {
  const _DisclaimerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('医療的注意事項',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '・本アプリは医療行為ではありません\n'
            '・視力改善・老眼の治癒を保証するものではありません\n'
            '・眼の異常を感じた場合は医療機関へご相談ください',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(height: 1.8),
          ),
        ],
      ),
    );
  }
}
