#Requires AutoHotkey v2.0
#SingleInstance Force

#Include v2\Core\App.ahk

global PoEApp := PoeAffixReaderApp(A_ScriptDir)
PoEApp.Initialize()

F4::PoEApp.StartActiveProfile()
F7::PoEApp.SaveCoordinatesTool()
F8::PoEApp.SelectProfile()
F9::PoEApp.ShowActiveProfile()
F10::PoEApp.EditActiveAffixGroups()
F12::PoEApp.RequestStop()
