class SettingsLoader {
    static Load(baseDir) {
        iniPath := baseDir "\setting.ini"
        logPath := SettingsLoader.Read(iniPath, "coordinate", "logFile", baseDir "\log_affix_v2.txt")
        if !InStr(logPath, "\") {
            logPath := baseDir "\" logPath
        }

        return Map(
            "baseDir", baseDir,
            "iniPath", iniPath,
            "logFile", logPath,
            "Alteration_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Alteration_X", 116),
            "Alteration_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Alteration_Y", 340),
            "Augmentation_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Augmentation_X", 233),
            "Augmentation_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Augmentation_Y", 391),
            "Scouring_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Scouring_X", 585),
            "Scouring_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Scouring_Y", 544),
            "Regal_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Regal_X", 430),
            "Regal_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Regal_Y", 336),
            "Transmutation_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Transmutation_X", 59),
            "Transmutation_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Transmutation_Y", 338),
            "Alchemy_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Alchemy_X", 662),
            "Alchemy_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Alchemy_Y", 380),
            "Chaos_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Chaos_X", 725),
            "Chaos_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Chaos_Y", 373),
            "Essence_X", SettingsLoader.ReadInt(iniPath, "coordinate", "Essence_X", 68),
            "Essence_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "Essence_Y", 313),
            "CraftingButton_X", SettingsLoader.ReadInt(iniPath, "coordinate", "CraftingButton_X", 1260),
            "CraftingButton_Y", SettingsLoader.ReadInt(iniPath, "coordinate", "CraftingButton_Y", 810)
        )
    }

    static SaveCoordinate(iniPath, keyX, keyY, x, y) {
        IniWrite(x, iniPath, "coordinate", keyX)
        IniWrite(y, iniPath, "coordinate", keyY)
    }

    static Read(iniPath, section, key, defaultValue) {
        try {
            return IniRead(iniPath, section, key, defaultValue)
        } catch {
            return defaultValue
        }
    }

    static ReadInt(iniPath, section, key, defaultValue) {
        return Round(SettingsLoader.Read(iniPath, section, key, defaultValue) + 0)
    }
}
