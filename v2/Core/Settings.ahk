class SettingsLoader {
    static Load(baseDir) {
        settingsPath := baseDir "\v2\profiles\user\settings.json"
        defaultLogPath := baseDir "\log_affix_v2.txt"
        defaults := Map(
            "schemaVersion", 1,
            "logFile", defaultLogPath,
            "coordinates", Map(
                "Alteration_X", 148,
                "Alteration_Y", 371,
                "Augmentation_X", 301,
                "Augmentation_Y", 446,
                "Scouring_X", 585,
                "Scouring_Y", 544,
                "Regal_X", 574,
                "Regal_Y", 367,
                "Transmutation_X", 71,
                "Transmutation_Y", 370,
                "Alchemy_X", 654,
                "Alchemy_Y", 375,
                "Chaos_X", 733,
                "Chaos_Y", 375,
                "Essence_X", 68,
                "Essence_Y", 313,
                "CraftingButton_X", 1260,
                "CraftingButton_Y", 810
            )
        )

        data := defaults
        if FileExist(settingsPath) {
            loaded := JsonData.LoadFile(settingsPath)
            data := SettingsLoader.MergeSettings(defaults, loaded, baseDir)
        }

        coordinates := data["coordinates"]
        return Map(
            "baseDir", baseDir,
            "settingsPath", settingsPath,
            "profileOverridesPath", baseDir "\v2\profiles\user\overrides.json",
            "profileGroupSetsPath", baseDir "\v2\profiles\user\profile_sets.json",
            "logFile", data["logFile"],
            "Alteration_X", coordinates["Alteration_X"],
            "Alteration_Y", coordinates["Alteration_Y"],
            "Augmentation_X", coordinates["Augmentation_X"],
            "Augmentation_Y", coordinates["Augmentation_Y"],
            "Scouring_X", coordinates["Scouring_X"],
            "Scouring_Y", coordinates["Scouring_Y"],
            "Regal_X", coordinates["Regal_X"],
            "Regal_Y", coordinates["Regal_Y"],
            "Transmutation_X", coordinates["Transmutation_X"],
            "Transmutation_Y", coordinates["Transmutation_Y"],
            "Alchemy_X", coordinates["Alchemy_X"],
            "Alchemy_Y", coordinates["Alchemy_Y"],
            "Chaos_X", coordinates["Chaos_X"],
            "Chaos_Y", coordinates["Chaos_Y"],
            "Essence_X", coordinates["Essence_X"],
            "Essence_Y", coordinates["Essence_Y"],
            "CraftingButton_X", coordinates["CraftingButton_X"],
            "CraftingButton_Y", coordinates["CraftingButton_Y"]
        )
    }

    static SaveCoordinate(settingsPath, keyX, keyY, x, y, baseDir := "") {
        document := SettingsLoader.LoadDocument(settingsPath, baseDir)
        document["coordinates"][keyX] := x
        document["coordinates"][keyY] := y
        JsonData.SaveFile(settingsPath, document)
    }

    static LoadDocument(settingsPath, baseDir := "") {
        if FileExist(settingsPath) {
            loaded := JsonData.LoadFile(settingsPath)
            defaults := SettingsLoader.Load(baseDir != "" ? baseDir : SettingsLoader.BaseDirFromSettingsPath(settingsPath))
            return SettingsLoader.DocumentFromSettingsMap(defaults, loaded)
        }

        rootDir := baseDir != "" ? baseDir : SettingsLoader.BaseDirFromSettingsPath(settingsPath)
        return Map(
            "schemaVersion", 1,
            "logFile", rootDir "\log_affix_v2.txt",
            "coordinates", Map(
                "Alteration_X", 116,
                "Alteration_Y", 340,
                "Augmentation_X", 233,
                "Augmentation_Y", 391,
                "Scouring_X", 585,
                "Scouring_Y", 544,
                "Regal_X", 430,
                "Regal_Y", 336,
                "Transmutation_X", 59,
                "Transmutation_Y", 338,
                "Alchemy_X", 662,
                "Alchemy_Y", 380,
                "Chaos_X", 725,
                "Chaos_Y", 373,
                "Essence_X", 68,
                "Essence_Y", 313,
                "CraftingButton_X", 1260,
                "CraftingButton_Y", 810
            )
        )
    }

    static MergeSettings(defaults, loaded, baseDir) {
        data := Map(
            "schemaVersion", 1,
            "logFile", defaults["logFile"],
            "coordinates", Map()
        )
        if loaded is Map && loaded.Has("logFile") {
            logPath := loaded["logFile"]
            if !InStr(logPath, "\") && baseDir != "" {
                logPath := baseDir "\" logPath
            }
            data["logFile"] := logPath
        }

        defaultCoordinates := defaults["coordinates"]
        loadedCoordinates := loaded is Map && loaded.Has("coordinates") && loaded["coordinates"] is Map ? loaded["coordinates"] : Map()
        for key, value in defaultCoordinates {
            data["coordinates"][key] := loadedCoordinates.Has(key) ? loadedCoordinates[key] + 0 : value
        }
        return data
    }

    static DocumentFromSettingsMap(settingsMap, loaded := "") {
        document := Map(
            "schemaVersion", 1,
            "logFile", settingsMap["logFile"],
            "coordinates", Map()
        )
        coordinateKeys := [
            "Alteration_X", "Alteration_Y",
            "Augmentation_X", "Augmentation_Y",
            "Scouring_X", "Scouring_Y",
            "Regal_X", "Regal_Y",
            "Transmutation_X", "Transmutation_Y",
            "Alchemy_X", "Alchemy_Y",
            "Chaos_X", "Chaos_Y",
            "Essence_X", "Essence_Y",
            "CraftingButton_X", "CraftingButton_Y"
        ]
        for _, key in coordinateKeys {
            document["coordinates"][key] := settingsMap[key]
        }
        return loaded is Map ? SettingsLoader.MergeSettings(document, loaded, settingsMap["baseDir"]) : document
    }

    static BaseDirFromSettingsPath(settingsPath) {
        SplitPath(settingsPath, &fileName, &dirPath)
        return RegExReplace(dirPath, "\\v2\\profiles\\user$")
    }
}
