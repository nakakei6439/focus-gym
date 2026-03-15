import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/training_session.dart';
import '../../core/services/purchase_service.dart';
import '../../shared/theme/app_theme.dart';

class TrainingListScreen extends StatefulWidget {
  const TrainingListScreen({super.key});

  @override
  State<TrainingListScreen> createState() => _TrainingListScreenState();
}

class _TrainingListScreenState extends State<TrainingListScreen> {
  final _purchase = PurchaseService.instance;

  /// トレーニングが使えるか
  /// 無料トレーニング OR 購入済み OR トライアル中
  bool _isTrainingUnlocked(TrainingType type) =>
      type.isFree || _purchase.isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トレーニングを選ぶ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('今日はどれをやる？',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('各トレーニングは1分間です',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            ...TrainingType.values.map((type) => _TrainingCard(
                  type: type,
                  isUnlocked: _isTrainingUnlocked(type),
                  isComingSoon: !type.isReleasedV1,
                  onPurchase: _showPurchaseDialog,
                  onInfo: () => _showEvidence(context, type),
                )),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('全トレーニングをアンロック'),
        content: const Text(
          '300円の買い切り購入で、すべてのトレーニングを永久にご利用いただけます。\n\n遠近ピント切替は引き続き無料でご利用いただけます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PurchaseService.instance.purchase();
              if (mounted) setState(() {});
            },
            child: const Text('300円で購入'),
          ),
        ],
      ),
    );
  }

  void _showEvidence(BuildContext context, TrainingType type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Flexible(child: Text(type.displayName)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(type.evidenceDescription,
              style: const TextStyle(height: 1.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final int remainingDays;
  const _TrialBanner({required this.remainingDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '無料トライアル期間：残り$remainingDays日',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final TrainingType type;
  final bool isUnlocked;
  final bool isComingSoon;
  final VoidCallback onPurchase;
  final VoidCallback onInfo;

  const _TrainingCard({
    required this.type,
    required this.isUnlocked,
    required this.isComingSoon,
    required this.onPurchase,
    required this.onInfo,
  });

  bool get _isLocked => !isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isComingSoon ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isComingSoon
                ? null
                : (_isLocked ? onPurchase : () => _startTraining(context)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (isComingSoon || _isLocked)
                          ? Colors.grey.withValues(alpha: 0.1)
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(type.emoji,
                          style: TextStyle(
                              fontSize: 28,
                              color: (isComingSoon || _isLocked)
                                  ? Colors.grey
                                  : null)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                type.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: (isComingSoon || _isLocked)
                                            ? Colors.grey
                                            : null),
                              ),
                            ),
                            if (isComingSoon)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('近日公開',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(type.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: (isComingSoon || _isLocked)
                                        ? Colors.grey
                                        : null)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: isComingSoon ? null : onInfo,
                        child: Icon(Icons.info_outline_rounded,
                            size: 20,
                            color: isComingSoon
                                ? Colors.grey.withValues(alpha: 0.5)
                                : AppTheme.primary.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        isComingSoon
                            ? Icons.schedule_rounded
                            : (_isLocked
                                ? Icons.lock_rounded
                                : Icons.arrow_forward_ios_rounded),
                        size: 18,
                        color: (isComingSoon || _isLocked)
                            ? Colors.grey
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTraining(BuildContext context) {
    if (type == TrainingType.gaborPatch) {
      context.push('/training/gabor');
    } else {
      context.push('/training/${type.name}');
    }
  }
}
