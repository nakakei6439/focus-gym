import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/hive_service.dart';
import '../../core/services/purchase_service.dart';
import '../../shared/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = HiveService.instance;
  final _purchase = PurchaseService.instance;

  int get _streakDays => _db.getStreakDays();
  bool get _doneToday => _db.hasCompletedToday();

  String get _greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'おはようございます';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusGym'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('assets/logo.png', width: 32,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.visibility, color: AppTheme.primary, size: 28)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(_greetingMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('毎日ちょっとずつ、目をケア',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              _StreakCard(streakDays: _streakDays),
              if (_purchase.isInTrial && !_purchase.isPurchased) ...[
                const SizedBox(height: 16),
                const SizedBox(height: 12),
                _TrialCard(remainingDays: _purchase.trialRemainingDays),
              ],
              const SizedBox(height: 20),
              if (_doneToday)
                _DoneCard()
              else
                _StartButton(onTap: () => context.push('/training')),
              const Spacer(),
              _InfoBanner(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays;
  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.orangeAccent, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('連続達成',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$streakDays',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text('日',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (streakDays >= 7)
            Column(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 32)),
                Text('${streakDays ~/ 7}週間',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  final int remainingDays;
  const _TrialCard({required this.remainingDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '無料トライアル残り$remainingDays日 — 全機能をお試しください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text('今日のトレーニングを始める'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 70),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            textStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text('3分で完了します',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _DoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('今日のトレーニング完了！',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text('また明日も一緒に続けよう',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '本アプリは医療行為ではありません。眼の異常を感じた場合は医療機関へご相談ください。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
