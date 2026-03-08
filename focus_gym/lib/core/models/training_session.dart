import 'package:hive/hive.dart';

part 'training_session.g.dart';

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
        return 'ぼかし→くっきり';
      case TrainingType.convergence:
        return '輻輳運動';
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
        return 'ぼやけた文字に\nピントを合わせる練習';
      case TrainingType.convergence:
        return '両目を内側・外側に動かして\n遠近調節の連動を鍛える';
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
