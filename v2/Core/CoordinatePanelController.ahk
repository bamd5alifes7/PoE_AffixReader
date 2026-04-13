class CoordinatePanelController {
    static SaveCoordinatesTool(app) {
        if !app.client.EnsureWindowActive() {
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
        SettingsLoader.SaveCoordinate(app.settings["settingsPath"], keys[1], keys[2], x, y, app.baseDir)
        app.ReloadSettingsModel()
        app.UpdateStatus("Coordinates updated for " StrReplace(keys[1], "_X") ".")
        app.RefreshAllViews()
        app.logger.Log("INFO", "coordinate_saved", Map("key", key, "x", x, "y", y))
        MsgBox("Coordinates saved to settings.json")
    }

    static SaveCoordinatesFromForm(app) {
        for _, item in app.coordinateKeys {
            keyX := item[2]
            keyY := item[3]
            valueX := Trim(app.controls["coordinateEdits"][keyX].Value)
            valueY := Trim(app.controls["coordinateEdits"][keyY].Value)
            if !RegExMatch(valueX, "^-?\d+$") || !RegExMatch(valueY, "^-?\d+$") {
                MsgBox("Coordinates for " item[1] " must be whole numbers.")
                return
            }
            SettingsLoader.SaveCoordinate(app.settings["settingsPath"], keyX, keyY, valueX + 0, valueY + 0, app.baseDir)
        }

        app.ReloadSettingsModel()
        app.UpdateStatus("Coordinates saved from the dashboard.")
        app.RefreshAllViews()
        app.controls["coordinateStatus"].Text := "Saved to " app.settings["settingsPath"]
    }

    static RefreshCoordinateForm(app) {
        if !app.controls.Has("coordinateEdits") {
            return
        }
        for _, item in app.coordinateKeys {
            keyX := item[2]
            keyY := item[3]
            app.controls["coordinateEdits"][keyX].Value := app.settings[keyX]
            app.controls["coordinateEdits"][keyY].Value := app.settings[keyY]
        }
        app.controls["coordinateStatus"].Text := "Editing values from " app.settings["settingsPath"]
    }
}
