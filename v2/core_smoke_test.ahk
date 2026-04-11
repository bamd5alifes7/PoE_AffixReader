#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Core\App.ahk

settings := SettingsLoader.Load(A_ScriptDir "\..")
logger := AffixLogger(A_ScriptDir "\core_smoke_test.log")
matcher := AffixMatcher()
client := PoeClient(settings, logger)
profiles := ProfileRegistry.Create()

if profiles.Count = 0 {
    throw Error("No profiles loaded.")
}

ExitApp
