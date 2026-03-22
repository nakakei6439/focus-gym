import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/training_session.dart';
import '../../shared/theme/app_theme.dart';

class TrainingListScreen extends StatelessWidget {
  const TrainingListScreen({super.key});

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
            Text('今日はどれをやる？', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('各トレーニングは1分間です', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ...TrainingType.values.map((type) => _TrainingCard(type: type)),
          ],
        ),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final TrainingType type;
  const _TrainingCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/training/${type.name}'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(type.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.displayName, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(type.description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
