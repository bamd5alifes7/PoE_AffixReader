# PoE_AffixReader v2

[繁體中文說明](PoE_AffixReader/README.zh-TW.md)  
[Project Overview](/PoE_AffixReader/README.md)

This build is the AutoHotkey v2 version of the project.

It now includes:
- a dashboard-style main UI
- a profile system
- profile-level group sets
- editable primary affix groups
- log output for troubleshooting

## Run

1. Install AutoHotkey v2.
2. Launch `PoE_AffixReader_v2.ahk`.

## Before You Start

- The app works by copying the current item's text before and after each crafting action, then matching that text against the configured affix patterns.
- Close or disable tools that may conflict with mouse/keyboard automation or item-copy behavior before running it.
- Only run one crafting workflow at a time.
- The default coordinate values were tuned for a 2560x1440 setup. If your layout is different, recapture coordinates before starting.

## Dashboard

The app now opens a main window with four tabs:
- `Home`: active profile, status, and quick actions
- `Profiles`: select the active profile, switch group sets, and inspect settings
- `Coordinates`: edit saved coordinates or use the capture tool
- `Log`: preview the latest log output

## Hotkeys

- `F4`: start the active profile
- `F7`: capture the current mouse position into `settings.json`
- `F8`: open the profile picker
- `F9`: show the dashboard
- `F10`: edit the active set's primary, secondary, and relative `affixGroups`
- `F12`: request stop

## Basic Workflow

1. Start the script and open the dashboard.
2. In `Profiles`, choose the crafting profile you want to run.
3. If needed, switch to the correct group set for that profile.
4. In `Coordinates`, use `F7` or the UI to save currency and crafting button positions.
5. Review the profile targets and affix groups.
6. Go back to the game and press `F4` to start.
7. Hold `F12` when you want to stop.

## Profiles And Storage

- Built-in profiles are loaded from `v2/profiles/default/*.json`.
- User settings are stored in `v2/profiles/user/settings.json`.
- Profile overrides are stored in `v2/profiles/user/overrides.json`.
- Built-in profile JSON files use the `groupSets` structure consistently, even for profiles that only have a single default set.

## Affix Matching Guide

- `targetAffixNum` means how many configured target matches must be found before the run stops.
- Some profiles also use `targetSecondAffixNum` for secondary groups.
- Matching is upward-compatible: if a profile needs `1` match and the item matches `2`, the run still stops successfully.
- The matcher uses regex-style patterns, so you can match exact text, ranges, or multiple variants in one pattern.

Examples:

```text
"(46|47|48)% Lightning Resistance"
"(110|111|112|113|114|115|116|117|118|119) maximum Life"
"Adds [0-9]* to [0-9]* Fire Damage"
```

When writing patterns:

- Make the text distinctive enough to avoid false positives.
- If the same wording can appear in item names, requirements, or other mods, include enough surrounding text or numbers to disambiguate it.
- Escape regex special characters when you want literal text. For example, use `\+` instead of `+`.
- If one vague pattern is hard to maintain, prefer a more explicit numeric range or longer phrase.

Example of escaping:

```text
"\+(3[6-9]|4[0-1])% to Cold Resistance"
```

## Group Sets And Multi-Condition Matching

- A profile can have multiple `groupSets`, and each set can contain primary, secondary, and relative groups.
- Use group sets when you want to keep multiple target packages under one profile and switch between them quickly.
- A single group can hold multiple acceptable patterns.
- Multiple groups let you describe combinations of mods you want the item to satisfy.
- Relative groups are useful for flows that need special handling when certain supporting mods appear.

## Coordinates

- Currency coordinates and the crafting button position are stored in `v2/profiles/user/settings.json`.
- If the default positions do not match your setup, recapture them with `F7` or update them from the `Coordinates` tab.
- `F7` is the fast path when you only want to save the current mouse position without opening the JSON manually.

## Delays And Stability

Common timing values are configured per profile:

- `clipboardDelay`: the most important delay; waits for the game state to update before copying item text
- `pingDelay`: a small extra wait between actions
- `conformDelay`: wait before final affix evaluation
- `debugDelay`: slows the run down for visual inspection
- `mouseSpeed`: mouse travel speed for automated clicks

If the script feels unstable:

- increase `clipboardDelay` first
- check the log to see whether copied item states look incomplete or stale
- only adjust the smaller delays after `clipboardDelay` is already stable

## Logging And Validation

- Every run writes troubleshooting output to `log_affix_v2.txt`.
- The log is the first place to check if the app stops too early, misses a match, or reads the wrong item state.
- Invalid regex patterns are blocked before save, and profile overrides are validated again during startup and reload.
- Reload now restores the previous in-memory state if the updated settings or profile overrides are invalid.

## Notes

- The dashboard is meant to coexist with the existing hotkey workflow.
- The affix editor saves primary, secondary, and relative `affixGroups` for the active set.
- The `Profiles` tab lets you adjust numeric targets only for profile types whose crafting flow safely supports it.
- Relative-match behavior can be configured on profiles that use relative groups.

## Core Layout

The v2 codebase is now split by responsibility so the main app file can stay focused on wiring the UI together.

- `v2/Core/App.ahk`: app bootstrap, main window creation, event wiring, and high-level coordination
- `v2/Core/AppStateLoader.ahk`: reloads user JSON settings, rebuilds profiles, and protects reload with rollback on failure
- `v2/Core/RunController.ahk`: starts a profile run, handles stop requests, and manages run cleanup
- `v2/Core/DashboardController.ahk`: refreshes the `Home` and `Log` tabs
- `v2/Core/ProfilePanelController.ahk`: refreshes the `Profiles` tab, syncs controls, and saves profile target/behavior changes
- `v2/Core/CoordinatePanelController.ahk`: updates the `Coordinates` tab and handles the capture/save flows
- `v2/Core/ProfilePresenter.ahk`: formats target summaries, profile details, and dashboard display text
- `v2/Core/ProfileCapabilities.ahk`: determines which profile settings are editable for each profile type
- `v2/Core/ProfileInputValidator.ahk`: validates profile target inputs and full profile/set data during load
- `v2/Core/PatternValidator.ahk`: validates regex patterns before they are written to disk
- `v2/Core/LogPreviewReader.ahk`: reads a safe preview of the current log file
- `v2/Core/ProfileRegistry.ahk`: defines built-in profiles and normalizes group/set structure
- `v2/Core/ProfileOverrides.ahk`: loads and saves profile overrides from `v2/profiles/user/overrides.json`
- `v2/Core/CraftingEngine.ahk`, `v2/Core/PoeClient.ahk`, `v2/Core/AffixMatcher.ahk`: core crafting loop, game interaction, and affix matching

## Editing Guide

If you want to extend the app, these are the usual places to start:

- Add or change built-in profiles: `v2/Core/ProfileRegistry.ahk`
- Change how overrides are stored in `v2/profiles/user/overrides.json`: `v2/Core/ProfileOverrides.ahk`
- Change dashboard/profile/coordinate tab behavior: the matching `*Controller.ahk` file
- Change display text or summaries without touching tab logic: `v2/Core/ProfilePresenter.ahk`
- Change what counts as valid input or valid regex: `v2/Core/ProfileInputValidator.ahk` and `v2/Core/PatternValidator.ahk`
- Change the actual crafting loop or stop behavior: `v2/Core/RunController.ahk` and `v2/Core/CraftingEngine.ahk`
