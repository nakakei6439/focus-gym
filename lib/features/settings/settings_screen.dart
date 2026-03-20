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

            // 課金
            Text('課金', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('購入状態',
                        style: TextStyle(fontSize: 17)),
                    trailing: Text(
                      _purchase.isPurchased ? '購入済み' : 'トライアル中',
                      style: TextStyle(
                        color: _purchase.isPurchased
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('購入を復元',
                        style: TextStyle(fontSize: 17)),
                    trailing: const Icon(Icons.restore_rounded,
                        size: 20, color: AppTheme.textSecondary),
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
                  ListTile(
                    title: const Text('参考文献',
                        style: TextStyle(fontSize: 17)),
                    trailing: const Icon(Icons.menu_book_rounded,
                        size: 20, color: AppTheme.textSecondary),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const _ReferencesDialog(),
                    ),
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

class _ReferencesDialog extends StatelessWidget {
  const _ReferencesDialog();

  static const _refs = [
    _Ref(
      training: '遠近ピント切替',
      citation:
          'Ciuffreda KJ et al. "Accommodation and related clinical findings in working age myopes." Optometry and Vision Science, 88(5), 560–569, 2011.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21378592/',
    ),
    _Ref(
      training: '追従運動',
      citation:
          'Kowler E. "Eye movements: The past 25 years." Vision Research, 51(13), 1457–1483, 2011.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21035483/',
    ),
    _Ref(
      training: 'ぼかし→くっきり',
      citation:
          'Scheiman M & Wick B. Clinical Management of Binocular Vision: Heterophoric, Accommodative, and Eye Movement Disorders. 4th ed. Wolters Kluwer, 2014.',
      url: null,
    ),
    _Ref(
      training: '輻輳運動',
      citation:
          'CITT Study Group. "Randomized clinical trial of treatments for symptomatic convergence insufficiency in children." Archives of Ophthalmology, 126(10), 1336–1349, 2008.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/18852411/',
    ),
    _Ref(
      training: '視点移動',
      citation:
          'Rayner K. "Eye movements in reading and information processing: 20 years of research." Psychological Bulletin, 124(3), 372–422, 1998.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/9849112/',
    ),
    _Ref(
      training: 'コントラスト順応',
      citation:
          'Owsley C et al. "Contrast sensitivity performance of eyes scheduled to undergo cataract surgery." Investigative Ophthalmology & Visual Science, 41(7), 1997–2003, 2000.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/10845630/',
    ),
    _Ref(
      training: 'ガルボーパッチ',
      citation:
          'Polat U et al. "Training the brain to overcome the effect of aging on the human eye." Scientific Reports, 2, 278, 2012.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/22355778/',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('参考文献'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _refs.length,
          separatorBuilder: (context, i) => const Divider(height: 24),
          itemBuilder: (context, i) {
            final ref = _refs[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.training,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(ref.citation,
                    style: const TextStyle(fontSize: 12, height: 1.6)),
                if (ref.url != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(ref.url!),
                        mode: LaunchMode.externalApplication),
                    child: Text(
                      ref.url!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _Ref {
  final String training;
  final String citation;
  final String? url;
  const _Ref({required this.training, required this.citation, this.url});
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
