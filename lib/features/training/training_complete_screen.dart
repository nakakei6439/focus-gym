import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';

class TrainingCompleteScreen extends StatefulWidget {
  final String trainingTypeName;
  final int streakDays;

  const TrainingCompleteScreen({
    super.key,
    required this.trainingTypeName,
    required this.streakDays,
  });

  @override
  State<TrainingCompleteScreen> createState() => _TrainingCompleteScreenState();
}

class _TrainingCompleteScreenState extends State<TrainingCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _encourageMessage {
    if (widget.streakDays >= 30) return '1ヶ月継続！あなたは目の健康の達人です！';
    if (widget.streakDays >= 14) return '2週間継続！素晴らしい習慣が身についています！';
    if (widget.streakDays >= 7) return '1週間継続！バッジをゲットしました！';
    if (widget.streakDays >= 3) return '3日連続！いい調子です！';
    if (widget.streakDays >= 1) return 'よくできました！続けることが大切です！';
    return 'お疲れさまでした！明日も続けましょう！';
  }

  bool get _showBadge => widget.streakDays >= 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Transform.scale(
                      scale: _scaleAnim.value,
                      child: const Text('🎉', style: TextStyle(fontSize: 80)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'トレーニング完了！',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.trainingTypeName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Text(
                                '${widget.streakDays}日連続',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const Text('達成！', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_showBadge) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏅', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.streakDays ~/ 7}週間バッジを獲得！',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      _encourageMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('ホームに戻る'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.push('/training'),
                      child: const Text('もう1種目やる'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
