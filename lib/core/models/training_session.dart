import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'training_session.g.dart';

/// ぼけ文字識別トレーニングで使用する記号グループ
/// キー: グループ名（デバッグ表示用）、値: 記号リスト
/// 全てU+25A0-U+25FF Geometric Shapes ブロック — iOSで絵文字化しない
const kBlurSymbolGroups = <String, List<String>>{
  '丸系':        ['●', '○', '◉', '◎', '◐', '◑', '◒', '◓', '◔', '◕'],
  '四角系':      ['■', '□', '▢', '▤', '▥', '▦', '▧', '▨', '▩', '◧', '◨'],
  '三角系':      ['▲', '▼', '△', '▽', '◤', '◥', '◢', '◣'],
  '方向系':      ['▸', '◂', '▷', '◁'],
  'ひし形・円系': ['◆', '◇', '◈', '◊', '◌', '◍'],
  '半分塗り系':   ['◩', '◪', '◫', '◬', '◭', '◮'],
  '縦横系':      ['▬', '▭', '▰', '▱'],
};

@HiveType(typeId: 0)
enum TrainingType {
  @HiveField(0)
  nearFar,

  @HiveField(1)
  tracking,

  @HiveField(2)
  blurClarity,

  @HiveField(3)
  convergence,

  @HiveField(4)
  saccade,

  @HiveField(5)
  contrastAdapt,
}

extension TrainingTypeExtension on TrainingType {
  String get displayName {
    switch (this) {
      case TrainingType.nearFar:
        return '遠近ピント切替';
      case TrainingType.tracking:
        return '追従運動';
      case TrainingType.blurClarity:
        return 'ぼけ文字識別';
      case TrainingType.convergence:
        return '寄り目トレーニング';
      case TrainingType.saccade:
        return '視点移動トレーニング';
      case TrainingType.contrastAdapt:
        return 'コントラスト順応';
    }
  }

  String get description {
    switch (this) {
      case TrainingType.nearFar:
        return '近くと遠くを交互に見て\nピント調節力を鍛える';
      case TrainingType.tracking:
        return '動くボールを目で追って\n眼の筋肉を動かす';
      case TrainingType.blurClarity:
        return '一瞬のぼけ記号を識別して\n視覚処理を鍛える';
      case TrainingType.convergence:
        return '画面を顔に近づけて\n輻輳筋を直接トレーニング';
      case TrainingType.saccade:
        return '画面の端から端へ視点を素早く\n動かして眼の反応速度を鍛える';
      case TrainingType.contrastAdapt:
        return '薄いグレーの文字に焦点を合わせて\nコントラスト感度を鍛える';
    }
  }

  String get emoji {
    switch (this) {
      case TrainingType.nearFar:
        return '🔭';
      case TrainingType.tracking:
        return '👁️';
      case TrainingType.blurClarity:
        return '🔍';
      case TrainingType.convergence:
        return '👀';
      case TrainingType.saccade:
        return '⚡';
      case TrainingType.contrastAdapt:
        return '🌗';
    }
  }

  IconData get icon {
    switch (this) {
      case TrainingType.nearFar:
        return Icons.zoom_in_map_rounded;
      case TrainingType.tracking:
        return Icons.remove_red_eye_rounded;
      case TrainingType.blurClarity:
        return Icons.blur_on_rounded;
      case TrainingType.convergence:
        return Icons.compare_arrows_rounded;
      case TrainingType.saccade:
        return Icons.speed_rounded;
      case TrainingType.contrastAdapt:
        return Icons.contrast_rounded;
    }
  }
}

@HiveType(typeId: 1)
class TrainingSession extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late TrainingType type;

  @HiveField(2)
  late int durationSeconds;

  @HiveField(3)
  late bool completed;

  TrainingSession({
    required this.date,
    required this.type,
    required this.durationSeconds,
    required this.completed,
  });
}
