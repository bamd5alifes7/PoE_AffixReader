#Include Logger.ahk
#Include Settings.ahk
#Include AffixMatcher.ahk
#Include PoeClient.ahk
#Include ProfileRegistry.ahk
#Include ProfileOverrides.ahk
#Include CraftingEngine.ahk

class PoeAffixReaderApp {
    __New(baseDir) {
        this.baseDir := baseDir
        this.stopRequested := false
        this.activeProfileId := "chaos_cycle"
    }

    Initialize() {
        this.EnsureAdmin()
        this.settings := SettingsLoader.Load(this.baseDir)
        this.logger := AffixLogger(this.settings["logFile"])
        this.matcher := AffixMatcher()
        this.client := PoeClient(this.settings, this.logger)
        this.profiles := ProfileRegistry.Create()
        ProfileOverrides.Apply(this.settings["iniPath"], this.profiles)
        this.logger.Log("INFO", "app_initialized", Map("activeProfile", this.activeProfileId))
        this.ShowWelcome()
    }

    EnsureAdmin() {
        if A_IsAdmin {
            return
        }
        try {
            if A_IsCompiled {
                Run('*RunAs "' A_ScriptFullPath '"')
            } else {
                Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
            }
        } catch as err {
            MsgBox("Failed to relaunch as administrator.`r`n" err.Message)
        }
        ExitApp
    }

    ShowWelcome() {
        profile := this.profiles[this.activeProfileId]
        MsgBox(
            "PoE_AffixReader v2`r`n`r`n"
            . "Active profile: " profile["name"] " (" profile["id"] ")`r`n"
            . "[F4] Start`r`n"
            . "[F7] Save coordinates`r`n"
            . "[F8] Open profile picker`r`n"
            . "[F9] Show active profile`r`n"
            . "[F10] Edit active affixGroups`r`n"
            . "[F12] Request stop`r`n`r`n"
            . "This build uses the new v2 core, profile system, and logging.`r`n"
            . "Tip: F8 opens a picker UI, so you do not need to type the full profile ID.`r`n"
            . "Tip: F10 edits the active profile's primary affixGroups without changing source code."
        )
    }

    ShowActiveProfile() {
        profile := this.profiles[this.activeProfileId]
        MsgBox(
            "Active profile: " profile["name"] "`r`n"
            . "ID: " profile["id"] "`r`n"
            . "Type: " profile["type"] "`r`n"
            . "Primary target count: " profile["targetAffixNum"] "`r`n"
            . "Secondary target count: " profile["targetSecondAffixNum"] "`r`n"
            . "Primary affix groups: " profile["affixGroups"].Length
        )
    }

    SelectProfile() {
        picker := Gui("+AlwaysOnTop +OwnDialogs", "PoE_AffixReader v2 Profile Picker")
        picker.SetFont("s10", "Segoe UI")
        picker.MarginX := 14
        picker.MarginY := 12

        picker.AddText("w760", "Select a profile from the list below. Typing the full profile ID by hand is no longer needed.")
        listView := picker.AddListView("xm w760 r10 Grid -Multi", ["Name", "ID", "Type", "Target"])

        rowToId := Map()
        selectedId := ""
        selectedRow := 1

        for id, profile in this.profiles {
            targetText := "Primary " profile["targetAffixNum"]
            if profile["targetSecondAffixNum"] > 0 {
                targetText .= " / Secondary " profile["targetSecondAffixNum"]
            }
            row := listView.Add("", profile["name"], id, profile["type"], targetText)
            rowToId[row] := id
            if id = this.activeProfileId {
                selectedRow := row
            }
        }

        listView.ModifyCol(1, 240)
        listView.ModifyCol(2, 220)
        listView.ModifyCol(3, 130)
        listView.ModifyCol(4, 150)
        listView.Modify(selectedRow, "Select Focus Vis")

        selectButton := picker.AddButton("xm w120 Default", "Use Selected")
        cancelButton := picker.AddButton("x+10 w120", "Cancel")

        ConfirmSelection(*) {
            row := listView.GetNext(0, "F")
            if !row {
                row := listView.GetNext()
            }
            if !row || !rowToId.Has(row) {
                MsgBox("Please select a profile from the list.")
                return
            }
            selectedId := rowToId[row]
            picker.Destroy()
        }

        CancelSelection(*) {
            picker.Destroy()
        }

        listView.OnEvent("DoubleClick", (*) => ConfirmSelection())
        selectButton.OnEvent("Click", (*) => ConfirmSelection())
        cancelButton.OnEvent("Click", (*) => CancelSelection())
        picker.OnEvent("Close", (*) => CancelSelection())
        picker.Show()
        WinWaitClose(picker)

        if selectedId = "" {
            return
        }

        this.activeProfileId := selectedId
        this.logger.Log("INFO", "profile_selected", Map("profile", selectedId))
        this.ShowActiveProfile()
    }

