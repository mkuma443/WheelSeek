# WheelSeek

[日本語](#日本語) | [English](#english)

## 日本語

WheelSeekは、動画の表示領域上でマウスホイールを回して、YouTubeとTwitchの
再生位置を移動できるChrome拡張機能です。

通常動画、ライブアーカイブ、プレイヤー側でシークが許可されている
ライブ配信に対応しています。

### 主な機能

- ホイールを上方向へ回す：早送り
- ホイールを下方向へ回す：巻き戻し
- 通常のシーク量：初期値10秒
- 通常のシーク量を5～30秒の範囲で設定可能
- Shift＋ホイール：30秒固定シーク
- マウスポインターが動画の表示領域内にある場合のみ作動
- 有効なシーク範囲が存在しない動画では作動しない
- 設定はChrome Syncに保存

### 対応サイト・コンテンツ

#### YouTube

- 通常動画
- ライブアーカイブ
- シークが許可されているライブ配信

#### Twitch

- VOD／ライブアーカイブ
- シークバーと有効なシーク範囲が表示されているライブ配信

次のコンテンツは現在対象外です。

- YouTube Shorts
- Twitch Clips
- 外部サイトに埋め込まれたYouTube／Twitchプレイヤー

### 実験的機能

実験的機能は、拡張機能の設定画面から個別にON・OFFできます。
初期状態ではONです。

#### 可変シーク

直近のマウスホイール回転量に応じて、シーク量を5秒刻みで5～60秒の
範囲に変更します。

ゆっくり回した場合は短く、素早く連続して回した場合は長くシークします。

Shiftキーを押している場合は、可変シークの設定よりも30秒固定シークが
優先されます。

#### 放送時刻表示

ライブ配信またはライブアーカイブをシークした際、映像が配信されていたと
推定される日時を動画上部中央に表示します。

```text
2027/07/26
  20:32:50
     +5s
```

- 日付：小さめのフォント
- 時刻：大きめのフォント
- シーク量：通常サイズ
- 表示時間：約1.75秒
- 日時はブラウザのローカルタイムゾーンで表示

ライブアーカイブでは、ページ内にある配信開始日時のメタデータと現在の
再生位置から放送時刻を計算します。

配信中のライブ映像では、現在時刻とライブ端からの遅延量を使用して
計算します。

信頼できる開始日時を取得できないアーカイブでは、誤った日時を推測せず、
通常のシーク量だけを表示します。

この機能は、同じライブイベントに参加した複数配信者のアーカイブを
同時刻で見比べる用途を想定しています。

### 設定

ツールバーのWheelSeekアイコンから設定画面を開けます。

- 通常のシーク量：5～30秒
- 可変シーク：ON／OFF
- 放送時刻表示：ON／OFF

### インストール

[ChromeウェブストアからWheelSeekをインストール](https://chromewebstore.google.com/detail/wheelseek/hmhobkbiphpgnhkjjopellhefeimfidf)

### ローカルでのインストール

1. Chromeで`chrome://extensions`を開きます。
2. **デベロッパーモード**を有効にします。
3. **パッケージ化されていない拡張機能を読み込む**を選択します。
4. このリポジトリのルートディレクトリを選択します。
5. 対応するYouTubeまたはTwitchの動画ページを開きます。

ソースコードを変更した場合は、拡張機能カードの**再読み込み**を押し、
動画ページも再読み込みしてください。

### アクセス権

WheelSeekが要求するアクセス権は、次の用途に限定されています。

#### `storage`

Chromeの`storage.sync`を使用して、次の設定を保存します。

- 通常のシーク秒数
- 可変シークのON／OFF
- 放送時刻表示のON／OFF

Chrome Syncが有効な場合、これらの設定は同じGoogleアカウントでログイン
しているChrome間で同期されることがあります。設定がWheelSeekの開発者へ
送信されることはありません。

#### YouTube・Twitchへのホストアクセス

次のページに限り、拡張機能のコンテンツスクリプトを動作させます。

- `https://www.youtube.com/*`
- `https://m.youtube.com/*`
- `https://www.twitch.tv/*`

このアクセス権は、次の処理に使用します。

- マウスポインター下の動画を検出
- プレイヤーのシーク可能範囲を確認
- 動画の再生位置を変更
- シーク量と推定放送時刻を動画上に表示
- ページ内に既に存在するライブ開始日時のメタデータを確認

WheelSeekは、YouTubeとTwitch以外のウェブサイトへアクセスする権限を
要求しません。また、閲覧履歴、タブ一覧、Cookie、Googleアカウント情報、
ダウンロード、位置情報、カメラ、マイクへアクセスする権限も要求しません。

### プライバシー

WheelSeekは、閲覧履歴、動画の視聴履歴、アカウント情報、ページ内容、
設定情報を開発者へ送信しません。

分析ツール、広告、トラッキング、外部でホストされたコードは使用して
いません。

詳細は[PRIVACY.md](PRIVACY.md)を参照してください。

---

## English

WheelSeek is a Chrome extension that lets you seek YouTube and Twitch videos
with the mouse wheel while the pointer is inside the rendered video area.

It supports regular videos, live archives, and live streams for which the
player exposes a usable seek range.

### Features

- Wheel up: seek forward
- Wheel down: seek backward
- Default seek amount: 10 seconds
- Configurable default seek amount from 5 to 30 seconds
- Shift + wheel: fixed 30-second seek
- Activates only while the pointer is inside the rendered video area
- Does not activate when the player has no usable seek range
- Preferences are stored with Chrome Sync

### Supported sites and content

#### YouTube

- Regular videos
- Live archives
- Seekable live streams

#### Twitch

- VODs and live archives
- Live streams that expose a visible seek bar and usable seek range

The following content is currently excluded:

- YouTube Shorts
- Twitch Clips
- YouTube or Twitch players embedded on third-party websites

### Experimental features

Experimental features can be enabled or disabled individually from the
extension settings. They are enabled by default.

#### Variable seek

Changes the seek amount from 5 to 60 seconds in 5-second increments based on
recent mouse-wheel intensity.

Slow wheel movement produces a shorter seek. Fast consecutive wheel movement
produces a longer seek.

Shift + wheel always performs a fixed 30-second seek and takes priority over
variable seeking.

#### Broadcast clock

When seeking a live stream or live archive, WheelSeek displays the estimated
original broadcast date and time at the top center of the video.

```text
2027/07/26
  20:32:50
     +5s
```

- Date: smaller font
- Time: larger font
- Seek amount: standard size
- Display duration: approximately 1.75 seconds
- Date and time use the browser's local time zone

For live archives, WheelSeek calculates the broadcast time from start-time
metadata already available on the page and the current playback position.

For active live streams, it calculates the time from the current clock and the
distance from the seekable live edge.

If a reliable start timestamp cannot be found for an archive, WheelSeek does
not guess. It displays only the normal seek amount.

This feature is intended for comparing multiple streamer viewpoints from the
same livestream event at approximately the same broadcast time.

### Settings

Open the settings panel from the WheelSeek toolbar icon.

- Default seek amount: 5–30 seconds
- Variable seek: on/off
- Broadcast clock: on/off

### Installation

[Install WheelSeek from the Chrome Web Store](https://chromewebstore.google.com/detail/wheelseek/hmhobkbiphpgnhkjjopellhefeimfidf)

### Local installation

1. Open `chrome://extensions` in Chrome.
2. Enable **Developer mode**.
3. Select **Load unpacked**.
4. Select the root directory of this repository.
5. Open a supported YouTube or Twitch video.

After changing source files, press **Reload** on the extension card and reload
the video tab.

### Permissions

WheelSeek requests only the permissions required for its core features.

#### `storage`

WheelSeek uses Chrome's `storage.sync` API to store:

- Default seek duration
- Variable-seek enabled state
- Broadcast-clock enabled state

When Chrome Sync is enabled, these preferences may be synchronized between
Chrome browsers signed into the same Google account. They are not sent to the
WheelSeek developer.

#### YouTube and Twitch host access

Content scripts run only on:

- `https://www.youtube.com/*`
- `https://m.youtube.com/*`
- `https://www.twitch.tv/*`

This access is used to:

- Detect the video under the mouse pointer
- Read the player's seekable time range
- Change the video's playback position
- Display seek feedback and the estimated broadcast time
- Read live-start metadata already present on the page

WheelSeek does not request access to websites other than YouTube and Twitch.
It also does not request permission to access browsing history, the tab list,
cookies, Google account information, downloads, location, the camera, or the
microphone.

### Privacy

WheelSeek does not transmit browsing history, video-viewing history, account
information, page content, or preferences to the developer.

WheelSeek does not use analytics, advertising, tracking services, or remotely
hosted code.

See [PRIVACY.md](PRIVACY.md) for details.
