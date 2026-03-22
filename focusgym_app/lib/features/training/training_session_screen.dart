import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/hive_service.dart';
import '../../core/models/training_session.dart';
import '../../core/services/daily_limit_service.dart';
import '../../shared/theme/app_theme.dart';

class TrainingSessionScreen extends StatefulWidget {
  final String trainingType;
  const TrainingSessionScreen({super.key, required this.trainingType});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with TickerProviderStateMixin {
  static const int _totalSeconds = 60; // 1分

  // 記号リスト（遠近ピント切替）
  static const List<String> _nearFarChars = ['●', '▲', '■', '◆', '★'];

  Duration get _nearFarAnimDuration {
    const startMs = 2000.0;
    const endMs = 600.0;
    const decay = 0.95;
    final ms = (endMs + (startMs - endMs) * pow(decay, _tapCount)).round();
    return Duration(milliseconds: ms.clamp(endMs.toInt(), startMs.toInt()));
  }

  // ランダムフレーズリスト（ぼかし→くっきり）
  static const List<String> _blurPhrases = [
    '老眼トレーニング\nFocusGym',
    '毎日1分間\n目の体操',
    '近くと遠くを\n交互に見る',
    '目の筋肉を\nほぐしましょう',
    '視力を守ろう\n今日も続けて',
    '目はいつも\n頑張っている',
    '健康な目で\n毎日を楽しむ',
  ];

  // ランダムフレーズリスト（コントラスト順応）
  static const List<String> _contrastPhrases = [
    '目のトレーニング\n毎日続けよう',
    'ピントを\n合わせてみて',
    '視力は\n鍛えられる',
    '今日も\n目の体操',
    'FocusGym\nで習慣化',
    'コントラストを\n感じてみて',
    'ゆっくりと\n読んでみよう',
  ];

  late TrainingType _type;
  late AnimationController _trainingController;
  late AnimationController _timerController;
  late String _nearFarChar;
  late String _blurPhrase;
  late String _contrastPhrase;

  final _random = Random();
  int _remainingSeconds = _totalSeconds;
  int _tapCount = 0;
  bool _isPaused = false;
  bool _isStarted = false;
  bool _isSmall = true;
  bool _isAnimating = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _type = TrainingType.values.firstWhere(
      (t) => t.name == widget.trainingType,
      orElse: () => TrainingType.nearFar,
    );

    // セッションごとにランダムなテキストを選択
    _nearFarChar = _nearFarChars[_random.nextInt(_nearFarChars.length)];
    _blurPhrase = _blurPhrases[_random.nextInt(_blurPhrases.length)];
    _contrastPhrase = _contrastPhrases[_random.nextInt(_contrastPhrases.length)];

    final trainingDuration = _type == TrainingType.contrastAdapt
        ? const Duration(seconds: 4)
        : const Duration(seconds: 3);

    _trainingController = AnimationController(
      vsync: this,
      duration: trainingDuration,
    );

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    );

  }

  /// 遠近アニメーションを target まで実行し、完了時に状態を更新する。
  /// 一時停止による cancel はcatchErrorで無視し、_isAnimating は true のまま保持する。
  void _runNearFarAnimation(double target) {
    setState(() => _isAnimating = true);
    _trainingController
        .animateTo(target, duration: _nearFarAnimDuration, curve: Curves.easeInOut)
        .orCancel
        .then((_) {
          if (!mounted) return;
          final reachedSmall = target == 0.0;
          setState(() {
            _isAnimating = false;
            _isSmall = reachedSmall;
          });
        })
        .catchError((_) {
          // 一時停止によるキャンセル → _isAnimating は true のまま保持
        });
  }

  bool _shouldShowDistanceAlert() {
    final disabled = HiveService.instance.getSetting(
      HiveService.keyDistanceAlertDisabled,
      defaultValue: false,
    );
    return disabled != true;
  }

  void _onStartPressed() {
    if (_shouldShowDistanceAlert()) {
      _showDistanceAlert();
    } else {
      _startTraining();
    }
  }

  void _startTraining() {
    setState(() {
      _isStarted = true;
      _isSmall = true;
    });
    if (_type == TrainingType.nearFar) {
      _runNearFarAnimation(1.0); // 小→大からスタート
    } else {
      _trainingController.repeat(reverse: true);
    }
    _timerController.forward();
    _startCountdown();
  }

  void _onNearFarTap() {
    if (_isPaused || !_isStarted || _isAnimating) return;
    if (_isSmall) {
      final remaining = _nearFarChars.where((c) => c != _nearFarChar).toList();
      setState(() {
        _nearFarChar = remaining[_random.nextInt(remaining.length)];
      });
    }
    HapticFeedback.lightImpact();
    _tapCount++;
    _runNearFarAnimation(_isSmall ? 1.0 : 0.0);
  }

  void _showDistanceAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DistanceAlertDialog(
        onConfirm: (neverShow) async {
          if (neverShow) {
            await HiveService.instance.saveSetting(
              HiveService.keyDistanceAlertDisabled, true);
          }
          _startTraining();
        },
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onComplete();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _trainingController.stop();
    } else if (_type == TrainingType.nearFar) {
      if (_isAnimating) {
        // 一時停止中断されたアニメーションを再開
        _runNearFarAnimation(_isSmall ? 1.0 : 0.0);
      }
      // _isAnimating が false = タップ待ち状態のまま → 何もしない
    } else {
      _trainingController.repeat(reverse: true);
    }
  }

  Future<void> _onComplete() async {
    final session = TrainingSession(
      date: DateTime.now(),
      type: _type,
      durationSeconds: _totalSeconds,
      completed: true,
    );
    await HiveService.instance.saveSession(session);
    await DailyLimitService.instance.addSeconds(_totalSeconds);

    if (!mounted) return;
    final streakDays = HiveService.instance.getStreakDays();
    context.pushReplacement('/training/complete', extra: {
      'typeName': _type.displayName,
      'streakDays': streakDays,
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _trainingController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _instructionText {
    switch (_type) {
      case TrainingType.nearFar:
        return 'ピントが合ったらタップ';
      case TrainingType.tracking:
        return '目で追ってください';
      case TrainingType.blurClarity:
        return '文字が見えるまで待ってください';
      case TrainingType.convergence:
        return '両目を内側・外側に動かしてください';
      case TrainingType.saccade:
        return '視点を素早く移してください';
      case TrainingType.contrastAdapt:
        return '薄い文字を読んでください';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightBackground = _type == TrainingType.contrastAdapt;
    return Scaffold(
      backgroundColor: isLightBackground ? const Color(0xFFF0F0F0) : Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            if (_isStarted) ...[
              Expanded(child: _buildTrainingArea()),
              _buildBottomBar(context),
            ] else
              Expanded(child: _buildStartScreen(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isLightBackground = _type == TrainingType.contrastAdapt;
    final textColor = isLightBackground ? Colors.black54 : Colors.white54;
    final timeColor = isLightBackground ? Colors.black87 : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: textColor, size: 28),
            onPressed: () => _isStarted ? _showQuitDialog(context) : context.pop(),
          ),
          const Spacer(),
          Text(_type.displayName, style: TextStyle(color: textColor, fontSize: 16)),
          const Spacer(),
          if (_isStarted)
            Text(_timeString, style: TextStyle(color: timeColor, fontSize: 22, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]))
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    final isLightBackground = _type == TrainingType.contrastAdapt;
    final textColor = isLightBackground ? Colors.black87 : Colors.white;
    final subtitleColor = isLightBackground ? Colors.black54 : Colors.white70;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_type.icon, size: 72, color: textColor),
            const SizedBox(height: 20),
            Text(
              _type.displayName,
              style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _type.description,
              style: TextStyle(color: subtitleColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: _onStartPressed,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('トレーニングを始める', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingArea() {
    switch (_type) {
      case TrainingType.nearFar:
        return _NearFarTraining(
          controller: _trainingController,
          character: _nearFarChar,
          onTap: _onNearFarTap,
          isSmall: _isSmall,
          isAnimating: _isAnimating,
        );
      case TrainingType.tracking:
        return _TrackingTraining(controller: _trainingController);
      case TrainingType.blurClarity:
        return _BlurClarityTraining(controller: _trainingController, phrase: _blurPhrase);
      case TrainingType.convergence:
        return _ConvergenceTraining(controller: _trainingController);
      case TrainingType.saccade:
        return _SaccadeTraining(controller: _trainingController);
      case TrainingType.contrastAdapt:
        return _ContrastAdaptTraining(controller: _trainingController, phrase: _contrastPhrase);
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    final progress = 1.0 - (_remainingSeconds / _totalSeconds);
    final isLightBackground = _type == TrainingType.contrastAdapt;
    final textColor = isLightBackground ? Colors.black45 : Colors.white54;
    final iconColor = isLightBackground ? Colors.black87 : Colors.white;
    final bgColor = isLightBackground ? Colors.black12 : Colors.white12;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isLightBackground ? Colors.black12 : Colors.white12,
            color: AppTheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _togglePause,
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: iconColor,
                  size: 40,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: bgColor,
                  minimumSize: const Size(64, 64),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isPaused ? '一時停止中' : _instructionText,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('トレーニングを中断しますか？'),
        content: const Text('経過時間は今日の残り時間に反映されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('続ける')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final elapsed = _totalSeconds - _remainingSeconds;
              if (elapsed > 0) {
                await DailyLimitService.instance.addSeconds(elapsed);
              }
              if (!mounted) return;
              context.go('/home');
            },
            child: const Text('中断する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ① 遠近ピント切替トレーニング
class _NearFarTraining extends StatelessWidget {
  final AnimationController controller;
  final String character;
  final VoidCallback onTap;
  final bool isSmall;
  final bool isAnimating;

  const _NearFarTraining({
    required this.controller,
    required this.character,
    required this.onTap,
    required this.isSmall,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    final sizeAnim = Tween<double>(begin: 14, end: 100).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final opacityAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final colorAnim = ColorTween(
      begin: const Color(0xFFAADDFF), // 遠くは青白く（大気遠近法）
      end: Colors.white,              // 近くは純白
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '記号にピントを合わせて',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Opacity(
                  opacity: opacityAnim.value,
                  child: Text(
                    character,
                    style: TextStyle(
                      color: colorAnim.value,
                      fontSize: sizeAnim.value,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // 小→大（isSmall=true）: controller 0→1、75%以上で表示
                // 大→小（isSmall=false）: controller 1→0、25%以下で表示
                final nearCompletion = isSmall
                    ? controller.value >= 0.75
                    : controller.value <= 0.25;
                final show = !isAnimating || nearCompletion;
                return AnimatedOpacity(
                  opacity: show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Text(
                    'タップしてください',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ② 追従運動トレーニング
class _TrackingTraining extends StatefulWidget {
  final AnimationController controller;
  const _TrackingTraining({required this.controller});

  @override
  State<_TrackingTraining> createState() => _TrackingTrainingState();
}

class _TrackingTrainingState extends State<_TrackingTraining> {
  Offset _currentTarget = const Offset(0.5, 0.5);
  Offset _nextTarget = const Offset(0.5, 0.5);
  final _random = Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addStatusListener(_onAnimationStatus);
    _pickNextTarget();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
      setState(() {
        _currentTarget = _nextTarget;
        _pickNextTarget();
      });
    }
  }

  void _pickNextTarget() {
    _nextTarget = Offset(
      0.1 + _random.nextDouble() * 0.8,
      0.1 + _random.nextDouble() * 0.8,
    );
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_onAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final pos = Offset.lerp(_currentTarget, _nextTarget, widget.controller.value)!;
            final x = pos.dx * constraints.maxWidth;
            final y = pos.dy * constraints.maxHeight;

            return CustomPaint(
              painter: _TrackingPainter(position: Offset(x, y)),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}

class _TrackingPainter extends CustomPainter {
  final Offset position;
  _TrackingPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(position, 32, glowPaint);
    canvas.drawCircle(position, 22, paint);
    canvas.drawCircle(position, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TrackingPainter old) => old.position != position;
}

// ③ ぼかし→くっきり刺激トレーニング
class _BlurClarityTraining extends StatelessWidget {
  final AnimationController controller;
  final String phrase;
  const _BlurClarityTraining({required this.controller, required this.phrase});

  @override
  Widget build(BuildContext context) {
    final blurAnim = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('文字にピントを合わせてください', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurAnim.value,
                  sigmaY: blurAnim.value,
                ),
                child: Text(
                  phrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final isClear = controller.value > 0.7;
              return Text(
                isClear ? 'くっきり見えていますか？' : 'ぼやけています...',
                style: TextStyle(
                  color: isClear ? AppTheme.primaryLight : Colors.white38,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ④ 輻輳運動トレーニング
// 2つの光点が左右から中央へ近づき（輻輳）、また離れる（開散）
// エビデンス: Scheiman et al. (2005) - 輻輳訓練の有効性
class _ConvergenceTraining extends StatelessWidget {
  final AnimationController controller;
  const _ConvergenceTraining({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // controller.value: 0→1（reverse:true で往復）
            // 0.0 = 最大開散（左右端）、1.0 = 最大輻輳（中央）
            final t = controller.value;
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;
            final maxOffset = constraints.maxWidth * 0.35;
            final currentOffset = maxOffset * (1.0 - t);

            final leftPos = Offset(centerX - currentOffset, centerY);
            final rightPos = Offset(centerX + currentOffset, centerY);

            final isConverging = t > 0.5;
            final label = isConverging ? '目を内側に寄せて' : '目を外側に広げて';

            return Stack(
              children: [
                CustomPaint(
                  painter: _ConvergencePainter(left: leftPos, right: rightPos),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isConverging
                          ? AppTheme.primaryLight
                          : Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ConvergencePainter extends CustomPainter {
  final Offset left;
  final Offset right;
  _ConvergencePainter({required this.left, required this.right});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final dotPaint = Paint()..color = AppTheme.primary;
    final centerPaint = Paint()..color = Colors.white;

    for (final pos in [left, right]) {
      canvas.drawCircle(pos, 28, glowPaint);
      canvas.drawCircle(pos, 18, dotPaint);
      canvas.drawCircle(pos, 6, centerPaint);
    }
  }

  @override
  bool shouldRepaint(_ConvergencePainter old) =>
      old.left != left || old.right != right;
}

// ⑤ 視点移動（サッカード）トレーニング
// 対角のターゲットへ素早く視点を移動させる
// エビデンス: Ciuffreda & Tannen (1995) - サッカード訓練で読書速度向上
class _SaccadeTraining extends StatelessWidget {
  final AnimationController controller;
  const _SaccadeTraining({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final isPhaseA = controller.value < 0.5;
            // フェーズA: 左上・右下 ／ フェーズB: 右上・左下
            final margin = 60.0;
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final pos1 = isPhaseA
                ? Offset(margin, margin)
                : Offset(w - margin, margin);
            final pos2 = isPhaseA
                ? Offset(w - margin, h - margin)
                : Offset(margin, h - margin);

            // アクティブターゲットをパルスさせる（sin波で拡大縮小）
            final pulse = 1.0 + 0.15 * sin(controller.value * 2 * pi * 4);

            return CustomPaint(
              painter: _SaccadePainter(pos1: pos1, pos2: pos2, pulse: pulse),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}

class _SaccadePainter extends CustomPainter {
  final Offset pos1;
  final Offset pos2;
  final double pulse;
  _SaccadePainter({required this.pos1, required this.pos2, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // 2つのターゲットを結ぶ線（視線方向を示す）
    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(pos1, pos2, linePaint);

    final glowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final dotPaint = Paint()..color = AppTheme.primary;
    final centerPaint = Paint()..color = Colors.white;

    for (final pos in [pos1, pos2]) {
      canvas.drawCircle(pos, 30 * pulse, glowPaint);
      canvas.drawCircle(pos, 20 * pulse, dotPaint);
      canvas.drawCircle(pos, 7, centerPaint);
    }
  }

  @override
  bool shouldRepaint(_SaccadePainter old) =>
      old.pos1 != pos1 || old.pos2 != pos2 || old.pulse != pulse;
}

// ⑥ コントラスト順応トレーニング
// 薄いテキストが徐々に濃くなる。背景は白系。
// エビデンス: Polat et al. (2012, PLOS ONE) - コントラスト感度訓練で老眼改善
class _ContrastAdaptTraining extends StatelessWidget {
  final AnimationController controller;
  final String phrase;
  const _ContrastAdaptTraining({required this.controller, required this.phrase});

  @override
  Widget build(BuildContext context) {
    final opacityAnim = Tween<double>(begin: 0.06, end: 0.95).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '薄い文字を読んでください',
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Opacity(
                opacity: opacityAnim.value,
                child: Text(
                  phrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final isVisible = controller.value > 0.6;
              return Text(
                isVisible ? '読めましたか？' : '文字を探してください',
                style: TextStyle(
                  color: isVisible ? AppTheme.primary : Colors.black38,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 距離アラートダイアログ
class _DistanceAlertDialog extends StatefulWidget {
  final Future<void> Function(bool neverShow) onConfirm;
  const _DistanceAlertDialog({required this.onConfirm});

  @override
  State<_DistanceAlertDialog> createState() => _DistanceAlertDialogState();
}

class _DistanceAlertDialogState extends State<_DistanceAlertDialog> {
  bool _neverShow = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📏 スマホを正しい位置で持とう'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tip('👁', '目との距離：30〜40cm'),
          _tip('💡', '明るい場所で行いましょう'),
          _tip('📐', '画面を正面に向けて持つ'),
          const SizedBox(height: 16),
          const Divider(),
          CheckboxListTile(
            value: _neverShow,
            onChanged: (v) => setState(() => _neverShow = v ?? false),
            title: const Text('今後は表示しない', style: TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await widget.onConfirm(_neverShow);
          },
          child: const Text('OK・始める'),
        ),
      ],
    );
  }

  Widget _tip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
