class DashboardController {
    static RefreshHomeTab(app) {
        if !app.profiles.Has(app.activeProfileId) {
            app.controls["homeProfileValue"].Text := "No Active Profile"
            app.controls["homeProfileMeta"].Text := "Load or create a valid profile configuration."
            app.controls["homeStatusValue"].Text := ProfilePresenter.HomeStatusTitle(app.runStatus)
            app.controls["homeStatusMeta"].Text := app.runStatus
            app.controls["homeStopRuleValue"].Text := "Unavailable"
            app.controls["homeStopRuleMeta"].Text := "No valid active profile is currently loaded."
            return
        }

        profile := app.profiles[app.activeProfileId]
        app.controls["homeProfileValue"].Text := profile["name"]
        app.controls["homeProfileMeta"].Text := "Type: " profile["type"] "`r`nSet: " app.ActiveGroupSetName(profile) " | Primary groups: " profile["affixGroups"].Length
        app.controls["homeStatusValue"].Text := ProfilePresenter.HomeStatusTitle(app.runStatus)
        app.controls["homeStatusMeta"].Text := app.runStatus
        app.controls["homeStopRuleValue"].Text := ProfilePresenter.StopRuleSummary(profile)
        app.controls["homeStopRuleMeta"].Text := ProfilePresenter.StopRuleTargets(profile)

        guideText := [
            ["F4", "Start the active profile while focused on Path of Exile."],
            ["F7", "Capture the current mouse position into settings.json."],
            ["F8", "Open the profile picker."],
            ["F9", "Bring this dashboard back to the front."],
            ["F10", "Edit the active set's primary affix groups."],
            ["F12", "Request stop during a running loop."]
        ]

        loop guideText.Length {
            app.controls["homeGuideKeys"][A_Index].Text := guideText[A_Index][1]
            app.controls["homeGuideTexts"][A_Index].Text := guideText[A_Index][2]
        }
    }

    static RefreshLogPreview(app) {
        if !app.controls.Has("logPreview") {
            return
        }
        app.controls["logPath"].Text := "Log file: " app.settings["logFile"]
        app.controls["logPreview"].Value := LogPreviewReader.Read(app.settings["logFile"])
    }
}
