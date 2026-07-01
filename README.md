# 🎸 Bestdori Event Widget for Noctalia

A boppin' little desktop widget for [Noctalia Shell](https://github.com/noctalia-dev/noctalia) that displays the latest active **Bang Dream! Girls Band Party!** server event and its featured cards.

| EN | JP |
|---|---|
| ![EN](screenshot.en.png) | ![JP](screenshot.jp.png) |

## ⚡ Features

- **Multi-Server Support**: Track events from JP, EN, TW, or CN servers via the settings UI.
- **Live Event Info**: Automatically tracks the most recent event from Bestdori for your chosen server.
- **Event Metadata**: Displays the event banner, type (e.g., MISSION LIVE), attribute icon (Pure, Cool, etc.), and duration.
- **Smart Band Matching**: Analyzes the featured characters and resolves their band. Displays the band icon and name (e.g., MyGO!!!!!) or shows "Mixed" if characters are from different bands.
- **Featured Cards**: Fetches and renders 40x40px icons for all event cards.
- **Clickable Links**: Click the banner, event title, or card icons to open the corresponding page on Bestdori.
- **Tooltips**: Hover over card icons to see character names, attribute icons to see attribute names (uppercased), or event dates to see a live countdown.
- **Countdown Tooltip**: Shows "Ends in Xd Xh Xm" for active events, "Starts in..." for upcoming, or "Event ended" for past events.
- **High-Speed Local Cache**: API responses and assets (images/SVGs) are cached locally in the plugin directory. The widget loads instantly and works offline!

## 🖥️ Settings

- **Game Server**: Choose between Japanese, English, Taiwanese, or Chinese servers.

## 📂 File Structure

```
bestdori-event/
├── manifest.json       # Plugin registration
├── Main.qml            # Backend process runner & timer (updates daily)
├── DesktopWidget.qml   # QML UI with dynamic height
├── Settings.qml        # Server selection settings UI
├── fetch.py            # Python helper for caching & data parsing
├── settings.json       # Persisted settings
├── .gitignore          # Ignores cache contents
├── LICENSE             # MIT license
├── README.md           # This file
├── cache/              # Local cache directory (committed via .gitkeep)
│   ├── .gitkeep
│   ├── api/            # Cached event and card JSON files
│   │   └── .gitkeep
│   └── assets/         # Cached banners, attributes, band, and card icons
│       └── .gitkeep
└── screenshots/        # (or root) EN and JP screenshots
```

## 🛠️ How to Enable

1. Place this directory under `~/.config/noctalia/plugins/bestdori-event/`.
2. Add the plugin to your `~/.config/noctalia/plugins.json` under `states`:
   ```json
   "bestdori-event": {
       "enabled": true,
       "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"
   }
   ```
3. Restart Noctalia Shell!
