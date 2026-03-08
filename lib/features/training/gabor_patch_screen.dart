import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/hive_service.dart';
import '../../core/models/training_session.dart';
import '../../core/services/daily_limit_service.dart';
import '../../shared/theme/app_theme.dart';

/// ガルボーパッチトレーニング画面
/// 縞模様（サイン波 × ガウシアンエンベロープ）を識別する知覚学習タスク
class GaborPatchScreen extends StatefulWidget {
  const GaborPatchScreen({super.key});

  @override
  State<GaborPatchScreen> createState() => _GaborPatchScreenState();
}

class _GaborPatchScreenState extends State<GaborPatchScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalTrials = 20;
  static const Duration _sessionDuration = Duration(minutes: 3);

  final _random = Random();
  late AnimationController _timer;
  double _angle = 0;
  double _spatialFreq = 0.05;
  double _contrast = 0.6;
  int _trials = 0;
  int _correct = 0;
  bool _answered = false;
  bool _finished = false;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: _sessionDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
    _stopwatch.start();
    _nextTrial();
  }

  void _nextTrial() {
    setState(() {
      _angle = _random.nextDouble() * pi;
      _spatialFreq = 0.04 + _random.nextDouble() * 0.04;
      _contrast = 0.4 + _random.nextDouble() * 0.4;
      _answered = false;
    });
  }

  void _answer(bool isLeft) {
    if (_answered || _finished) return;
    final correct = _angle < pi / 2;
    setState(() {
      _answered = true;
      _trials++;
      if (isLeft == correct) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_trials >= _totalTrials) {
        _finish();
      } else {
        _nextTrial();
      }
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    setState(() => _finished = true);
    _timer.stop();
    _stopwatch.stop();

    final elapsed = _stopwatch.elapsed.inSeconds;
    await DailyLimitService.instance.addSeconds(elapsed);
    await HiveService.instance.saveSession(TrainingSession(
      date: DateTime.now(),
      type: TrainingType.gaborPatch,
      durationSeconds: elapsed,
      completed: true,
    ));

    if (mounted) {
      context.pushReplacement('/training/complete');
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _sessionDuration.inSeconds -
        (_timer.value * _sessionDuration.inSeconds).round();
    final mins = remaining ~/ 60;
    final secs = remaining % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ガルボーパッチ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$mins:${secs.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _timer.value,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 6,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '縞模様はどちら向きですか？',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '回答 $_trials / $_totalTrials',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _timer,
                    builder: (_, child) => CustomPaint(
                      size: const Size(240, 240),
                      painter: _GaborPainter(
                        angle: _angle,
                        spatialFreq: _spatialFreq,
                        contrast: _contrast,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AnswerButton(
                        label: '↗ 右上向き',
                        onTap: () => _answer(false),
                        disabled: _answered,
                      ),
                      _AnswerButton(
                        label: '↖ 左上向き',
                        onTap: () => _answer(true),
                        disabled: _answered,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_trials > 0)
                    Text(
                      '正解率: ${(_correct / _trials * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _AnswerButton({
    required this.label,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: disabled ? null : onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(140, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// ガルボーパッチを描画する CustomPainter
class _GaborPainter extends CustomPainter {
  final double angle;
  final double spatialFreq;
  final double contrast;

  _GaborPainter({
    required this.angle,
    required this.spatialFreq,
    required this.contrast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sigma = size.width / 6;
    final paint = Paint()..strokeWidth = 1;

    for (int px = 0; px < size.width.toInt(); px++) {
      for (int py = 0; py < size.height.toInt(); py++) {
        final dx = px - cx;
        final dy = py - cy;

        // ガウシアンエンベロープ
        final gaussian = exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));

        // サイン波（角度に応じた方向）
        final xRot = dx * cos(angle) + dy * sin(angle);
        final sine = sin(2 * pi * spatialFreq * xRot);

        // 輝度値（0.0 〜 1.0）
        final value = 0.5 + 0.5 * contrast * sine * gaussian;
        final gray = (value.clamp(0.0, 1.0) * 255).round();

        paint.color = Color.fromRGBO(gray, gray, gray, 1.0);
        canvas.drawRect(Rect.fromLTWH(px.toDouble(), py.toDouble(), 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GaborPainter old) =>
      old.angle != angle ||
      old.spatialFreq != spatialFreq ||
      old.contrast != contrast;
}
