import 'package:flutter/material.dart';
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

  @HiveField(6)
  gaborPatch,
}

extension TrainingTypeExtension on TrainingType {
  /// 無料で常に使えるか（nearFar のみ無料）
  bool get isFree => this == TrainingType.nearFar;

  /// v1 リリースで使用可能か（nearFar のみ）
  bool get isReleasedV1 => true;

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
      case TrainingType.gaborPatch:
        return 'ガルボーパッチ';
    }
  }

  String get description {
    switch (this) {
      case TrainingType.nearFar:
        return '近くと遠くを交互に見て\nピント調節をサポートする練習';
      case TrainingType.tracking:
        return '動くボールを目で追って\n眼球運動の滑らかさをサポート';
      case TrainingType.blurClarity:
        return 'ぼやけた文字にピントを合わせて\n毛様体筋の応答をサポート';
      case TrainingType.convergence:
        return '両目を内側・外側に動かして\n輻輳機能をサポートする練習';
      case TrainingType.saccade:
        return '視点を素早く動かして\n眼球運動の精度をサポート';
      case TrainingType.contrastAdapt:
        return '薄いグレーの文字に焦点を合わせ\nコントラスト感度をサポート';
      case TrainingType.gaborPatch:
        return '縞模様を識別する練習で\n視覚の脳処理をサポート（高エビデンス）';
    }
  }

  String get evidenceDescription {
    switch (this) {
      case TrainingType.nearFar:
        return '毛様体筋の調節力（Accommodative Facility）の維持に役立つ可能性があります。\n\n参考：Ciuffreda et al., Optometry & Vision Science, 2011\n\n※医療行為ではありません。視力改善を保証するものではありません。';
      case TrainingType.tracking:
        return '滑動性追従眼球運動の練習です。眼球運動の滑らかさをサポートし、目の疲れを和らげる可能性があります。\n\n参考：Kowler, Vision Research, 2011\n\n※医療行為ではありません。';
      case TrainingType.blurClarity:
        return '視覚リハビリで用いられる調節応答訓練の手法に基づいています。毛様体筋の応答速度をサポートする可能性があります。\n\n参考：Scheiman & Wick, Clinical Management of Binocular Vision, 2014\n\n※医療行為ではありません。';
      case TrainingType.convergence:
        return '輻輳機能をサポートし、近くを見たときの疲れを和らげる可能性があります。無作為化比較試験（RCT）でも効果が確認されています。\n\n参考：CITT Study Group, Archives of Ophthalmology, 2008\n\n※医療行為ではありません。';
      case TrainingType.saccade:
        return 'サッカード訓練は眼球運動の精度をサポートし、読み疲れを和らげる可能性があります。\n\n参考：Rayner, Psychological Bulletin, 1998\n\n※医療行為ではありません。';
      case TrainingType.contrastAdapt:
        return '加齢とともに低下しやすいコントラスト感度をサポートする可能性があります。\n\n参考：Owsley et al., IOVS, 2000\n\n※医療行為ではありません。';
      case TrainingType.gaborPatch:
        return '視覚の脳処理（知覚学習）を活性化し、老眼に伴う読み取りづらさをサポートする可能性があります。無作為化比較試験で老眼患者の読書能力改善が科学誌に報告されています。\n\n参考：Polat et al., Scientific Reports, 2012\n\n※医療行為ではありません。視力改善を保証するものではありません。';
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
      case TrainingType.gaborPatch:
        return '🔬';
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
      case TrainingType.gaborPatch:
        return Icons.grid_on_rounded;
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
