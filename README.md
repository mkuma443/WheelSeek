# WheelSeek

WheelSeek is a Chrome extension that seeks YouTube and Twitch videos with the
mouse wheel while the pointer is inside the rendered video.

## Features

- Wheel up: seek forward
- Wheel down: seek backward
- Default seek amount: 10 seconds
- Shift + wheel: fixed 30-second seek
- Configurable seek amount from 5 to 30 seconds
- Experimental variable seek from 5 to 60 seconds based on recent wheel intensity
- Experimental local broadcast clock for live streams and live archives
- Supports regular videos, seekable live streams, and live archives
- Does not run on YouTube Shorts, Twitch Clips, or embedded players

The broadcast clock uses metadata already present on the page when possible.
Active live streams are calculated from the seekable live edge. If a reliable
start timestamp cannot be found for an archive, WheelSeek does not guess.

## Load locally

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked**.
4. Select this repository directory.
5. Open a supported YouTube or Twitch video and place the pointer over it.

After changing source files, press **Reload** on the extension card and reload
the video tab.

## Development

Requirements: Node.js 18 or newer and PowerShell.

```powershell
npm test
npm run check
.\tools\generate-icons.ps1
.\tools\build.ps1
```

The build script creates `dist/WheelSeek-<version>.zip` for Chrome Web Store
upload.

## Privacy

WheelSeek does not collect or transmit browsing history, video history, account
details, or settings. Preferences are stored with `chrome.storage.sync`. See
[PRIVACY.md](PRIVACY.md).