    StartActiveProfile() {
        if !this.profiles.Has(this.activeProfileId) {
            MsgBox("No active profile is available.")
            return
        }

        this.stopRequested := false
        profile := this.profiles[this.activeProfileId]

        try {
            engine := CraftingEngine(profile, this.client, this.matcher, this.logger, this)
            engine.Run()
            this.logger.CheckSize()
        } catch as err {
            this.logger.LogError("profile_failed", err, Map("profile", profile["id"]))
            MsgBox("An error occurred during execution. See the log file for details.`r`n`r`n" err.Message)
        } finally {
            this.client.ResetHeldCurrency()
            Send("{LShift Up}")
        }
    }

    RequestStop() {
        this.stopRequested := true
        this.logger.Log("INFO", "stop_requested")
    }

    EditActiveAffixGroups() {
        if !this.profiles.Has(this.activeProfileId) {
            MsgBox("No active profile is available.")
            return
        }

        profile := this.profiles[this.activeProfileId]
        groups := this.CloneGroups(profile["affixGroups"])
        if groups.Length = 0 {
            groups.Push([])
        }

        editor := Gui("+AlwaysOnTop +OwnDialogs +Resize MinSize700x420", "Edit affixGroups")
        editor.SetFont("s10", "Segoe UI")
        editor.MarginX := 14
        editor.MarginY := 12

        header := editor.AddText("w760", "Editing primary affixGroups for " profile["name"] " (" profile["id"] "). One line = one regex pattern.")
        note := editor.AddText("xm y+6 w760", "Reminder: this editor currently saves only the active profile's primary affixGroups. Secondary and relative groups still use code defaults.")
        groupList := editor.AddListBox("xm y+12 w220 r14")
        patternEdit := editor.AddEdit("x+14 yp w520 r14")
        addGroupButton := editor.AddButton("xm y+12 w110", "Add Group")
        removeGroupButton := editor.AddButton("x+10 yp w110", "Remove Group")
        saveButton := editor.AddButton("x+330 yp w110 Default", "Save")
        cancelButton := editor.AddButton("x+10 yp w110", "Cancel")

        currentIndex := 1
        isRefreshing := false

        SaveCurrentGroup() {
            if currentIndex < 1 || currentIndex > groups.Length {
                return
            }
            lines := StrSplit(patternEdit.Value, "`n", "`r")
            cleaned := []
            for _, line in lines {
                value := Trim(line)
                if value != "" {
                    cleaned.Push(value)
                }
            }
            groups[currentIndex] := cleaned
        }

        RefreshGroupList(selectIndex := 1) {
            isRefreshing := true
            entries := []
            for index, group in groups {
                entries.Push("Group " index " (" group.Length " patterns)")
            }
            groupList.Delete()
            groupList.Add(entries)
            if groups.Length > 0 {
                selectIndex := Min(Max(selectIndex, 1), groups.Length)
                groupList.Choose(selectIndex)
                currentIndex := selectIndex
                patternEdit.Value := ProfileOverridesGui.JoinLines(groups[selectIndex])
            } else {
                currentIndex := 0
                patternEdit.Value := ""
            }
            isRefreshing := false
        }

        OnGroupChange(*) {
            if isRefreshing {
                return
            }
            SaveCurrentGroup()
            nextIndex := groupList.Value
            if nextIndex < 1 || nextIndex > groups.Length {
                return
            }
            currentIndex := nextIndex
            RefreshGroupList(currentIndex)
        }

        OnAddGroup(*) {
            SaveCurrentGroup()
            groups.Push([])
            RefreshGroupList(groups.Length)
            patternEdit.Focus()
        }

        OnRemoveGroup(*) {
            if groups.Length = 0 {
                return
            }
            SaveCurrentGroup()
            groups.RemoveAt(currentIndex)
            if groups.Length = 0 {
                groups.Push([])
            }
            RefreshGroupList(Min(currentIndex, groups.Length))
        }

        OnSave(*) {
            SaveCurrentGroup()
            ProfileOverrides.SaveAffixGroups(this.settings["iniPath"], profile["id"], groups)
            profile["affixGroups"] := this.CloneGroups(groups)
            this.logger.Log("INFO", "profile_affixgroups_saved", Map("profile", profile["id"], "groupCount", groups.Length))
            editor.Destroy()
            MsgBox("Primary affixGroups saved for " profile["id"] ".")
        }

        OnCancel(*) {
            editor.Destroy()
        }

        groupList.OnEvent("Change", (*) => OnGroupChange())
        addGroupButton.OnEvent("Click", (*) => OnAddGroup())
        removeGroupButton.OnEvent("Click", (*) => OnRemoveGroup())
        saveButton.OnEvent("Click", (*) => OnSave())
        cancelButton.OnEvent("Click", (*) => OnCancel())
        editor.OnEvent("Close", (*) => OnCancel())

        RefreshGroupList(1)
        editor.Show("w780 h420")
    }

