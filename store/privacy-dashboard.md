# Chromeウェブストア「プライバシーへの取り組み」入力案

この文書はDeveloper Dashboardへ転記するための案です。

## 単一用途

### 日本語

YouTubeとTwitchのシーク可能な動画を、動画領域内でのマウスホイール操作に
よって早送り・巻き戻しし、シーク量および利用可能な場合は推定放送時刻を
表示すること。

### English

Allow users to seek supported YouTube and Twitch videos with the mouse wheel
while the pointer is inside the video area, and display seek feedback and,
when available, the estimated original broadcast time.

## 権限の正当性

### `storage`

#### 日本語

通常のシーク秒数、可変シークのON／OFF、放送時刻表示のON／OFFを
`chrome.storage.sync`へ保存するために使用します。それ以外のデータは
保存しません。

#### English

Used only to save the default seek duration, variable-seek enabled state, and
broadcast-clock enabled state with `chrome.storage.sync`. No other data is
stored.

### `https://www.youtube.com/*`、`https://m.youtube.com/*`

#### 日本語

YouTube上で動画領域とシーク可能範囲を検出し、再生位置を変更し、シーク表示を
描画するために必要です。実験的な放送時刻表示がONの場合は、ページ内に既に
存在するライブ開始日時メタデータも端末内で確認します。

#### English

Required on YouTube to detect the video area and seekable range, change the
playback position, and render seek feedback. When the experimental broadcast
clock is enabled, WheelSeek also reads live-start metadata already present on
the page and processes it locally.

### `https://www.twitch.tv/*`

#### 日本語

Twitch上で動画領域、表示中のシークバー、シーク可能範囲を検出し、再生位置を
変更し、シーク表示を描画するために必要です。実験的な放送時刻表示がONの場合は、
ページ内に既に存在するVOD開始日時メタデータも端末内で確認します。

#### English

Required on Twitch to detect the video area, visible seek bar, and seekable
range, change the playback position, and render seek feedback. When the
experimental broadcast clock is enabled, WheelSeek also reads VOD start-time
metadata already present on the page and processes it locally.

## データ利用の申告案

Developer Dashboardの現在の文言を確認したうえで、次を選択する保守的な案です。

- ウェブサイトのコンテンツ：該当
  - 動画要素、シーク可能範囲、ライブ開始日時メタデータを端末内で処理
- ユーザーの操作：該当
  - ホイール入力とポインター位置を端末内で一時的に処理
- 個人を特定できる情報：該当なし
- 健康情報：該当なし
- 金融・支払い情報：該当なし
- 認証情報：該当なし
- 個人的な通信：該当なし
- 位置情報：該当なし
- ウェブ履歴：該当なし

上記の「ウェブサイトのコンテンツ」と「ユーザーの操作」は、機能の実行中に
端末内で一時的に利用するだけです。収集、永続保存、開発者への送信、販売、
第三者共有、人による閲覧は行いません。

## Limited Useへの適合

Developer Dashboardに表示される各認証項目について、現在の実装は次を満たします。

- データをWheelSeekの単一用途の提供以外に使用しない
- データを第三者へ販売または転送しない
- データを広告、信用判断、融資目的に使用しない
- 人がユーザーデータを閲覧できるようにしない

### 公開ページへ掲載するLimited Use文

#### 日本語

WheelSeekによるユーザーデータの利用は、Chromeウェブストアのユーザーデータ
ポリシー（Limited Use要件を含む）に準拠します。WheelSeekは、対応ページの
コンテンツおよびユーザー操作を、ユーザー向けシーク機能の提供に必要な範囲で
端末内処理するだけであり、外部へ送信、販売、第三者共有しません。

#### English

WheelSeek's use of information complies with the Chrome Web Store User Data
Policy, including the Limited Use requirements. WheelSeek processes supported
page content and user interactions locally only as necessary to provide its
user-facing seek functionality. It does not transmit, sell, or share this
information with third parties.

## プライバシーポリシーURL

https://github.com/mkuma443/WheelSeek/blob/main/PRIVACY.md
