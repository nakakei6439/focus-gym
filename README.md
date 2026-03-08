# FocusGym — 目のトレーニングアプリ

毎日ちょっとずつ、目をケアする習慣を。

---

## 概要

**FocusGym** は、目の筋肉の柔軟性をサポートするトレーニングアプリです。
スマホやPCの使いすぎで疲れた目に、1日15分までの科学的根拠に基づいたエクササイズを提供します。

> **注意：** 本アプリは医療行為ではありません。視力の改善・老眼の治癒を保証するものではありません。眼の異常を感じた場合は医療機関を受診してください。

---

## 機能

### 無料トレーニング

| トレーニング | 効果の目安 |
| --- | --- |
| 遠近ピント切替 | 毛様体筋の調節力をサポート |

### 有料トレーニング（300円・一括アンロック）

| トレーニング | 効果の目安 |
| --- | --- |
| 追従運動 | 眼球運動の滑らかさをサポート |
| ぼかし→くっきり | ピント合わせの応答をサポート |
| 輻輳運動 | 両目の輻輳機能をサポート |
| 視点移動（サッカード） | 視点移動の精度をサポート |
| コントラスト順応 | コントラスト感度をサポート |
| ガルボーパッチ | 視覚の脳処理をサポート（最もエビデンスが強い） |

### 習慣化機能

- 連続達成日数（ストリーク）表示
- 月間カレンダー
- 毎日リマインダー通知
- 1日15分の適切な上限管理

---

## スクリーンショット

※ 準備中

---

## 動作環境

| 項目 | 要件 |
| --- | --- |
| iOS | 14.0 以上 |
| Android | 6.0（API 23）以上 |
| フレームワーク | Flutter 3.x / Dart 3.x |

---

## 開発環境のセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/nakakei6439/focus-gym.git
cd focus-gym/focus_gym

# 依存パッケージを取得
flutter pub get

# Hive TypeAdapter を再生成（モデル変更時）
flutter pub run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze

# iOSシミュレーターで起動
flutter run -d D7C51E20-2575-4BA0-9D42-9900DBF47116

# 実機iOSで起動
flutter run -d 00008150-000854443E03401C
```

---

## プロジェクト構成

```text
Focus Gym/
├── CLAUDE.md           Claude Code 用の指示ファイル
├── COMMANDS.md         スラッシュコマンド一覧
├── requirements.md     機能要件・技術スタック・エビデンス
├── business_plan.md    事業計画
├── decisions.md        意思決定ログ
├── docs/               GitHub Pages（サポートページ・プライバシーポリシー）
└── focus_gym/          Flutter プロジェクト
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── app/app.dart
        ├── core/
        │   ├── database/hive_service.dart
        │   ├── models/training_session.dart
        │   ├── notification/notification_service.dart
        │   ├── services/purchase_service.dart
        │   └── services/daily_limit_service.dart
        ├── features/
        │   ├── home/home_screen.dart
        │   ├── training/
        │   │   ├── training_list_screen.dart
        │   │   ├── training_session_screen.dart
        │   │   ├── training_complete_screen.dart
        │   │   └── gabor_patch_screen.dart
        │   ├── history/history_screen.dart
        │   └── settings/settings_screen.dart
        └── shared/theme/app_theme.dart
```

---

## ドキュメント

- [サポートページ](https://nakakei6439.github.io/focus-gym/)
- [プライバシーポリシー](https://nakakei6439.github.io/focus-gym/privacy.html)
- [トレーニングのエビデンス](https://nakakei6439.github.io/focus-gym/evidence.html)

---

## ライセンス

MIT License

---

## 開発者

nakakei6439
