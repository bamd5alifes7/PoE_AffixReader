class ProfileOverrides {
    static Apply(iniPath, profiles) {
        for id, profile in profiles {
            overrideGroups := ProfileOverrides.LoadAffixGroups(iniPath, id)
            if IsObject(overrideGroups) {
                profile["affixGroups"] := overrideGroups
            }
        }
    }

    static LoadAffixGroups(iniPath, profileId) {
        section := ProfileOverrides.SectionName(profileId)
        groupCount := SettingsLoader.ReadInt(iniPath, section, "groupCount", -1)
        if groupCount < 0 {
            return ""
        }

        groups := []
        loop groupCount {
            groupIndex := A_Index
            patternCount := SettingsLoader.ReadInt(iniPath, section, "group" groupIndex "PatternCount", 0)
            group := []
            loop patternCount {
                pattern := SettingsLoader.Read(iniPath, section, "group" groupIndex "Pattern" A_Index, "")
                if pattern != "" {
                    group.Push(pattern)
                }
            }
            groups.Push(group)
        }
        return groups
    }

    static SaveAffixGroups(iniPath, profileId, groups) {
        section := ProfileOverrides.SectionName(profileId)
        ProfileOverrides.ClearSection(iniPath, section)
        IniWrite(groups.Length, iniPath, section, "groupCount")

        for groupIndex, group in groups {
            IniWrite(group.Length, iniPath, section, "group" groupIndex "PatternCount")
            for patternIndex, pattern in group {
                IniWrite(pattern, iniPath, section, "group" groupIndex "Pattern" patternIndex)
            }
        }
    }

    static SectionName(profileId) {
        return "profile_affixgroups_" profileId
    }

    static ClearSection(iniPath, section) {
        try {
            IniDelete(iniPath, section)
        } catch {
        }
    }
}