    CloneGroups(groups) {
        clone := []
        for _, group in groups {
            nextGroup := []
            for _, pattern in group {
                nextGroup.Push(pattern)
            }
            clone.Push(nextGroup)
        }
        return clone
    }

    SaveCoordinatesTool() {
        if !this.client.EnsureWindowActive() {
            return
        }

        MouseGetPos(&x, &y)
        result := InputBox(
            "Current coordinates: [" x ", " y "]`r`n"
            . "Enter currency ID`r`n"
            . "1=Alteration 2=Augmentation 3=Scouring 4=Regal 5=Transmutation 6=Alchemy 7=Chaos 8=Essence 9=CraftingButton",
            "PoE_AffixReader v2 Coordinate Tool",
            "w480 h220"
        )
        if result.Result != "OK" {
            return
        }

        keyMap := Map(
            "1", ["Alteration_X", "Alteration_Y"],
            "2", ["Augmentation_X", "Augmentation_Y"],
            "3", ["Scouring_X", "Scouring_Y"],
            "4", ["Regal_X", "Regal_Y"],
            "5", ["Transmutation_X", "Transmutation_Y"],
            "6", ["Alchemy_X", "Alchemy_Y"],
            "7", ["Chaos_X", "Chaos_Y"],
            "8", ["Essence_X", "Essence_Y"],
            "9", ["CraftingButton_X", "CraftingButton_Y"]
        )

        key := Trim(result.Value)
        if !keyMap.Has(key) {
            MsgBox("Please enter a value from 1 to 9.")
            return
        }

        keys := keyMap[key]
        SettingsLoader.SaveCoordinate(this.settings["iniPath"], keys[1], keys[2], x, y)
        this.settings := SettingsLoader.Load(this.baseDir)
        this.client := PoeClient(this.settings, this.logger)
        this.logger.Log("INFO", "coordinate_saved", Map("key", key, "x", x, "y", y))
        MsgBox("Coordinates saved to setting.ini")
    }
}

class ProfileOverridesGui {
    static JoinLines(lines) {
        text := ""
        for index, line in lines {
            if index > 1 {
                text .= "`r`n"
            }
            text .= line
        }
        return text
    }
}
