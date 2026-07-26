# Chromeウェブストア登録チェックリスト

## 必須

- [x] Manifest V3 ZIP：`dist/WheelSeek-0.1.0.zip`
- [x] 128×128 PNGアイコン：`icons/icon-128.png`
- [x] 1280×800 PNGスクリーンショット案（3枚）
- [x] 440×280 PNGプロモーション画像
- [x] 日本語掲載文：`store/listing-ja.md`
- [x] 英語掲載文：`store/listing-en.md`
- [x] 単一用途と権限説明：`store/privacy-dashboard.md`
- [x] 公開プライバシーポリシー：`PRIVACY.md`
- [ ] Developer Dashboardで開発者メールを確認
- [ ] Developer Dashboardで2段階認証を確認
- [ ] 配布範囲を選択
- [ ] データ利用のチェック項目を実際の画面文言と照合
- [ ] 審査へ提出

## 任意だが推奨

- [x] 1400×560 PNGマーキー画像
- [ ] 機能紹介YouTube動画
- [x] ホームページ：https://github.com/mkuma443/WheelSeek
- [x] サポートURL：https://github.com/mkuma443/WheelSeek/issues
- [ ] GitHub Issuesを有効化してサポートURLを確認
- [ ] 公開前に実際のChrome画面から最終スクリーンショットを撮影

## 推奨する初回配布設定

- 公開範囲：一般公開
- 価格：無料
- カテゴリ：仕事効率化／Productivity
- メイン言語：日本語
- 追加ローカライズ：English
- 審査通過後の公開：手動公開

## 登録前の最終確認

- ストア掲載文と実装機能が一致している
- スクリーンショットが実際のユーザー体験を正確に示している
- 不要な権限がManifestに含まれていない
- プライバシーポリシーとDashboardの申告が一致している
- ZIP内の`manifest.json`がルートにある
- バージョンが直前のアップロードより大きい
- YouTubeおよびTwitchとの非提携表記が掲載されている
