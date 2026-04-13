class RunController {
    static StartActiveProfile(app) {
        if !app.profiles.Has(app.activeProfileId) {
            MsgBox("No active profile is available.")
            return
        }

        app.stopRequested := false
        profile := app.profiles[app.activeProfileId]
        app.UpdateStatus("Running profile " profile["name"] ". Press F12 or Stop to request a halt.")
        app.RefreshAllViews()

        try {
            engine := CraftingEngine(profile, app.client, app.matcher, app.logger, app)
            engine.Run()
            app.logger.CheckSize()
            if app.stopRequested {
                app.UpdateStatus("Stop requested. Review the item and log before the next run.")
            } else {
                app.UpdateStatus("Profile run completed for " profile["name"] ".")
            }
        } catch as err {
            app.logger.LogError("profile_failed", err, Map("profile", profile["id"]))
            app.UpdateStatus("Run failed. Check the log for details.")
            MsgBox("An error occurred during execution. See the log file for details.`r`n`r`n" err.Message)
        } finally {
            app.client.ResetHeldCurrency()
            Send("{LShift Up}")
            app.RefreshAllViews()
        }
    }

    static RequestStop(app) {
        app.stopRequested := true
        app.logger.Log("INFO", "stop_requested")
        app.UpdateStatus("Stop requested. The current loop will halt after the in-flight step.")
        app.RefreshAllViews()
    }
}
