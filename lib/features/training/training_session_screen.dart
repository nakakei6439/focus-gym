import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  late String _contrastPhrase;

  final _random = Random();
  int _remainingSeconds = _totalSeconds;
  int _tapCount = 0;
  bool _isPaused = false;
  bool _isStarted = false;
  bool _isSmall = true;
  bool _isAnimating = false;
  bool _isCompleting = false;
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
    } else if (_type == TrainingType.blurClarity) {
      // Widget 内の initState で自己起動（コントローラー不使用）
    } else if (_type == TrainingType.convergence) {
      // Widget 内のカメラで自己制御（コントローラー不使用）
    } else if (_type == TrainingType.tracking) {
      _trainingController.forward(); // 追従運動: 一方向のみ（折り返しなし）
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
    } else if (_type == TrainingType.blurClarity) {
      // isPaused プロパティ経由で Widget 内制御
    } else if (_type == TrainingType.convergence) {
      // isPaused プロパティ経由で Widget 内制御
    } else if (_type == TrainingType.tracking) {
      _trainingController.forward(); // 追従運動: 現在位置から再開
    } else {
      _trainingController.repeat(reverse: true);
    }
  }

  Future<void> _onComplete() async {
    if (_isCompleting) return;
    _isCompleting = true;
    final session = TrainingSession(
      date: DateTime.now(),
      type: _type,
      durationSeconds: _totalSeconds,
      completed: true,
    );
    await HiveService.instance.saveSession(session);
    await DailyLimitService.instance.addSeconds(_totalSeconds);

    if (!mounted) return;
    context.go('/training');
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
        return '見えた記号を選んでください';
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
        return _TrackingTraining(controller: _trainingController, speed: TrackingSpeed.medium);
      case TrainingType.blurClarity:
        return _BlurIdentificationTraining(isPaused: _isPaused);
      case TrainingType.convergence:
        return _ConvergencePhoneMotionTraining(isPaused: _isPaused, onComplete: _onComplete);
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
enum TrackingSpeed {
  low(Duration(milliseconds: 4000)),
  medium(Duration(milliseconds: 2500)),
  high(Duration(milliseconds: 1500));

  const TrackingSpeed(this.duration);
  final Duration duration;

  String get label => switch (this) {
        TrackingSpeed.low => '低速',
        TrackingSpeed.medium => '中速',
        TrackingSpeed.high => '高速',
      };
}

class _TrackingTraining extends StatefulWidget {
  final AnimationController controller;
  final TrackingSpeed speed;
  const _TrackingTraining({
    required this.controller,
    this.speed = TrackingSpeed.medium,
  });

  @override
  State<_TrackingTraining> createState() => _TrackingTrainingState();
}

class _TrackingTrainingState extends State<_TrackingTraining> {
  Offset _currentTarget = const Offset(0.5, 0.5);
  Offset _nextTarget = const Offset(0.5, 0.5);
  int _currentZone = 4; // 3×3グリッドの中央ゾーン（0〜8）
  int _targetCount = 0; // 適応速度用カウンタ
  final _random = Random();

  // 修正3: 適応速度 — セッション開始は 3500ms、徐々に 1500ms まで加速
  Duration get _currentDuration {
    const startMs = 3500.0;
    const endMs = 1500.0;
    const decay = 0.92;
    final ms = endMs + (startMs - endMs) * pow(decay, _targetCount);
    return Duration(milliseconds: ms.round().clamp(endMs.toInt(), startMs.toInt()));
  }

  // 修正2: 座標からゾーン番号（0〜8）を計算
  int _zoneOf(Offset pos) {
    final col = (pos.dx * 3).clamp(0.0, 2.9999).toInt();
    final row = (pos.dy * 3).clamp(0.0, 2.9999).toInt();
    return row * 3 + col;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.duration = _currentDuration;
    widget.controller.addStatusListener(_onAnimationStatus);
    _pickNextTarget();
  }

  // 修正1: completed のみ処理し、forward(from:0) で次ターゲットへ一方向移動
  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentTarget = _nextTarget;
        _currentZone = _zoneOf(_currentTarget);
        _targetCount++;
        _pickNextTarget();
      });
      widget.controller.duration = _currentDuration;
      widget.controller.forward(from: 0.0);
    }
  }

  // 修正2: 3×3ゾーン分割で画面全体を均等カバー（現在ゾーンを除いて選択）
  void _pickNextTarget() {
    const padding = 0.06;
    const zoneSize = (1.0 - padding * 2) / 3;

    final candidateZones = List.generate(9, (i) => i)
        .where((z) => z != _currentZone)
        .toList()
      ..shuffle(_random);

    final targetZone = candidateZones.first;
    final col = targetZone % 3;
    final row = targetZone ~/ 3;

    _nextTarget = Offset(
      padding + col * zoneSize + _random.nextDouble() * zoneSize,
      padding + row * zoneSize + _random.nextDouble() * zoneSize,
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

// ③ ぼけ文字識別トレーニング
// ぼけた記号を一瞬見て何かを当てる → 脳の視覚処理（知覚学習）を鍛える
// エビデンス: Polat et al. (2012, Scientific Reports) - 劣化視覚刺激による神経可塑性
enum _IdentPhase { showing, choosing, feedback }

class _BlurIdentificationTraining extends StatefulWidget {
  final bool isPaused;
  const _BlurIdentificationTraining({required this.isPaused});

  @override
  State<_BlurIdentificationTraining> createState() =>
      _BlurIdentificationTrainingState();
}

class _BlurIdentificationTrainingState
    extends State<_BlurIdentificationTraining> {
  // 記号グループは training_session.dart の kBlurSymbolGroups を参照
  static List<List<String>> get _symbolGroups =>
      kBlurSymbolGroups.values.toList();

  static List<String> get _symbols =>
      _symbolGroups.expand((g) => g).toList();

  List<String> _groupOf(String symbol) =>
      _symbolGroups.firstWhere((g) => g.contains(symbol),
          orElse: () => _symbols);

  _IdentPhase _phase = _IdentPhase.showing;
  String _target = '';
  String _lastTarget = ''; // 連続同一記号の防止
  List<String> _choices = []; // 毎ラウンドの3択
  bool? _isCorrect;
  int _correctCount = 0;
  Timer? _phaseTimer;
  final _random = Random();

  // 適応難易度: 表示時間 400ms → 120ms（閾値訓練レンジ、Polat 2012 と整合）
  Duration get _showDuration {
    const startMs = 400.0, endMs = 120.0;
    final ms = endMs + (startMs - endMs) * pow(0.88, _correctCount);
    return Duration(milliseconds: ms.round().clamp(120, 400));
  }

  // 適応難易度: ブラーσ 10.0 → 3.0（正解するたびに見やすくなるが表示時間で難易度維持）
  double get _blurSigma {
    const start = 10.0, end = 3.0;
    return end + (start - end) * pow(0.95, _correctCount);
  }

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    // 直前と同じ記号を除外してターゲット選択
    final allSymbols = _symbols;
    final candidates = allSymbols.where((s) => s != _lastTarget).toList();
    _lastTarget = _target;
    _target = candidates[_random.nextInt(candidates.length)];

    // 同一グループから選択肢を生成（視覚的に似た記号で難易度を上げる）
    final group = _groupOf(_target);
    final sameGroup = group.where((s) => s != _target && s != _lastTarget).toList()
      ..shuffle(_random);
    final distractors = sameGroup.length >= 2
        ? sameGroup.take(2).toList()
        : (allSymbols.where((s) => s != _target).toList()..shuffle(_random))
            .take(2)
            .toList();
    final choices = [_target, ...distractors]..shuffle(_random);

    setState(() {
      _choices = choices;
      _phase = _IdentPhase.showing;
      _isCorrect = null;
    });
    _phaseTimer = Timer(_showDuration, () {
      if (!mounted) return;
      setState(() => _phase = _IdentPhase.choosing);
    });
  }

  void _onChoiceTap(String choice) {
    if (_phase != _IdentPhase.choosing) return;
    final correct = choice == _target;
    setState(() {
      _isCorrect = correct;
      _phase = _IdentPhase.feedback;
      if (correct) _correctCount++;
    });
    HapticFeedback.lightImpact();
    _phaseTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _startRound();
    });
  }

  @override
  void didUpdateWidget(_BlurIdentificationTraining old) {
    super.didUpdateWidget(old);
    if (old.isPaused == widget.isPaused) return;
    if (widget.isPaused) {
      _phaseTimer?.cancel();
    } else {
      // 再開: showing フェーズなら新ラウンドをスタート
      if (_phase == _IdentPhase.showing) _startRound();
      // choosing / feedback はそのまま表示継続
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInstruction(),
            const SizedBox(height: 48),
            _buildMainArea(),
            const SizedBox(height: 48),
            if (_phase == _IdentPhase.choosing) _buildChoices(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    final text = switch (_phase) {
      _IdentPhase.showing  => 'この記号を覚えてください',
      _IdentPhase.choosing => '見えた記号はどれ？',
      _IdentPhase.feedback => _isCorrect! ? '正解！' : '残念... $_target でした',
    };
    final color = switch (_phase) {
      _IdentPhase.feedback when !(_isCorrect!) => Colors.redAccent,
      _IdentPhase.feedback                     => AppTheme.primaryLight,
      _                                        => Colors.white54,
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        text,
        key: ValueKey(_phase),
        style: TextStyle(color: color, fontSize: 16),
      ),
    );
  }

  Widget _buildMainArea() {
    if (_phase == _IdentPhase.showing) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Text(
          _target,
          style: const TextStyle(
              color: Colors.white, fontSize: 96, fontWeight: FontWeight.w300),
        ),
      );
    }
    if (_phase == _IdentPhase.feedback) {
      return Text(
        _target,
        style: TextStyle(
          color: _isCorrect! ? AppTheme.primaryLight : Colors.redAccent,
          fontSize: 96,
          fontWeight: FontWeight.w300,
        ),
      );
    }
    // choosing フェーズ: 記号は非表示
    return const SizedBox(height: 96);
  }

  Widget _buildChoices() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _choices.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => _onChoiceTap(s),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                s,
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ④ 寄り目トレーニング（輻輳運動）
// フロントカメラで顔との距離を計測し、画面を近づける動作で実際の輻輳を発生させる
// エビデンス: CITT-ART (2019, JAMA Ophthalmology) - 成人の輻輳不全への訓練効果
enum _ConvergencePhase { prepare, approaching, relaxing }

