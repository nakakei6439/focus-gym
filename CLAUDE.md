# CLAUDE.md - FocusGym プロジェクト

Claude Code がセッションをまたいでコンテキストを維持するためのファイルです。

---

## プロジェクト概要

| 項目 | 内容 |
|------|------|
| アプリ名 | FocusGym（老眼トレーニングアプリ） |
| コンセプト | 「1日3分、目のジム」 |
| ターゲット | 38〜55歳、PC・スマホ多用層で近くが見えにくくなってきた人 |
| 対応OS | iOS 14+ / Android 6.0（API 23）+ |
| Flutterアプリ | `focus_gym/` サブディレクトリ |
| 要件定義 | `requirements.md` |

---

## 技術スタック

| 用途 | 技術 |
|------|------|
| フロントエンド | Flutter 3.x / Dart 3.x |
| ローカルDB | Hive + hive_flutter + hive_generator |
| コード生成 | build_runner |
| 通知 | flutter_local_notifications |
| ルーティング | go_router 14.0.0 |
| カレンダーUI | table_calendar 3.1.0 |
| 状態管理 | setState / InheritedWidget（**Riverpodは使わない**） |
| アーキテクチャ | Feature-first ディレクトリ構成 |

---

## 開発経緯・実装済み機能

### Phase 1: プロジェクト立ち上げ（完了）
- `requirements.md` 作成（MVP要件定義）
- `flutter create focus_gym --org com.focusgym --platforms ios,android` でプロジェクト生成
- Feature-first ディレクトリ構成を設計・採用

### Phase 2: コア機能実装（完了）

**6種類のトレーニング**（要件書の3種 + 追加3種）

| # | トレーニング名 | 実装方法 |
|---|--------------|---------|
| 1 | 遠近ピント切替 | `AnimationController` + `Tween<double>` で文字サイズを交互アニメーション |
| 2 | 追従運動 | `CustomPainter` + `Offset.lerp()` でボールをランダム移動 |
| 3 | ぼかし→くっきり | `ImageFilter.blur` の sigma を `16.0 → 0.0` でアニメーション |
| 4 | 輻輳運動 | 2点が離れた位置から中心へ収束するアニメーション |
| 5 | 視点移動（サッカード） | 対角コーナーを交互にターゲット表示 |
| 6 | コントラスト順応 | 白背景上でグレー文字の opacity を徐々に上げる |

**サービス層**
- `HiveService` — sessions・settings の2ボックス管理、ストリーク計算、月間カレンダーデータ取得
- `NotificationService` — 毎日リマインダー（デフォルト20:00）+ 未実施時の2時間後再通知
- `AppTheme` — Primary `#1A6B4A`（ダークグリーン）、Accent `#FF6B35`（オレンジ）、高コントラスト設計

### Phase 3: 画面実装（完了）

| ファイル | 内容 |
|---------|------|
| `home_screen.dart` | ストリーク表示・「今日やる」大ボタン |
| `training_list_screen.dart` | 6種類のカード選択UI |
| `training_session_screen.dart` | 60fps アニメーション・停止/再開 |
| `training_complete_screen.dart` | 完了演出・励ましメッセージ・バッジ表示 |
| `history_screen.dart` | 月間カレンダー・累計トレーニング時間 |
| `settings_screen.dart` | 通知時刻設定 |
| `app.dart` | go_router ルーティング設定 |

### Phase 4: 追加対応（完了）
- 距離アラートダイアログ（初回のみ表示、「次回から表示しない」をHiveに保存）
- 7日連続達成バッジ
- iOS 通知パーミッション対応

---

## ディレクトリ構成

```
Focus Gym/
├── CLAUDE.md              ← このファイル
├── requirements.md
└── focus_gym/             ← Flutterプロジェクト
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── app/app.dart
        ├── core/
        │   ├── database/hive_service.dart
        │   ├── models/training_session.dart
        │   ├── models/training_session.g.dart  (自動生成)
        │   └── notification/notification_service.dart
        ├── features/
        │   ├── home/home_screen.dart
        │   ├── training/
        │   │   ├── training_list_screen.dart
        │   │   ├── training_session_screen.dart
        │   │   └── training_complete_screen.dart
        │   ├── history/history_screen.dart
        │   └── settings/settings_screen.dart
        └── shared/theme/app_theme.dart
```

---

## 主要コマンド

```bash
# Flutterプロジェクトディレクトリへ移動してから実行
cd focus_gym

# 依存取得
flutter pub get

# Hive TypeAdapter 再生成（モデル変更時）
flutter pub run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze

# iOSシミュレーター起動
xcrun simctl boot "iPhone 17 Pro" && open -a Simulator

# シミュレーターで実行
flutter run -d D7C51E20-2575-4BA0-9D42-9900DBF47116

# 実機iOSで実行
flutter run -d 00008150-000854443E03401C
```

---

## GitHubワークフロー

### ブランチ戦略

- **main**: 常にリリース可能な状態を維持
- **feature/xxx**: 機能ごとにブランチを切る（例: `feature/add-splash-screen`）

### コミット・マージの判断基準

| 変更規模 | 対応 |
|---------|------|
| バグ修正・小さな調整 | feature ブランチでコミット → PR作成 → main へマージ |
| 新機能追加 | feature ブランチを作成 → 実装完了後 PR → main へマージ |
| 破壊的変更 | feature ブランチ + 詳細 PR 説明 → ユーザー確認後マージ |

### コミットメッセージ規約

```
feat:     新機能追加
fix:      バグ修正
refactor: リファクタリング
style:    UIスタイル変更
docs:     ドキュメント更新
chore:    ビルド・設定変更
```

例: `feat: スプラッシュ画面を追加`

### PR作成フロー（Claude Codeが実行する手順）

```bash
git checkout -b feature/<機能名>
# 実装・確認
git add <関連ファイル>
git commit -m "feat: ..."
git push -u origin feature/<機能名>
gh pr create --title "..." --body "..."
# ユーザー承認後
gh pr merge --squash
```

### 重要なルール

- `git push` や PR 作成・マージは**必ずユーザー確認を取ってから**実行する
- `--force` や `--no-verify` は使わない
- main への直接 push は行わない

---

## MVP スコープ外（将来対応）

- 視力測定・AI分析
- OCR機能
- Firebase Cloud Messaging（FCM）
- ダークモード
- ユーザーアカウント・クラウド同期
- アナリティクス
