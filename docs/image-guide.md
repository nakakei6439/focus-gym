# スクリーンショット・アイコン作成ガイド

App Store / Google Play への提出に必要な画像の作成方法です。
Claude は画像を生成できないため、このガイドに沿って作成してください。

---

## 1. アプリアイコン

### 必要サイズ

| プラットフォーム | サイズ | 備考 |
| --- | --- | --- |
| iOS | 1024 × 1024 px | App Store 提出用（@1x） |
| Android | 512 × 512 px | Google Play 提出用 |

### デザイン方針

- **カラー：** ソフトグリーン（`#5C9E7A`）背景 + クリーム（`#FAFAF5`）のアクセント
- **モチーフ：** 葉のような目の形、または目をイメージしたシンプルなアイコン
- **テキスト：** 入れない（小サイズで読めなくなるため）
- **角丸：** iOS は自動で角丸になるため正方形で作成

### 作成ツール（無料）

- **Canva**（canva.com）：テンプレートあり、書き出しが簡単
- **Figma**（figma.com）：精密なデザインが可能
- **Sketch**（Mac専用、有料）

### Canva での手順

1. Canva を開き「カスタムサイズ」で 1024 × 1024 px を指定
2. 背景色を `#5C9E7A` に設定
3. 目のアイコン素材（検索：「eye minimal」）を配置
4. PNG でダウンロード（背景あり）
5. `focus_gym/ios/Runner/Assets.xcassets/AppIcon.appiconset/` に配置

---

## 2. App Store スクリーンショット

### 必要サイズ（最低限）

| デバイス | サイズ | 備考 |
| --- | --- | --- |
| iPhone 6.9"（必須） | 1320 × 2868 px | iPhone 16 Pro Max |
| iPhone 6.5" | 1284 × 2778 px | iPhone 14 Plus など |
| iPhone 5.5" | 1242 × 2208 px | iPhone 8 Plus |

> 6.9" サイズを提出すれば 5.5" 以外は省略可能な場合があります（要確認）。

### 推奨スクリーンショット構成（5枚）

| 枚数 | 内容 | キャッチコピー例 |
| --- | --- | --- |
| 1枚目 | ホーム画面 | 「毎日ちょっとずつ、目をケア」 |
| 2枚目 | トレーニング選択画面 | 「7種類のエクササイズ」 |
| 3枚目 | トレーニング実施中 | 「60fps の滑らかなアニメーション」 |
| 4枚目 | 達成・ストリーク画面 | 「続けるほど、楽しくなる」 |
| 5枚目 | エビデンス説明 | 「科学的根拠に基づいたトレーニング」 |

### 実機からのキャプチャ手順

1. iPhone でアプリを起動
2. 各画面を表示した状態でサイドボタン + 音量アップボタン同時押し
3. 写真アプリに保存される
4. Mac に AirDrop または USB 転送

### スクリーンショットへのテキスト追加（Canva）

1. Canva で「iPhone モックアップ」テンプレートを検索
2. 実機スクリーンショットを貼り付け
3. キャッチコピーテキストを追加（フォント：丸ゴシック系、文字色：`#5C9E7A`）
4. 背景色：クリーム（`#FAFAF5`）または白
5. PNG でダウンロード

---

## 3. App Store プレビュー動画（任意）

- 最大30秒のMP4動画
- 画面収録：iPhone の「コントロールセンター」→「画面収録」
- 編集：iMovie（Mac）で文字追加・BGMなし推奨

---

## 4. Flutter アイコン自動生成

```bash
# flutter_launcher_icons パッケージを使用
cd focus_gym
flutter pub add flutter_launcher_icons

# pubspec.yaml に設定を追加後
flutter pub run flutter_launcher_icons
```

`pubspec.yaml` への追記例：

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"  # 1024x1024 のPNG
```

---

## 5. デザインカラーパレット

| 用途 | カラーコード |
| --- | --- |
| Primary（ソフトグリーン） | `#5C9E7A` |
| Background（クリーム） | `#FAFAF5` |
| Accent（ピーチ） | `#E8A87C` |
| Surface（ライトグリーン） | `#F0F4EE` |
| テキスト | `#333333` |