class _ConvergencePhoneMotionTraining extends StatefulWidget {
  final bool isPaused;
  final VoidCallback onComplete;
  const _ConvergencePhoneMotionTraining({required this.isPaused, required this.onComplete});

  @override
  State<_ConvergencePhoneMotionTraining> createState() =>
      _ConvergencePhoneMotionTrainingState();
}

class _ConvergencePhoneMotionTrainingState
    extends State<_ConvergencePhoneMotionTraining> {
  // 顔ボックス高さ / 画面高さ の比率キャリブレーション値
  // 実機 debugMode で計測して調整する
  static const _farRatio = 0.287; // ~40cm（実機キャリブレーション値）
  static const _nearRatio = 0.700; // ユーザー最大到達距離
  static const _holdThreshold = 0.88; // ratio 0.65 付近で判定

  static const _totalSets = 5;

  CameraController? _camera;
  FaceDetector? _faceDetector;
  bool _cameraReady = false;
  bool _processing = false;

  double _distanceT = 0.0; // 0.0 = 遠, 1.0 = 近
  _ConvergencePhase _phase = _ConvergencePhase.prepare;
  Timer? _phaseTimer;
  Timer? _relaxCountdownTimer;
  int _setCount = 0;
  int _relaxSeconds = 4;

  bool _debugMode = false;
  double _debugT = 0.0;
  double _debugFaceRatio = 0.0;

  @override
  void initState() {
    super.initState();
    _debugMode = HiveService.instance
        .getSetting('debug_mode_enabled', defaultValue: false) as bool;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      _camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
      _camera!.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
    }
  }

  void _processFrame(CameraImage image) async {
    if (_processing || widget.isPaused) return;
    _processing = true;
    try {
      final bytes = image.planes[0].bytes;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector!.processImage(inputImage);
      if (!mounted) return;
      if (faces.isNotEmpty) {
        final ratio = faces.first.boundingBox.height / image.height;
        debugPrint('顔ボックス比率: ${ratio.toStringAsFixed(3)}');
        final t = ((ratio - _farRatio) / (_nearRatio - _farRatio))
            .clamp(0.0, 1.0)
            .toDouble();
        if (mounted) {
          setState(() {
            _distanceT = t;
            _debugFaceRatio = ratio;
          });
          if (_phase == _ConvergencePhase.prepare && t < 0.20) {
            _onFaceAtStart();
          } else if (_phase == _ConvergencePhase.approaching && t >= _holdThreshold) {
            _onFaceNear();
          }
        }
      } else if (_phase == _ConvergencePhase.approaching && _distanceT >= 0.5) {
        // 顔が検出できないほど近い = 最接近とみなす
        if (mounted) _onFaceNear();
      }
    } finally {
      _processing = false;
    }
  }

  void _onFaceAtStart() {
    if (_phase != _ConvergencePhase.prepare) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = _ConvergencePhase.approaching);
  }

  void _onFaceNear() {
    if (_phase != _ConvergencePhase.approaching) return;
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      HapticFeedback.heavyImpact();
      if (timer.tick >= 3) timer.cancel(); // 3 × 150ms = 450ms
    });
    setState(() {
      _phase = _ConvergencePhase.relaxing;
      _relaxSeconds = 4;
    });
    _relaxCountdownTimer?.cancel();
    _relaxCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _relaxSeconds--);
      if (_relaxSeconds <= 0) timer.cancel();
    });
    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
      final newCount = _setCount + 1;
      setState(() {
        _setCount = newCount;
        _phase = _ConvergencePhase.prepare;
      });
      if (newCount >= _totalSets) {
        widget.onComplete();
      }
    });
  }

  @override
  void didUpdateWidget(_ConvergencePhoneMotionTraining old) {
    super.didUpdateWidget(old);
    if (old.isPaused == widget.isPaused) return;
    if (widget.isPaused) {
      _phaseTimer?.cancel();
      try { _camera?.stopImageStream(); } catch (_) {}
    } else {
      try { _camera?.startImageStream(_processFrame); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _relaxCountdownTimer?.cancel();
    try { _camera?.stopImageStream(); } catch (_) {}
    _camera?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _debugMode ? _debugT : _distanceT;

    Widget centerContent;
    if (_phase == _ConvergencePhase.prepare) {
      centerContent = Column(
        key: const ValueKey('prepare'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_setCount / $_totalSets セット',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 48),
          const Text(
            '腕を伸ばして\nカメラを顔に向けてください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.6),
          ),
        ],
      );
    } else if (_phase == _ConvergencePhase.approaching) {
      centerContent = Column(
        key: const ValueKey('approaching'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_setCount / $_totalSets セット',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(painter: _ConvergenceDotPainter(t: t)),
          ),
          const SizedBox(height: 48),
          const Text(
            '画面をゆっくり顔に近づけて\nターゲットを見ながら目を寄り目にしてください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
          ),
        ],
      );
    } else {
      // relaxing
      centerContent = Column(
        key: const ValueKey('relaxing'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_setCount / $_totalSets セット',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 48),
          Text(
            '$_relaxSeconds',
            style: const TextStyle(color: Colors.green, fontSize: 72, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 16),
          const Text(
            'リラックスしてください',
            style: TextStyle(color: Colors.green, fontSize: 18),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: centerContent,
          ),
        ),
        if (_debugMode)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'カメラ: ${_cameraReady ? "準備完了" : "初期化中"}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Text(
                    '顔ボックス比率: ${_debugFaceRatio.toStringAsFixed(3)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Text(
                    '距離t: ${t.toStringAsFixed(2)}  フェーズ: $_phase',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Slider(
                    value: _debugT,
                    onChanged: (v) => setState(() {
                      _debugT = v;
                      if (_phase == _ConvergencePhase.prepare && v < 0.20) {
                        _onFaceAtStart();
                      } else if (_phase == _ConvergencePhase.approaching && v >= _holdThreshold) {
                        _onFaceNear();
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// 近づくほど小さくなる同心円ターゲット（遠=大きい、近=小さい）
// 色変化なし: 黒外円 → 白中円 → 黒中心点 の固定デザイン
class _ConvergenceDotPainter extends CustomPainter {
  final double t; // 0.0 = 遠(大), 1.0 = 近(小)
  _ConvergenceDotPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const outerR = 80.0; // 黒外円：固定
    const whiteR = outerR * 0.85; // 白円：固定
    final innerR = (outerR * (0.45 - 0.35 * t)).clamp(outerR * 0.08, outerR * 0.45); // 黒中心点：縮む

    canvas.drawCircle(center, outerR, Paint()..color = Colors.black);
    canvas.drawCircle(center, whiteR, Paint()..color = Colors.white);
    canvas.drawCircle(center, innerR, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(_ConvergenceDotPainter old) => old.t != t;
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

