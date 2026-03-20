# コマンド一覧

Claude Code で使えるスラッシュコマンドの一覧です。

---

## `/save`

現在の変更を GitHub に保存する。

- `git status` で変更確認 → ステージング → コミット → push まで自動実行
- コミットメッセージは変更内容から自動生成（`feat/fix/docs/chore/style` 形式）

```text
/save
```

---

## `/decisions`

このセッションで行われた重要な決定を `decisions.md` に記録する。

- 現セッションの意思決定を洗い出して追記
- 既存エントリとの重複はスキップ
- セッション末に Claude が自動実施するが、途中で手動記録したい場合にも使える

```text
/decisions
```

---

## `/usage`

Claude API の利用残高・使用量を確認する。

- Anthropic コンソールの請求ページと使用量ページをブラウザで開く

```text
/usage
```

---

## `/sim`

iOSシミュレーターを起動してアプリを実行する。

- iPhone 17 Pro シミュレーターを起動し `flutter run` でアプリを起動
- 起動後のキー操作（`r` Hot Reload / `R` Hot Restart / `q` 終了）を案内

```text
/sim
```

---

## `/device`

実機（iPhone 17 Pro Max）でアプリを実行する。

- デバイスの接続状態を確認し `flutter run` でアプリを起動
- 未接続の場合はUSB接続・ワイヤレスペアリングの手順を案内

```text
/device
```
