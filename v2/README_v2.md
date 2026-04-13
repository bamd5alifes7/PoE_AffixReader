# PoE_AffixReader v2

This build is the AutoHotkey v2 version of the project.

It now includes:
- a dashboard-style main UI
- a profile system
- profile-level group sets
- editable primary affix groups
- log output for troubleshooting

## Run

1. Install AutoHotkey v2.
2. Launch [`PoE_AffixReader_v2.ahk`](../PoE_AffixReader_v2.ahk).

## Dashboard

The app now opens a main window with four tabs:
- `Home`: active profile, status, and quick actions
- `Profiles`: select the active profile, switch group sets, and inspect settings
- `Coordinates`: edit saved coordinates or use the capture tool
- `Log`: preview the latest log output

## Hotkeys

- `F4`: start the active profile
- `F7`: capture the current mouse position into `setting.ini`
- `F8`: open the profile picker
- `F9`: show the dashboard
- `F10`: edit the active set's primary, secondary, and relative `affixGroups`
- `F12`: request stop

## Notes

- The dashboard is meant to coexist with the existing hotkey workflow.
- The affix editor saves primary, secondary, and relative `affixGroups` for the active set.
- The `Profiles` tab lets you adjust numeric targets only for profile types whose crafting flow safely supports it.
- Relative-match behavior can be configured on profiles that use relative groups.
