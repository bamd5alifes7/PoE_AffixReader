class ProfilePanelController {
    static RefreshProfileList(app) {
        if !app.controls.Has("profileList") {
            return
        }

        listView := app.controls["profileList"]
        focusedRow := listView.GetNext(0, "F")
        selectedProfileId := focusedRow && app.profileRowToId.Has(focusedRow) ? app.profileRowToId[focusedRow] : app.activeProfileId

        listView.Delete()
        app.profileRowToId := Map()
        selectedRow := 1
        rowIndex := 0

        for profileId, profile in app.profiles {
            rowIndex += 1
            row := listView.Add("", profile["name"], ProfilePresenter.TargetText(profile), app.ActiveGroupSetName(profile), ProfilePresenter.AffixGroupSummary(app.ActiveGroupSet(profile)))
            app.profileRowToId[row] := profileId
            if profileId = selectedProfileId {
                selectedRow := row
            }
        }

        if rowIndex > 0 {
            listView.Modify(selectedRow, "Select Focus Vis")
        }
        ProfilePanelController.RefreshSelectedProfileSetPicker(app)
        ProfilePanelController.UpdateSelectedProfileDetails(app)
    }

    static RefreshSelectedProfileSetPicker(app) {
        if !app.controls.Has("profileSetPicker") {
            return
        }

        profile := app.GetSelectedProfile()
        picker := app.controls["profileSetPicker"]
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
        ProfilePanelController.RefreshSelectedProfileTargetControls(app, profile)
    }

    static UpdateSelectedProfileDetails(app) {
        if !app.controls.Has("profileList") {
            return
        }
        profile := app.GetSelectedProfile()
        if !IsObject(profile) {
            return
        }
        setIndex := app.SelectedSetIndex(profile)
        previewSet := ProfileRegistry.NormalizeGroupSet(profile["groupSets"][setIndex], "Set " setIndex)
        app.controls["profileDetails"].Value := ProfilePresenter.ProfileDetails(
            profile,
            previewSet,
            profile["id"] = app.activeProfileId,
            setIndex = profile["activeGroupSetIndex"],
            app.ActiveGroupSetName(profile)
        )
        ProfilePanelController.RefreshSelectedProfileTargetControls(app, profile)
    }

    static RefreshSelectedProfileTargetControls(app, profile := "") {
        if !app.controls.Has("profilePrimaryTargetEdit") {
            return
        }

        primaryEdit := app.controls["profilePrimaryTargetEdit"]
        secondaryEdit := app.controls["profileSecondaryTargetEdit"]
        relativeSkipCheckbox := app.controls["profileRelativeSkipCheckbox"]
        augmentOnZeroCheckbox := app.controls["profileAugmentOnZeroCheckbox"]
        hint := app.controls["profileTargetHint"]
        if !IsObject(profile) {
            primaryEdit.Value := ""
            secondaryEdit.Value := ""
            primaryEdit.Opt("+Disabled")
            secondaryEdit.Opt("+Disabled")
            relativeSkipCheckbox.Value := 0
            relativeSkipCheckbox.Opt("+Disabled")
            augmentOnZeroCheckbox.Value := 0
            augmentOnZeroCheckbox.Opt("+Disabled")
            hint.Text := ""
            return
        }

        primaryEdit.Value := profile["targetAffixNum"]
        secondaryEdit.Value := profile["targetSecondAffixNum"]
        relativeSkipCheckbox.Value := profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0
        augmentOnZeroCheckbox.Value := profile["augmentOnZero"] ? 1 : 0
        capabilities := ProfileCapabilities.EditableSummary(profile)

        if capabilities["targetEditable"] {
            primaryEdit.Opt("-Disabled")
            if capabilities["secondaryTargetEditable"] {
                secondaryEdit.Opt("-Disabled")
            } else {
                secondaryEdit.Opt("+Disabled")
            }
        } else {
            primaryEdit.Opt("+Disabled")
            secondaryEdit.Opt("+Disabled")
        }

        if capabilities["relativeEditable"] {
            relativeSkipCheckbox.Opt("-Disabled")
        } else {
            relativeSkipCheckbox.Opt("+Disabled")
        }

        if capabilities["augmentEditable"] {
            augmentOnZeroCheckbox.Opt("-Disabled")
        } else {
            augmentOnZeroCheckbox.Opt("+Disabled")
        }
        hint.Text := ProfileCapabilities.TargetHint(profile)
    }

    static SaveSelectedProfileTargets(app) {
        profile := app.GetSelectedProfile()
        if !IsObject(profile) {
            MsgBox("Please select a profile first.")
            return
        }
        capabilities := ProfileCapabilities.EditableSummary(profile)
        targetEditable := capabilities["targetEditable"]
        relativeEditable := capabilities["relativeEditable"]
        augmentEditable := capabilities["augmentEditable"]
        if !targetEditable && !relativeEditable && !augmentEditable {
            MsgBox("This profile does not have editable target or behavior rules.")
            return
        }

        primaryTarget := profile["targetAffixNum"]
        secondaryTarget := profile["targetSecondAffixNum"]
        if targetEditable {
            targetValidation := ProfileInputValidator.ValidateTargetValues(
                app.controls["profilePrimaryTargetEdit"].Value,
                app.controls["profileSecondaryTargetEdit"].Value,
                capabilities["secondaryTargetEditable"]
            )
            if !targetValidation["ok"] {
                MsgBox(targetValidation["message"])
                return
            }
            primaryTarget := targetValidation["primaryTarget"]
            secondaryTarget := targetValidation["secondaryTarget"]
        }

        profile["targetAffixNum"] := primaryTarget
        profile["targetSecondAffixNum"] := secondaryTarget
        ProfileOverrides.SaveTargetOverrides(app.settings["profileOverridesPath"], profile)
        if augmentEditable {
            profile["augmentOnZero"] := app.controls["profileAugmentOnZeroCheckbox"].Value = 1
        }
        if relativeEditable {
            profile["skipAugmentationWhenRelativeMatch"] := app.controls["profileRelativeSkipCheckbox"].Value = 1
        }
        ProfileOverrides.SaveBehaviorOverrides(app.settings["profileOverridesPath"], profile)
        app.logger.Log("INFO", "profile_targets_saved", Map("profile", profile["id"], "targetAffixNum", primaryTarget, "targetSecondAffixNum", secondaryTarget, "skipAugmentationWhenRelativeMatch", profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0, "augmentOnZero", profile["augmentOnZero"] ? 1 : 0))
        app.UpdateStatus("Profile rules updated for " profile["name"] ".")
        app.RefreshAllViews()
    }
}
