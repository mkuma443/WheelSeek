# Chrome Web Store listing draft

## Name

WheelSeek

## Short description

Seek YouTube and Twitch videos with the mouse wheel.

## Detailed description

WheelSeek makes it quick to move through YouTube and Twitch videos without
leaving the video area.

- Scroll up over a video to seek forward.
- Scroll down to seek backward.
- Hold Shift for a fixed 30-second jump.
- Choose a default seek amount from 5 to 30 seconds.
- Optionally vary the jump from 5 to 60 seconds based on wheel intensity.
- Optionally show the estimated local broadcast time while seeking a live
  archive.

WheelSeek only activates while the pointer is inside a supported video and the
player exposes a usable seek range. It supports regular videos, seekable live
streams, and live archives on YouTube and Twitch.

The experimental broadcast clock is designed for comparing multiple viewpoints
from the same livestream event. It uses broadcast metadata already available on
the page when possible. If reliable timing metadata is unavailable, it does not
invent a date and time.

## 日本語の詳しい説明

WheelSeekは、動画の上でマウスホイールを回すだけでYouTubeとTwitchの
再生位置を移動できる拡張機能です。

- 動画上でホイールを上方向へ回すと早送り
- 下方向へ回すと巻き戻し
- Shiftキーを押しながら回すと30秒シーク
- 通常のシーク量を5～30秒から設定
- 回転量に応じた5～60秒の可変シーク（実験的機能）
- ライブアーカイブの推定放送時刻をシーク中に表示（実験的機能）

通常動画、シーク可能なライブ配信、ライブアーカイブに対応しています。
マウスポインターが動画内にあり、プレイヤーに有効なシーク範囲が存在する
場合だけ作動します。

放送時刻表示は、同じライブイベントに参加した複数配信者のアーカイブを
同時刻で見比べる用途を想定しています。ページ内に信頼できる開始日時が
見つからないアーカイブでは、誤った日時を推測して表示しません。

## Single purpose

WheelSeek provides mouse-wheel seeking controls and related seek-time feedback
for videos on YouTube and Twitch.

## Permission justifications

### storage

Stores the user's seek duration and experimental-feature preferences. The
extension does not store viewing history.

### youtube.com and twitch.tv host access

Required to detect the video under the pointer, read its seekable time range,
change its playback position, and show seek feedback.

## Data disclosure

- No data collected
- No data sold or shared
- No analytics
- No remote code
- Settings are stored with Chrome Sync and are not accessible to the developer

## Assets still required before publication

- 1280 × 800 or 640 × 400 store screenshot
- Optional 440 × 280 small promotional tile
- Publicly hosted privacy-policy URL
- Support email and website
