# PoE_AffixReader v2

PoE_AffixReader v2 is an AutoHotkey v2-based Path of Exile crafting helper that reads copied item text, matches configured affix patterns, and automates crafting workflows through a dashboard-style UI.

[繁體中文說明](https://github.com/bamd5alifes7/PoE_AffixReader/blob/main/README.zh-TW.md)  
[English Guide](https://github.com/bamd5alifes7/PoE_AffixReader/blob/main/README.en.md)

## Highlights

- dashboard-style main UI
- profile system with built-in and user overrides
- group sets for switching between target packages
- editable primary / secondary / relative affix groups
- English and Traditional Chinese copied item rarity support
- log output for troubleshooting and tuning

## Quick Start

1. Install AutoHotkey v2.
2. Run `PoE_AffixReader_v2.ahk`.
3. Open the dashboard and choose a profile.
4. Capture coordinates if your game layout differs from the default setup.
5. Press `F4` to start and `F12` to stop.

## Hotkeys

- `F4`: start the active profile
- `F7`: capture the current mouse position into `settings.json`
- `F8`: open the profile picker
- `F9`: show the dashboard
- `F10`: edit the active set's affix groups
- `F12`: request stop

## Files

- `v2/profiles/default/*.json`: built-in profiles
- `v2/profiles/user/settings.json`: user coordinate and settings data
- `v2/profiles/user/overrides.json`: user profile overrides
- `log_affix_v2.txt`: run log for troubleshooting

## Documentation

- For complete usage, setup, affix matching, delay tuning, and troubleshooting, see [README.en.md](C:/Users/Adrain Hui/Documents/GitHub/PoE_AffixReader/README.en.md).
- For the full Traditional Chinese guide, see [README.zh-TW.md](C:/Users/Adrain Hui/Documents/GitHub/PoE_AffixReader/README.zh-TW.md).
