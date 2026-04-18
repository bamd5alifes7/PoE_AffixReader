class AppStateLoader {
    static ReloadSettingsModel(app) {
        app.settings := SettingsLoader.Load(app.baseDir)
        app.logger := AffixLogger(app.settings["logFile"])
        app.client := PoeClient(app.settings, app.logger)
    }

    static LoadProfilesModel(app) {
        previousProfileId := app.activeProfileId
        profiles := ProfileRegistry.Create(app.baseDir)
        ProfileGroupSets.Apply(app.settings["profileGroupSetsPath"], profiles, app.settings["profileOverridesPath"])
        ProfileOverrides.Apply(app.settings["profileOverridesPath"], profiles)
        validation := ProfileInputValidator.ValidateProfiles(profiles)
        if !validation["ok"] {
            throw Error(
                "Invalid regex found in profile '" validation["profileName"] "' / set '" validation["setName"] "' / "
                . validation["groupType"] " group '" validation["groupName"] "' line " validation["patternIndex"] ".`r`n`r`n"
                . validation["pattern"] "`r`n`r`n"
                . validation["message"]
            )
        }

        app.profiles := profiles
        if app.profiles.Has(previousProfileId) {
            app.activeProfileId := previousProfileId
            return
        }
        for profileId, _ in app.profiles {
            app.activeProfileId := profileId
            return
        }
        app.activeProfileId := ""
    }

    static ReloadFromDisk(app) {
        previousSettings := app.settings
        previousLogger := app.logger
        previousClient := app.client
        previousProfiles := app.profiles
        previousActiveProfileId := app.activeProfileId

        try {
            AppStateLoader.ReloadSettingsModel(app)
            AppStateLoader.LoadProfilesModel(app)
            app.UpdateStatus("Settings and profile overrides reloaded from disk.")
            app.RefreshAllViews()
            app.controls["coordinateStatus"].Text := "Reloaded from " app.settings["settingsPath"]
        } catch as err {
            app.settings := previousSettings
            app.logger := previousLogger
            app.client := previousClient
            app.profiles := previousProfiles
            app.activeProfileId := previousActiveProfileId
            app.logger.LogError("reload_failed", err)
            app.UpdateStatus("Reload failed. Fix the invalid settings or profile patterns and try again.")
            app.RefreshAllViews()
            MsgBox("Reload failed.`r`n`r`n" err.Message, "Reload Failed")
        }
    }
}
