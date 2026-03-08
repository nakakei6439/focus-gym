# CLAUDE.md

## ルール

- 回答は必ず日本語
- セッション末に重要な決定を `decisions.md` へ追記する（セミオート：Claude が自発的に実施）
- 手動で記録したい場合は `/decisions` コマンドを使う
- 新しいコマンドを `.claude/commands/` に作成したら `COMMANDS.md` にも追記する

---

## ドキュメント構成

| ファイル | 内容 |
| --- | --- |
| `requirements.md` | 機能要件・技術スタック・実装済み機能・ディレクトリ構成 |
| `business_plan.md` | 事業方針・ターゲット・収益計画・将来展望 |
| `decisions.md` | 意思決定ログ（なぜそう決めたか） |

Flutterアプリは `focus_gym/` サブディレクトリ。

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

## Git ルール

- `main` は常にリリース可能な状態を維持
- 作業は `feature/*` ブランチで行い、PR → squash マージ
- `git push`・PR作成・マージは必ずユーザー確認を取ってから実行
- `--force`・`--no-verify`・main 直接 push は禁止
- コミット規約: `feat/fix/refactor/style/docs/chore: メッセージ`
