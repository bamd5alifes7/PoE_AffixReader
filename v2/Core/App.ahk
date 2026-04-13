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
        this.runStatus := "Idle"
        this.mainGui := ""
        this.mainTabs := ""
        this.controls := Map()
        this.profileRowToId := Map()
        this.coordinateKeys := [
            ["Alteration", "Alteration_X", "Alteration_Y"],
            ["Augmentation", "Augmentation_X", "Augmentation_Y"],
            ["Scouring", "Scouring_X", "Scouring_Y"],
            ["Regal", "Regal_X", "Regal_Y"],
            ["Transmutation", "Transmutation_X", "Transmutation_Y"],
            ["Alchemy", "Alchemy_X", "Alchemy_Y"],
            ["Chaos", "Chaos_X", "Chaos_Y"],
            ["Essence", "Essence_X", "Essence_Y"],
            ["CraftingButton", "CraftingButton_X", "CraftingButton_Y"]
        ]
    }

    Initialize() {
        this.EnsureAdmin()
        this.settings := SettingsLoader.Load(this.baseDir)
        this.logger := AffixLogger(this.settings["logFile"])
        this.matcher := AffixMatcher()
        this.client := PoeClient(this.settings, this.logger)
        this.profiles := ProfileRegistry.Create()
        ProfileOverrides.Apply(this.settings["iniPath"], this.profiles)
        if !this.profiles.Has(this.activeProfileId) {
            for profileId, _ in this.profiles {
                this.activeProfileId := profileId
                break
            }
        }
        this.CreateMainWindow()
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
        this.UpdateStatus("Ready. Select a profile and use the hotkeys when Path of Exile is focused.")
        this.ShowMainWindow(1)
    }

    CreateMainWindow() {
        mainWindow := Gui("+Resize MinSize960x720", "PoE_AffixReader v2 Dashboard")
        mainWindow.SetFont("s10", "Segoe UI")
        mainWindow.MarginX := 14
        mainWindow.MarginY := 12
        mainWindow.OnEvent("Close", (*) => mainWindow.Hide())
        mainWindow.OnEvent("Escape", (*) => mainWindow.Hide())

        mainWindow.AddText("xm w920", "PoE_AffixReader v2")
        mainWindow.SetFont("s9", "Segoe UI")
        mainWindow.AddText("xm y+4 w920", "Hotkeys still work. This dashboard gives you a main UI for profile selection, coordinate editing, and quick log review.")

        tabs := mainWindow.AddTab3("xm y+12 w920 h620", ["Home", "Profiles", "Coordinates", "Log"])
        this.mainGui := mainWindow
        this.mainTabs := tabs

        tabs.UseTab(1)
        this.BuildHomeTab(mainWindow)

        tabs.UseTab(2)
        this.BuildProfilesTab(mainWindow)

        tabs.UseTab(3)
        this.BuildCoordinatesTab(mainWindow)

        tabs.UseTab(4)
        this.BuildLogTab(mainWindow)

        tabs.UseTab()
        this.RefreshAllViews()
    }

    BuildHomeTab(gui) {
        leftX := 30
        profileX := leftX
        stopRuleX := 354
        topLabelY := 124
        topBoxY := 144
        topValueY := 170
        topMetaY := 204
        topCardH := 138
        profileW := 288
        stopRuleW := 496
        statusLabelY := 300
        statusBoxY := 320
        statusValueY := 346
        statusMetaY := 378
        statusW := 820
        statusH := 86
        guideLabelY := 430
        guideBoxY := 450
        guideStartY := 476
        guideKeyX := 52
        guideTextX := 118
        guideRowGap := 29

        gui.SetFont("s8 w400", "Segoe UI")
        gui.AddText("x" profileX " y" topLabelY " w160 h20", "Profile")
        gui.AddText("x" stopRuleX " y" topLabelY " w160 h20", "Target")

        gui.AddGroupBox("x" profileX " y" topBoxY " w" profileW " h" topCardH, "")
        gui.AddGroupBox("x" stopRuleX " y" topBoxY " w" stopRuleW " h" topCardH, "")

        gui.SetFont("s14 w700", "Segoe UI")
        this.controls["homeProfileValue"] := gui.AddText("x48 y" topValueY " w252 h26", "")
        this.controls["homeStopRuleValue"] := gui.AddText("x372 y" topValueY " w460 h26", "")

        gui.SetFont("s9 w400", "Segoe UI")
        this.controls["homeProfileMeta"] := gui.AddText("x48 y" topMetaY " w252 h56", "")
        this.controls["homeStopRuleMeta"] := gui.AddText("x372 y" topMetaY " w460 h56", "")

        gui.SetFont("s8 w400", "Segoe UI")
        gui.AddText("x" leftX " y" statusLabelY " w160 h20", "Run Status")
        gui.AddGroupBox("x" leftX " y" statusBoxY " w" statusW " h" statusH, "")

        gui.SetFont("s13 w700", "Segoe UI")
        this.controls["homeStatusValue"] := gui.AddText("x48 y" statusValueY " w180 h24", "")
        gui.SetFont("s9 w400", "Segoe UI")
        this.controls["homeStatusMeta"] := gui.AddText("x210 y" statusMetaY " w610 h24", "")

        gui.SetFont("s8 w400", "Segoe UI")
        gui.AddText("x" leftX " y" guideLabelY " w220 h20", "Hotkey Guide")
        gui.AddGroupBox("x30 y" guideBoxY " w820 h206", "")

        this.controls["homeGuideKeys"] := []
        this.controls["homeGuideTexts"] := []
        guideRows := [
            ["F4", ""],
            ["F7", ""],
            ["F8", ""],
            ["F9", ""],
            ["F10", ""],
            ["F12", ""]
        ]

        for index, row in guideRows {
            rowY := guideStartY + ((index - 1) * guideRowGap)
            gui.SetFont("s9 w700", "Segoe UI")
            this.controls["homeGuideKeys"].Push(gui.AddText("x" guideKeyX " y" rowY " w54 h20", row[1]))
            gui.SetFont("s9 w400", "Segoe UI")
            this.controls["homeGuideTexts"].Push(gui.AddText("x" guideTextX " y" rowY " w680 h20", row[2]))
        }
    }

    BuildProfilesTab(gui) {
        gui.AddText("xm+16 y+20 w860", "Choose which crafting profile is active. Double-click a row to activate that profile immediately.")
        profileList := gui.AddListView("xm+16 y+10 w860 r7 Grid -Multi", ["Profile", "Target", "Set", "Groups"])
        profileList.ModifyCol(1, 180)
        profileList.ModifyCol(2, 130)
        profileList.ModifyCol(3, 120)
        profileList.ModifyCol(4, 390)
        this.controls["profileList"] := profileList
        gui.SetFont("s9 w400", "Segoe UI")
        useButton := gui.AddButton("xm+16 y+12 w140 h32 Default", "Use Profile")
        applySetButton := gui.AddButton("x+10 yp w120 h32", "Use Set")
        editButton := gui.AddButton("x+10 yp w130 h32", "Edit Affixes")

        gui.AddText("xm+16 y+18 w60 h20", "Set")
        this.controls["profileSetPicker"] := gui.AddDropDownList("x+8 yp-3 w220 Choose1", [])
        addSetButton := gui.AddButton("x+10 yp w90 h28", "Add")
        renameSetButton := gui.AddButton("x+8 yp w90 h28", "Rename")
        removeSetButton := gui.AddButton("x+8 yp w90 h28", "Remove")

        gui.AddText("xm+16 y+18 w90 h20", "Primary Target")
        this.controls["profilePrimaryTargetEdit"] := gui.AddEdit("x+8 yp-3 w60 Number", "")
        gui.AddText("x+20 yp+3 w104 h20", "Secondary Target")
        this.controls["profileSecondaryTargetEdit"] := gui.AddEdit("x+8 yp-3 w60 Number", "")
        saveTargetButton := gui.AddButton("x+12 yp-3 w94 h28", "Save")

        this.controls["profileRelativeSkipCheckbox"] := gui.AddCheckbox("xm+16 y+16 w340 h20", "Skip Augment When Relative Match")
        this.controls["profileTargetHint"] := gui.AddText("xm+16 y+10 w860 h32 c666666", "")

        gui.AddGroupBox("x30 y508 w860 h176", "Summary")
        this.controls["profileDetails"] := gui.AddEdit("x44 y534 w832 h136 ReadOnly VScroll -Wrap", "")

        profileList.OnEvent("ItemFocus", (*) => this.UpdateSelectedProfileDetails())
        profileList.OnEvent("DoubleClick", (*) => this.UseSelectedProfileFromList())
        this.controls["profileSetPicker"].OnEvent("Change", (*) => this.UpdateSelectedProfileDetails())
        applySetButton.OnEvent("Click", (*) => this.ApplySelectedProfileSet())
        addSetButton.OnEvent("Click", (*) => this.AddGroupSetToSelectedProfile())
        renameSetButton.OnEvent("Click", (*) => this.RenameSelectedProfileSet())
        removeSetButton.OnEvent("Click", (*) => this.RemoveSelectedProfileSet())
        saveTargetButton.OnEvent("Click", (*) => this.SaveSelectedProfileTargets())
        useButton.OnEvent("Click", (*) => this.UseSelectedProfileFromList())
        editButton.OnEvent("Click", (*) => this.EditActiveAffixGroups())
    }

    BuildCoordinatesTab(gui) {
        gui.AddText("xm+16 y+40 w860", "Edit saved coordinates here, or capture the current mouse position inside PoE with the helper button.")
        gui.AddText("xm+16 y+14 w180", "Currency / Action")
        gui.AddText("x+24 yp w120", "X")
        gui.AddText("x+24 yp w120", "Y")

        this.controls["coordinateEdits"] := Map()

        for index, item in this.coordinateKeys {
            label := item[1]
            keyX := item[2]
            keyY := item[3]
            yOption := index = 1 ? "xm+16 y+10" : "xm+16 y+8"
            gui.AddText(yOption . " w180", label)
            editX := gui.AddEdit("x+24 yp-4 w120 Number", "")
            editY := gui.AddEdit("x+24 yp w120 Number", "")
            this.controls["coordinateEdits"][keyX] := editX
            this.controls["coordinateEdits"][keyY] := editY
        }

        saveButton := gui.AddButton("xm+16 y+18 w140 h32 Default", "Save Coordinates")
        reloadButton := gui.AddButton("x+10 yp w140 h32", "Reload")
        captureButton := gui.AddButton("x+10 yp w180 h32", "Capture With Mouse (F7)")
        this.controls["coordinateStatus"] := gui.AddText("xm+16 y+14 w860 h24", "")

        saveButton.OnEvent("Click", (*) => this.SaveCoordinatesFromForm())
        reloadButton.OnEvent("Click", (*) => this.ReloadSettingsFromDisk())
        captureButton.OnEvent("Click", (*) => this.SaveCoordinatesTool())
    }

    BuildLogTab(gui) {
        this.controls["logPath"] := gui.AddText("xm+16 y+40 w860", "")
        this.controls["logPreview"] := gui.AddEdit("xm+16 y+10 w860 r22 ReadOnly -Wrap", "")
        refreshButton := gui.AddButton("xm+16 y+16 w140 h32 Default", "Refresh Log")
        homeButton := gui.AddButton("x+10 yp w160 h32", "Back To Home")

        refreshButton.OnEvent("Click", (*) => this.RefreshLogPreview())
        homeButton.OnEvent("Click", (*) => this.ShowMainWindow(1))
    }

    ShowMainWindow(tabIndex := 1) {
        this.RefreshAllViews()
        if IsObject(this.mainTabs) {
            this.mainTabs.Choose(tabIndex)
        }
        this.mainGui.Show("w950 h690")
        this.mainGui.Opt("+AlwaysOnTop")
        this.mainGui.Opt("-AlwaysOnTop")
    }

    ShowActiveProfile() {
        this.ShowMainWindow(1)
    }

    SelectProfile() {
        picker := Gui("+AlwaysOnTop +OwnDialogs", "PoE_AffixReader v2 Profile Picker")
        picker.SetFont("s10", "Segoe UI")
        picker.MarginX := 14
        picker.MarginY := 12

        picker.AddText("w760", "Select a profile from the list below. Typing the full profile ID by hand is no longer needed.")
        listView := picker.AddListView("xm w760 r10 Grid -Multi", ["Profile", "Target", "Set"])

        rowToId := Map()
        selectedId := ""
        selectedRow := 1

        for id, profile in this.profiles {
            row := listView.Add("", profile["name"], this.TargetText(profile), this.ActiveGroupSetName(profile))
            rowToId[row] := id
            if id = this.activeProfileId {
                selectedRow := row
            }
        }

        listView.ModifyCol(1, 280)
        listView.ModifyCol(2, 220)
        listView.ModifyCol(3, 220)
        listView.Modify(selectedRow, "Select Focus Vis")

        selectButton := picker.AddButton("xm w160 h34 Default", "Activate Profile")
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

        this.SetActiveProfile(selectedId, true)
        this.ShowMainWindow(2)
    }

    UseSelectedProfileFromList() {
        row := this.controls["profileList"].GetNext(0, "F")
        if !row {
            row := this.controls["profileList"].GetNext()
        }
        if !row || !this.profileRowToId.Has(row) {
            MsgBox("Please select a profile from the list.")
            return
        }
        this.SetActiveProfile(this.profileRowToId[row], true)
        this.ShowMainWindow(2)
    }

    SetActiveProfile(profileId, announce := false) {
        if !this.profiles.Has(profileId) {
            MsgBox("Profile not found: " profileId)
            return false
        }

        this.activeProfileId := profileId
        this.logger.Log("INFO", "profile_selected", Map("profile", profileId))
        this.UpdateStatus("Active profile changed to " this.profiles[profileId]["name"] ".")
        this.RefreshAllViews()
        if announce {
            profile := this.profiles[profileId]
            MsgBox(
                "Active profile: " profile["name"] "`r`n"
                . "Type: " profile["type"] "`r`n"
                . "Set: " this.ActiveGroupSetName(profile) "`r`n"
                . "Target: " this.TargetText(profile)
            )
        }
        return true
    }

    GetSelectedProfileId() {
        if !this.controls.Has("profileList") {
            return this.activeProfileId
        }
        row := this.controls["profileList"].GetNext(0, "F")
        if !row {
            row := this.controls["profileList"].GetNext()
        }
        if row && this.profileRowToId.Has(row) {
            return this.profileRowToId[row]
        }
        return this.activeProfileId
    }

    GetSelectedProfile() {
        profileId := this.GetSelectedProfileId()
        return this.profiles.Has(profileId) ? this.profiles[profileId] : ""
    }

    SelectedSetIndex(profile) {
        if !this.controls.Has("profileSetPicker") {
            return profile["activeGroupSetIndex"]
        }
        setIndex := this.controls["profileSetPicker"].Value
        if setIndex < 1 || setIndex > profile["groupSets"].Length {
            return profile["activeGroupSetIndex"]
        }
        return setIndex
    }

    ApplySelectedProfileSet() {
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }

        setIndex := this.SelectedSetIndex(profile)
        this.SetProfileGroupSet(profile["id"], setIndex, true)
    }

    SetProfileGroupSet(profileId, setIndex, announce := false) {
        if !this.profiles.Has(profileId) {
            MsgBox("Profile not found: " profileId)
            return false
        }

        profile := this.profiles[profileId]
        activeSet := ProfileRegistry.ActivateGroupSet(profile, setIndex)
        ProfileOverrides.SaveProfileGroupSets(this.settings["iniPath"], profile)
        this.logger.Log("INFO", "profile_groupset_selected", Map("profile", profileId, "setIndex", setIndex, "setName", activeSet["name"]))
        if profileId = this.activeProfileId {
            this.UpdateStatus("Active set changed to " activeSet["name"] " for " profile["name"] ".")
        }
        this.RefreshAllViews()
        if announce {
            MsgBox("Active set for " profile["name"] " is now " activeSet["name"] ".")
        }
        return true
    }

    AddGroupSetToSelectedProfile() {
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }

        sourceIndex := this.SelectedSetIndex(profile)
        sourceSet := ProfileRegistry.NormalizeGroupSet(profile["groupSets"][sourceIndex], "Set " sourceIndex)
        nextIndex := profile["groupSets"].Length + 1
        newSet := Map(
            "name", "Set " nextIndex,
            "affixGroups", this.CloneGroups(sourceSet["affixGroups"]),
            "secondaryAffixGroups", this.CloneGroups(sourceSet["secondaryAffixGroups"]),
            "relativeAffixGroups", this.CloneGroups(sourceSet["relativeAffixGroups"])
        )
        profile["groupSets"].Push(ProfileRegistry.NormalizeGroupSet(newSet, "Set " nextIndex))
        profile["activeGroupSetIndex"] := profile["groupSets"].Length
        ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
        ProfileOverrides.SaveProfileGroupSets(this.settings["iniPath"], profile)
        this.logger.Log("INFO", "profile_groupset_added", Map("profile", profile["id"], "setIndex", profile["activeGroupSetIndex"]))
        this.UpdateStatus("Added set " this.ActiveGroupSetName(profile) " for " profile["name"] ".")
        this.RefreshAllViews()
    }

    RenameSelectedProfileSet() {
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }

        setIndex := this.SelectedSetIndex(profile)
        groupSet := ProfileRegistry.NormalizeGroupSet(profile["groupSets"][setIndex], "Set " setIndex)
        result := InputBox("Enter a name for this set.", "Rename Set", "w360 h140", groupSet["name"])
        if result.Result != "OK" {
            return
        }

        setName := Trim(result.Value)
        if setName = "" {
            MsgBox("Set name cannot be blank.")
            return
        }

        groupSet["name"] := setName
        profile["groupSets"][setIndex] := ProfileRegistry.NormalizeGroupSet(groupSet, "Set " setIndex)
        ProfileOverrides.SaveProfileGroupSets(this.settings["iniPath"], profile)
        this.logger.Log("INFO", "profile_groupset_renamed", Map("profile", profile["id"], "setIndex", setIndex, "setName", setName))
        this.UpdateStatus("Renamed set to " setName " for " profile["name"] ".")
        this.RefreshAllViews()
    }

    RemoveSelectedProfileSet() {
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }
        if profile["groupSets"].Length <= 1 {
            MsgBox("Each profile needs at least one set.")
            return
        }

        setIndex := this.SelectedSetIndex(profile)
        removingSet := profile["groupSets"][setIndex]
        currentActiveIndex := profile["activeGroupSetIndex"]
        answer := MsgBox("Remove set '" removingSet["name"] "' from " profile["name"] "?", "Remove Set", "YesNo")
        if answer != "Yes" {
            return
        }

        profile["groupSets"].RemoveAt(setIndex)
        if currentActiveIndex = setIndex {
            nextIndex := Min(setIndex, profile["groupSets"].Length)
        } else if currentActiveIndex > setIndex {
            nextIndex := currentActiveIndex - 1
        } else {
            nextIndex := currentActiveIndex
        }
        ProfileRegistry.ActivateGroupSet(profile, nextIndex)
        ProfileOverrides.SaveProfileGroupSets(this.settings["iniPath"], profile)
        this.logger.Log("INFO", "profile_groupset_removed", Map("profile", profile["id"], "setIndex", setIndex))
        this.UpdateStatus("Removed set " removingSet["name"] " from " profile["name"] ".")
        this.RefreshAllViews()
    }

    StartActiveProfile() {
        if !this.profiles.Has(this.activeProfileId) {
            MsgBox("No active profile is available.")
            return
        }

        this.stopRequested := false
        profile := this.profiles[this.activeProfileId]
        this.UpdateStatus("Running profile " profile["name"] ". Press F12 or Stop to request a halt.")
        this.RefreshAllViews()

        try {
            engine := CraftingEngine(profile, this.client, this.matcher, this.logger, this)
            engine.Run()
            this.logger.CheckSize()
            if this.stopRequested {
                this.UpdateStatus("Stop requested. Review the item and log before the next run.")
            } else {
                this.UpdateStatus("Profile run completed for " profile["name"] ".")
            }
        } catch as err {
            this.logger.LogError("profile_failed", err, Map("profile", profile["id"]))
            this.UpdateStatus("Run failed. Check the log for details.")
            MsgBox("An error occurred during execution. See the log file for details.`r`n`r`n" err.Message)
        } finally {
            this.client.ResetHeldCurrency()
            Send("{LShift Up}")
            this.RefreshAllViews()
        }
    }

    RequestStop() {
        this.stopRequested := true
        this.logger.Log("INFO", "stop_requested")
        this.UpdateStatus("Stop requested. The current loop will halt after the in-flight step.")
        this.RefreshAllViews()
    }

    EditActiveAffixGroups() {
        if !this.profiles.Has(this.activeProfileId) {
            MsgBox("No active profile is available.")
            return
        }

        profile := this.profiles[this.activeProfileId]
        activeSet := this.ActiveGroupSet(profile)
        primaryGroups := this.CloneGroups(activeSet["affixGroups"])
        secondaryGroups := this.CloneGroups(activeSet["secondaryAffixGroups"])
        relativeGroups := this.CloneGroups(activeSet["relativeAffixGroups"])

        editor := Gui("+AlwaysOnTop +OwnDialogs +Resize MinSize820x620", "Edit affixGroups")
        editor.SetFont("s10", "Segoe UI")
        editor.MarginX := 14
        editor.MarginY := 12

        editor.AddText("w790", "Editing affix groups for " profile["name"] " / " activeSet["name"] ". One line = one regex pattern.")
        editor.AddText("xm y+6 w790", "You can edit the active set's primary, secondary, and relative affix groups here.")
        headerY := 70
        listX := 14
        listW := 240
        rightXGap := 18
        rightX := listX + listW + rightXGap
        rightW := 520
        groupTypeLabelY := headerY
        groupTypePickerY := headerY - 3
        listY := headerY + 46
        nameLabelY := listY
        nameEditY := nameLabelY + 24
        patternMetaY := nameEditY + 42
        patternsLabelY := patternMetaY
        patternStatsX := rightX + 180
        patternsEditY := patternsLabelY + 24
        editor.AddText("x" listX " y" groupTypeLabelY " w74", "Group Type")
        groupTypePicker := editor.AddDropDownList("x92 y" groupTypePickerY " w162 Choose1", ["Primary", "Secondary", "Relative"])
        editor.AddText("x" listX " y" (listY - 26) " w240", "Groups")
        groupList := editor.AddListBox("x" listX " y" listY " w" listW " h390")
        editor.AddText("x" rightX " y" nameLabelY " w520", "Group Name")
        groupNameEdit := editor.AddEdit("x" rightX " y" nameEditY " w" rightW)
        editor.AddText("x" rightX " y" patternsLabelY " w160", "Patterns")
        patternStatsText := editor.AddText("x" patternStatsX " y" patternsLabelY " w340 Right", "")
        patternEdit := editor.AddEdit("x" rightX " y" patternsEditY " w" rightW " h346 WantTab -Wrap HScroll")
        patternEdit.SetFont("s10", "Consolas")
        addGroupButton := editor.AddButton("x" listX " y+24 w120", "Add Group")
        removeGroupButton := editor.AddButton("x+10 yp w120", "Remove Group")
        saveButton := editor.AddButton("x+300 yp w110 Default", "Save")
        cancelButton := editor.AddButton("x+10 yp w110", "Cancel")

        baseWidth := 820
        baseHeight := 620
        buttonYGap := 18
        buttonW := 120
        buttonGap := 10
        buttonsY := 526
        contentBottom := buttonsY - buttonYGap
        listH := contentBottom - listY
        patternH := contentBottom - patternsEditY

        currentIndex := 1
        isRefreshing := false
        currentGroupType := "Primary"

        CurrentGroups() {
            if currentGroupType = "Secondary" {
                return secondaryGroups
            }
            if currentGroupType = "Relative" {
                return relativeGroups
            }
            return primaryGroups
        }

        DefaultGroupName(groupType, index) {
            return groupType " Group " index
        }

        UpdatePatternStats() {
            lines := StrSplit(patternEdit.Value, "`n", "`r")
            nonEmptyCount := 0
            for _, line in lines {
                if Trim(line) != "" {
                    nonEmptyCount += 1
                }
            }
            lineCount := patternEdit.Value = "" ? 0 : lines.Length
            patternStatsText.Text := "Lines: " lineCount " | Active patterns: " nonEmptyCount
        }

        SaveCurrentGroup() {
            groups := CurrentGroups()
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
            groupName := Trim(groupNameEdit.Value)
            if groupName = "" {
                groupName := DefaultGroupName(currentGroupType, currentIndex)
            }
            groups[currentIndex]["name"] := groupName
            groups[currentIndex]["patterns"] := cleaned
        }

        RefreshGroupList(selectIndex := 1) {
            isRefreshing := true
            groups := CurrentGroups()
            entries := []
            for index, group in groups {
                entries.Push(group["name"] " (" group["patterns"].Length " patterns)")
            }
            groupList.Delete()
            groupList.Add(entries)
            if groups.Length > 0 {
                selectIndex := Min(Max(selectIndex, 1), groups.Length)
                groupList.Choose(selectIndex)
                currentIndex := selectIndex
                groupNameEdit.Value := groups[selectIndex]["name"]
                patternEdit.Value := ProfileOverridesGui.JoinLines(groups[selectIndex]["patterns"])
            } else {
                currentIndex := 0
                groupNameEdit.Value := ""
                patternEdit.Value := ""
            }
            UpdatePatternStats()
            isRefreshing := false
        }

        OnGroupTypeChange(*) {
            if isRefreshing {
                return
            }
            SaveCurrentGroup()
            currentGroupType := groupTypePicker.Text
            currentIndex := 1
            RefreshGroupList(1)
        }

        OnGroupChange(*) {
            if isRefreshing {
                return
            }
            SaveCurrentGroup()
            groups := CurrentGroups()
            nextIndex := groupList.Value
            if nextIndex < 1 || nextIndex > groups.Length {
                return
            }
            currentIndex := nextIndex
            RefreshGroupList(currentIndex)
        }

        OnAddGroup(*) {
            SaveCurrentGroup()
            groups := CurrentGroups()
            groups.Push(Map("name", DefaultGroupName(currentGroupType, groups.Length + 1), "patterns", []))
            RefreshGroupList(groups.Length)
            groupNameEdit.Focus()
        }

        OnRemoveGroup(*) {
            groups := CurrentGroups()
            if groups.Length = 0 {
                return
            }
            SaveCurrentGroup()
            groups.RemoveAt(currentIndex)
            if groups.Length = 0 {
                groupNameEdit.Value := ""
                patternEdit.Value := ""
                currentIndex := 0
                RefreshGroupList(1)
                return
            }
            RefreshGroupList(Min(currentIndex, groups.Length))
        }

        OnSave(*) {
            SaveCurrentGroup()
            activeSet["affixGroups"] := this.CloneGroups(primaryGroups)
            activeSet["secondaryAffixGroups"] := this.CloneGroups(secondaryGroups)
            activeSet["relativeAffixGroups"] := this.CloneGroups(relativeGroups)
            profile["groupSets"][profile["activeGroupSetIndex"]] := activeSet
            ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
            ProfileOverrides.SaveProfileGroupSets(this.settings["iniPath"], profile)
            this.logger.Log("INFO", "profile_affixgroups_saved", Map("profile", profile["id"], "primaryGroupCount", primaryGroups.Length, "secondaryGroupCount", secondaryGroups.Length, "relativeGroupCount", relativeGroups.Length))
            this.UpdateStatus("Affix groups saved for " profile["name"] ".")
            editor.Destroy()
            this.RefreshAllViews()
            MsgBox("Primary, secondary, and relative affix groups saved for " profile["name"] ".")
        }

        OnCancel(*) {
            editor.Destroy()
        }

        groupTypePicker.OnEvent("Change", (*) => OnGroupTypeChange())
        groupList.OnEvent("Change", (*) => OnGroupChange())
        patternEdit.OnEvent("Change", (*) => UpdatePatternStats())
        addGroupButton.OnEvent("Click", (*) => OnAddGroup())
        removeGroupButton.OnEvent("Click", (*) => OnRemoveGroup())
        saveButton.OnEvent("Click", (*) => OnSave())
        cancelButton.OnEvent("Click", (*) => OnCancel())
        editor.OnEvent("Close", (*) => OnCancel())
        editor.OnEvent("Size", OnEditorResize)

        groupTypePicker.Choose(1)
        RefreshGroupList(1)
        editor.Show("w820 h620")

        OnEditorResize(guiObj, minMax, width, height) {
            if minMax = -1 {
                return
            }

            currentWidth := Max(width, baseWidth)
            currentHeight := Max(height, baseHeight)
            extraWidth := currentWidth - baseWidth
            extraHeight := currentHeight - baseHeight

            currentRightW := rightW + extraWidth
            currentButtonsY := buttonsY + extraHeight
            currentListH := listH + extraHeight
            currentPatternH := patternH + extraHeight

            groupList.Move(listX, listY, listW, currentListH)
            groupNameEdit.Move(rightX, nameEditY, currentRightW)
            patternStatsText.Move(patternStatsX + extraWidth, patternsLabelY, 340)
            patternEdit.Move(rightX, patternsEditY, currentRightW, currentPatternH)
            addGroupButton.Move(listX, currentButtonsY, buttonW)
            removeGroupButton.Move(listX + buttonW + buttonGap, currentButtonsY, buttonW)
            saveButton.Move(rightX + currentRightW - 110 - 120, currentButtonsY, 110)
            cancelButton.Move(rightX + currentRightW - 110, currentButtonsY, 110)
        }
    }

    CloneGroups(groups) {
        clone := []
        for _, group in groups {
            nextPatterns := []
            if group is Map {
                patterns := group["patterns"]
                groupName := group["name"]
            } else {
                patterns := group
                groupName := "Primary Group " (clone.Length + 1)
            }
            for _, pattern in patterns {
                nextPatterns.Push(pattern)
            }
            clone.Push(Map("name", groupName, "patterns", nextPatterns))
        }
        return clone
    }

    ActiveGroupSet(profile) {
        return ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
    }

    ActiveGroupSetName(profile) {
        activeSet := this.ActiveGroupSet(profile)
        return activeSet["name"]
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
        this.ReloadSettingsModel()
        this.UpdateStatus("Coordinates updated for " StrReplace(keys[1], "_X") ".")
        this.RefreshAllViews()
        this.logger.Log("INFO", "coordinate_saved", Map("key", key, "x", x, "y", y))
        MsgBox("Coordinates saved to setting.ini")
    }

    SaveCoordinatesFromForm() {
        for _, item in this.coordinateKeys {
            keyX := item[2]
            keyY := item[3]
            valueX := Trim(this.controls["coordinateEdits"][keyX].Value)
            valueY := Trim(this.controls["coordinateEdits"][keyY].Value)
            if !RegExMatch(valueX, "^-?\d+$") || !RegExMatch(valueY, "^-?\d+$") {
                MsgBox("Coordinates for " item[1] " must be whole numbers.")
                return
            }
            SettingsLoader.SaveCoordinate(this.settings["iniPath"], keyX, keyY, valueX + 0, valueY + 0)
        }

        this.ReloadSettingsModel()
        this.UpdateStatus("Coordinates saved from the dashboard.")
        this.RefreshAllViews()
        this.controls["coordinateStatus"].Text := "Saved to " this.settings["iniPath"]
    }

    ReloadSettingsFromDisk() {
        this.ReloadSettingsModel()
        this.UpdateStatus("Settings reloaded from disk.")
        this.RefreshAllViews()
        this.controls["coordinateStatus"].Text := "Reloaded from " this.settings["iniPath"]
    }

    ReloadSettingsModel() {
        this.settings := SettingsLoader.Load(this.baseDir)
        this.client := PoeClient(this.settings, this.logger)
    }

    RefreshAllViews() {
        if !IsObject(this.mainGui) {
            return
        }
        this.RefreshHomeTab()
        this.RefreshProfileList()
        this.RefreshCoordinateForm()
        this.RefreshLogPreview()
    }

    RefreshHomeTab() {
        profile := this.profiles[this.activeProfileId]
        this.controls["homeProfileValue"].Text := profile["name"]
        this.controls["homeProfileMeta"].Text := "Type: " profile["type"] "`r`nSet: " this.ActiveGroupSetName(profile) " | Primary groups: " profile["affixGroups"].Length
        this.controls["homeStatusValue"].Text := this.HomeStatusTitle()
        this.controls["homeStatusMeta"].Text := this.runStatus
        this.controls["homeStopRuleValue"].Text := this.StopRuleSummary(profile)
        this.controls["homeStopRuleMeta"].Text := this.StopRuleTargets(profile)
        guideText := [
            ["F4", "Start the active profile while focused on Path of Exile."],
            ["F7", "Capture the current mouse position into setting.ini."],
            ["F8", "Open the profile picker."],
            ["F9", "Bring this dashboard back to the front."],
            ["F10", "Edit the active set's primary affix groups."],
            ["F12", "Request stop during a running loop."]
        ]

        loop guideText.Length {
            this.controls["homeGuideKeys"][A_Index].Text := guideText[A_Index][1]
            this.controls["homeGuideTexts"][A_Index].Text := guideText[A_Index][2]
        }
    }

    RefreshProfileList() {
        if !this.controls.Has("profileList") {
            return
        }

        listView := this.controls["profileList"]
        focusedRow := listView.GetNext(0, "F")
        selectedProfileId := focusedRow && this.profileRowToId.Has(focusedRow) ? this.profileRowToId[focusedRow] : this.activeProfileId

        listView.Delete()
        this.profileRowToId := Map()
        selectedRow := 1
        rowIndex := 0

        for profileId, profile in this.profiles {
            rowIndex += 1
            row := listView.Add("", profile["name"], this.TargetText(profile), this.ActiveGroupSetName(profile), this.AffixGroupSummary(profile))
            this.profileRowToId[row] := profileId
            if profileId = selectedProfileId {
                selectedRow := row
            }
        }

        if rowIndex > 0 {
            listView.Modify(selectedRow, "Select Focus Vis")
        }
        this.RefreshSelectedProfileSetPicker()
        this.UpdateSelectedProfileDetails()
    }

    RefreshSelectedProfileSetPicker() {
        if !this.controls.Has("profileSetPicker") {
            return
        }

        profile := this.GetSelectedProfile()
        picker := this.controls["profileSetPicker"]
        picker.Delete()
        if !IsObject(profile) {
            return
        }

        names := []
        for _, groupSet in profile["groupSets"] {
            names.Push(groupSet["name"])
        }
        picker.Add(names)
        picker.Choose(profile["activeGroupSetIndex"])
        this.RefreshSelectedProfileTargetControls(profile)
    }

    UpdateSelectedProfileDetails() {
        if !this.controls.Has("profileList") {
            return
        }
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            return
        }
        setIndex := this.SelectedSetIndex(profile)
        previewSet := ProfileRegistry.NormalizeGroupSet(profile["groupSets"][setIndex], "Set " setIndex)
        detailText := ""
        if profile["id"] = this.activeProfileId {
            detailText := "This is the active profile."
            if setIndex = profile["activeGroupSetIndex"] {
                detailText .= " This set is active."
            } else {
                detailText .= " Active set: " this.ActiveGroupSetName(profile) "."
            }
            detailText .= "`r`n`r`n"
        }
        detailText .=
        (
            "Primary affix groups: " previewSet["affixGroups"].Length "`r`n"
            . "Secondary affix groups: " previewSet["secondaryAffixGroups"].Length "`r`n"
            . "Relative affix groups: " previewSet["relativeAffixGroups"].Length "`r`n"
            . "Skip augment on relative match: " (profile["skipAugmentationWhenRelativeMatch"] ? "On" : "Off") "`r`n"
            . "Clipboard delay: " profile["clipboardDelay"] " ms"
        )
        this.controls["profileDetails"].Value := detailText
        this.RefreshSelectedProfileTargetControls(profile)
    }

    RefreshCoordinateForm() {
        if !this.controls.Has("coordinateEdits") {
            return
        }
        for _, item in this.coordinateKeys {
            keyX := item[2]
            keyY := item[3]
            this.controls["coordinateEdits"][keyX].Value := this.settings[keyX]
            this.controls["coordinateEdits"][keyY].Value := this.settings[keyY]
        }
        this.controls["coordinateStatus"].Text := "Editing values from " this.settings["iniPath"]
    }

    RefreshLogPreview() {
        if !this.controls.Has("logPreview") {
            return
        }
        this.controls["logPath"].Text := "Log file: " this.settings["logFile"]
        this.controls["logPreview"].Value := this.ReadLogPreview()
    }

    ReadLogPreview(maxLines := 40, maxChars := 6000) {
        if !FileExist(this.settings["logFile"]) {
            return "Log file not found yet. Run a profile or wait for the first log write."
        }

        try {
            text := FileRead(this.settings["logFile"], "UTF-8")
        } catch as err {
            return "Unable to read log file.`r`n" err.Message
        }

        if StrLen(text) > maxChars {
            text := SubStr(text, StrLen(text) - maxChars + 1)
        }

        lines := StrSplit(text, "`n", "`r")
        if lines.Length > maxLines {
            startIndex := lines.Length - maxLines + 1
            preview := ""
            loop maxLines {
                if A_Index > 1 {
                    preview .= "`r`n"
                }
                preview .= lines[startIndex + A_Index - 1]
            }
            return preview
        }
        return text
    }

    UpdateStatus(statusText) {
        this.runStatus := statusText
        if this.controls.Has("homeStatusValue") {
            this.controls["homeStatusValue"].Text := this.HomeStatusTitle()
        }
        if this.controls.Has("homeStatusMeta") {
            this.controls["homeStatusMeta"].Text := this.runStatus
        }
    }

    HomeStatusTitle() {
        status := StrLower(this.runStatus)
        if InStr(status, "running") {
            return "Running"
        }
        if InStr(status, "failed") {
            return "Needs Attention"
        }
        if InStr(status, "stop requested") {
            return "Stopping"
        }
        if InStr(status, "completed") {
            return "Completed"
        }
        return "Ready"
    }

    TargetText(profile) {
        text := "Primary " profile["targetAffixNum"]
        if profile["targetSecondAffixNum"] > 0 {
            text .= " / Secondary " profile["targetSecondAffixNum"]
        }
        return text
    }

    TargetEditable(profile) {
        type := profile["type"]
        return type != "alteration" && type != "alterationAugment"
    }

    SecondaryTargetEditable(profile) {
        return this.TargetEditable(profile) && profile["secondaryAffixGroups"].Length > 0
    }

    RelativeSkipEditable(profile) {
        return profile["type"] = "alterationAugment" && profile["relativeAffixGroups"].Length > 0
    }

    RefreshSelectedProfileTargetControls(profile := "") {
        if !this.controls.Has("profilePrimaryTargetEdit") {
            return
        }

        primaryEdit := this.controls["profilePrimaryTargetEdit"]
        secondaryEdit := this.controls["profileSecondaryTargetEdit"]
        relativeSkipCheckbox := this.controls["profileRelativeSkipCheckbox"]
        hint := this.controls["profileTargetHint"]
        if !IsObject(profile) {
            primaryEdit.Value := ""
            secondaryEdit.Value := ""
            primaryEdit.Opt("+Disabled")
            secondaryEdit.Opt("+Disabled")
            relativeSkipCheckbox.Value := 0
            relativeSkipCheckbox.Opt("+Disabled")
            hint.Text := ""
            return
        }

        primaryEdit.Value := profile["targetAffixNum"]
        secondaryEdit.Value := profile["targetSecondAffixNum"]
        relativeSkipCheckbox.Value := profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0

        if this.TargetEditable(profile) {
            primaryEdit.Opt("-Disabled")
            if this.SecondaryTargetEditable(profile) {
                secondaryEdit.Opt("-Disabled")
                hint.Text := "Target values are configurable for this profile."
            } else {
                secondaryEdit.Opt("+Disabled")
                hint.Text := "Only the primary target is configurable for this profile."
            }
        } else {
            primaryEdit.Opt("+Disabled")
            secondaryEdit.Opt("+Disabled")
            hint.Text := "This profile's target is fixed because its crafting flow depends on it."
        }

        if this.RelativeSkipEditable(profile) {
            relativeSkipCheckbox.Opt("-Disabled")
            if hint.Text = "" {
                hint.Text := "Relative-match behavior is configurable for this profile."
            } else {
                hint.Text .= " Relative-match behavior is also configurable."
            }
        } else {
            relativeSkipCheckbox.Opt("+Disabled")
        }
    }

    SaveSelectedProfileTargets() {
        profile := this.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }
        targetEditable := this.TargetEditable(profile)
        relativeEditable := this.RelativeSkipEditable(profile)
        if !targetEditable && !relativeEditable {
            MsgBox("This profile does not have editable target or relative-match behavior.")
            return
        }

        primaryTarget := profile["targetAffixNum"]
        secondaryTarget := profile["targetSecondAffixNum"]
        if targetEditable {
            primaryValue := Trim(this.controls["profilePrimaryTargetEdit"].Value)
            secondaryValue := Trim(this.controls["profileSecondaryTargetEdit"].Value)
            if !RegExMatch(primaryValue, "^\d+$") {
                MsgBox("Primary target must be a whole number.")
                return
            }
            if secondaryValue = "" {
                secondaryValue := "0"
            }
            if !RegExMatch(secondaryValue, "^\d+$") {
                MsgBox("Secondary target must be a whole number.")
                return
            }

            primaryTarget := primaryValue + 0
            secondaryTarget := secondaryValue + 0
            if primaryTarget < 1 || primaryTarget > 3 {
                MsgBox("Primary target must be between 1 and 3.")
                return
            }
            if secondaryTarget < 0 || secondaryTarget > 3 {
                MsgBox("Secondary target must be between 0 and 3.")
                return
            }
            if !this.SecondaryTargetEditable(profile) {
                secondaryTarget := 0
            }
        }

        profile["targetAffixNum"] := primaryTarget
        profile["targetSecondAffixNum"] := secondaryTarget
        ProfileOverrides.SaveTargetOverrides(this.settings["iniPath"], profile)
        if relativeEditable {
            profile["skipAugmentationWhenRelativeMatch"] := this.controls["profileRelativeSkipCheckbox"].Value = 1
            ProfileOverrides.SaveBehaviorOverrides(this.settings["iniPath"], profile)
        }
        this.logger.Log("INFO", "profile_targets_saved", Map("profile", profile["id"], "targetAffixNum", primaryTarget, "targetSecondAffixNum", secondaryTarget, "skipAugmentationWhenRelativeMatch", profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0))
        this.UpdateStatus("Profile rules updated for " profile["name"] ".")
        this.RefreshAllViews()
    }

    StopRuleSummary(profile) {
        summary := profile["targetAffixNum"] " Primary"
        if profile["targetSecondAffixNum"] > 0 {
            summary .= " + " profile["targetSecondAffixNum"] " Secondary"
        }
        return summary
    }

    StopRuleTargets(profile, separator := "`r`n") {
        parts := []
        primaryNames := this.GroupNameList(profile["affixGroups"])
        if primaryNames != "" {
            parts.Push("Primary: " primaryNames)
        }

        secondaryNames := this.GroupNameList(profile["secondaryAffixGroups"])
        if secondaryNames != "" {
            parts.Push("Secondary: " secondaryNames)
        }

        if parts.Length = 0 {
            return "No named target groups configured."
        }

        text := ""
        for index, part in parts {
            if index > 1 {
                text .= separator
            }
            text .= part
        }
        return text
    }

    AffixGroupSummary(profile, separator := " | ") {
        return this.AffixGroupSummaryForSet(this.ActiveGroupSet(profile), separator)
    }

    AffixGroupSummaryForSet(groupSet, separator := " | ") {
        parts := []

        primaryNames := this.GroupNameList(groupSet["affixGroups"])
        if primaryNames != "" {
            parts.Push("P: " primaryNames)
        }

        secondaryNames := this.GroupNameList(groupSet["secondaryAffixGroups"])
        if secondaryNames != "" {
            parts.Push("S: " secondaryNames)
        }

        relativeNames := this.GroupNameList(groupSet["relativeAffixGroups"])
        if relativeNames != "" {
            parts.Push("R: " relativeNames)
        }

        if parts.Length = 0 {
            return "-"
        }

        text := ""
        for index, part in parts {
            if index > 1 {
                text .= separator
            }
            text .= part
        }
        return text
    }

    GroupNameList(groups) {
        if !IsObject(groups) || groups.Length = 0 {
            return ""
        }

        names := ""
        for index, group in groups {
            groupName := group is Map ? group["name"] : "Group " index
            if Trim(groupName) = "" {
                groupName := "Group " index
            }
            if names != "" {
                names .= ", "
            }
            names .= groupName
        }
        return names
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
