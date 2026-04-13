class ProfileOverrides {
    static Apply(iniPath, profiles) {
        for id, profile in profiles {
            groupSets := ProfileOverrides.LoadGroupSets(iniPath, profile)
            if IsObject(groupSets) && groupSets.Length > 0 {
                profile["groupSets"] := groupSets
            } else {
                legacyGroups := ProfileOverrides.LoadAffixGroups(iniPath, id, 1)
                if IsObject(legacyGroups) {
                    activeSet := ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
                    activeSet["affixGroups"] := legacyGroups
                    profile["groupSets"][profile["activeGroupSetIndex"]] := activeSet
                }
            }

            ProfileOverrides.LoadTargetOverrides(iniPath, profile)
            ProfileOverrides.LoadBehaviorOverrides(iniPath, profile)
            activeIndex := ProfileOverrides.LoadActiveGroupSetIndex(iniPath, id)
            ProfileRegistry.ActivateGroupSet(profile, activeIndex)
        }
    }

    static LoadGroupSets(iniPath, profile) {
        section := ProfileOverrides.GroupSetSectionName(profile["id"])
        setCount := SettingsLoader.ReadInt(iniPath, section, "setCount", -1)
        if setCount < 0 {
            return ""
        }

        existingSets := profile.Has("groupSets") ? profile["groupSets"] : []
        groupSets := []
        loop setCount {
            setIndex := A_Index
            fallbackName := ProfileRegistry.GroupSetFallbackName(profile, setIndex)
            if IsObject(existingSets) && setIndex <= existingSets.Length {
                defaultSet := ProfileRegistry.NormalizeGroupSet(existingSets[setIndex], fallbackName)
            } else {
                defaultSet := ProfileRegistry.DefaultGroupSet(profile)
            }
            setName := SettingsLoader.Read(iniPath, section, "set" setIndex "Name", defaultSet["name"])
            if setIndex = 1 && Trim(setName) = "Default" {
                setName := ProfileRegistry.DefaultGroupSetName(profile)
            }
            overrideGroups := ProfileOverrides.LoadAffixGroups(iniPath, profile["id"], setIndex)
            nextSet := Map(
                "name", setName,
                "affixGroups", IsObject(overrideGroups) ? overrideGroups : defaultSet["affixGroups"],
                "secondaryAffixGroups", ProfileOverrides.LoadSecondaryAffixGroups(iniPath, profile["id"], setIndex, defaultSet["secondaryAffixGroups"]),
                "relativeAffixGroups", ProfileOverrides.LoadRelativeAffixGroups(iniPath, profile["id"], setIndex, defaultSet["relativeAffixGroups"])
            )
            groupSets.Push(ProfileRegistry.NormalizeGroupSet(nextSet, fallbackName))
        }
        return groupSets
    }

    static LoadActiveGroupSetIndex(iniPath, profileId) {
        section := ProfileOverrides.GroupSetSectionName(profileId)
        setIndex := SettingsLoader.ReadInt(iniPath, section, "activeSetIndex", -1)
        if setIndex > 0 {
            return setIndex
        }
        return 1
    }

    static LoadAffixGroups(iniPath, profileId, setIndex := 1) {
        section := ProfileOverrides.AffixSectionName(profileId, setIndex)
        groupCount := SettingsLoader.ReadInt(iniPath, section, "groupCount", -1)
        if groupCount < 0 && setIndex = 1 {
            legacySection := ProfileOverrides.LegacyAffixSectionName(profileId)
            groupCount := SettingsLoader.ReadInt(iniPath, legacySection, "groupCount", -1)
            if groupCount >= 0 {
                section := legacySection
            }
        }
        if groupCount < 0 {
            return ""
        }

        groups := []
        loop groupCount {
            groupIndex := A_Index
            patternCount := SettingsLoader.ReadInt(iniPath, section, "group" groupIndex "PatternCount", 0)
            groupName := SettingsLoader.Read(iniPath, section, "group" groupIndex "Name", "Primary Group " groupIndex)
            patterns := []
            loop patternCount {
                pattern := SettingsLoader.Read(iniPath, section, "group" groupIndex "Pattern" A_Index, "")
                if pattern != "" {
                    patterns.Push(pattern)
                }
            }
            groups.Push(Map("name", groupName, "patterns", patterns))
        }
        return groups
    }

    static SaveProfileGroupSets(iniPath, profile) {
        section := ProfileOverrides.GroupSetSectionName(profile["id"])
        oldCount := SettingsLoader.ReadInt(iniPath, section, "setCount", 0)
        maxCount := Max(oldCount, profile["groupSets"].Length)

        ProfileOverrides.ClearSection(iniPath, section)
        loop maxCount {
            ProfileOverrides.ClearSection(iniPath, ProfileOverrides.AffixSectionName(profile["id"], A_Index))
            ProfileOverrides.ClearSection(iniPath, ProfileOverrides.SecondaryAffixSectionName(profile["id"], A_Index))
            ProfileOverrides.ClearSection(iniPath, ProfileOverrides.RelativeAffixSectionName(profile["id"], A_Index))
        }
        ProfileOverrides.ClearSection(iniPath, ProfileOverrides.LegacyAffixSectionName(profile["id"]))

        IniWrite(profile["groupSets"].Length, iniPath, section, "setCount")
        IniWrite(profile["activeGroupSetIndex"], iniPath, section, "activeSetIndex")

        for setIndex, groupSet in profile["groupSets"] {
            normalizedSet := ProfileRegistry.NormalizeGroupSet(groupSet, ProfileRegistry.GroupSetFallbackName(profile, setIndex))
            profile["groupSets"][setIndex] := normalizedSet
            IniWrite(normalizedSet["name"], iniPath, section, "set" setIndex "Name")
            ProfileOverrides.SaveAffixGroups(iniPath, profile["id"], normalizedSet["affixGroups"], setIndex)
            ProfileOverrides.SaveSecondaryAffixGroups(iniPath, profile["id"], normalizedSet["secondaryAffixGroups"], setIndex)
            ProfileOverrides.SaveRelativeAffixGroups(iniPath, profile["id"], normalizedSet["relativeAffixGroups"], setIndex)
        }
    }

    static LoadTargetOverrides(iniPath, profile) {
        section := ProfileOverrides.TargetSectionName(profile["id"])
        profile["targetAffixNum"] := Max(1, SettingsLoader.ReadInt(iniPath, section, "targetAffixNum", profile["targetAffixNum"]))
        profile["targetSecondAffixNum"] := Max(0, SettingsLoader.ReadInt(iniPath, section, "targetSecondAffixNum", profile["targetSecondAffixNum"]))
    }

    static SaveTargetOverrides(iniPath, profile) {
        section := ProfileOverrides.TargetSectionName(profile["id"])
        IniWrite(profile["targetAffixNum"], iniPath, section, "targetAffixNum")
        IniWrite(profile["targetSecondAffixNum"], iniPath, section, "targetSecondAffixNum")
    }

    static LoadBehaviorOverrides(iniPath, profile) {
        section := ProfileOverrides.BehaviorSectionName(profile["id"])
        profile["skipAugmentationWhenRelativeMatch"] := SettingsLoader.ReadInt(iniPath, section, "skipAugmentationWhenRelativeMatch", profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0) = 1
    }

    static SaveBehaviorOverrides(iniPath, profile) {
        section := ProfileOverrides.BehaviorSectionName(profile["id"])
        IniWrite(profile["skipAugmentationWhenRelativeMatch"] ? 1 : 0, iniPath, section, "skipAugmentationWhenRelativeMatch")
    }

    static SaveAffixGroups(iniPath, profileId, groups, setIndex := 1) {
        section := ProfileOverrides.AffixSectionName(profileId, setIndex)
        ProfileOverrides.ClearSection(iniPath, section)
        IniWrite(groups.Length, iniPath, section, "groupCount")

        for groupIndex, group in groups {
            normalizedGroup := ProfileOverrides.NormalizeGroup(group, "Primary Group " groupIndex)
            IniWrite(normalizedGroup["name"], iniPath, section, "group" groupIndex "Name")
            IniWrite(normalizedGroup["patterns"].Length, iniPath, section, "group" groupIndex "PatternCount")
            for patternIndex, pattern in normalizedGroup["patterns"] {
                IniWrite(pattern, iniPath, section, "group" groupIndex "Pattern" patternIndex)
            }
        }
    }

    static LoadSecondaryAffixGroups(iniPath, profileId, setIndex := 1, defaultGroups := "") {
        section := ProfileOverrides.SecondaryAffixSectionName(profileId, setIndex)
        groupCount := SettingsLoader.ReadInt(iniPath, section, "groupCount", -1)
        if groupCount < 0 {
            return defaultGroups
        }

        groups := []
        loop groupCount {
            groupIndex := A_Index
            patternCount := SettingsLoader.ReadInt(iniPath, section, "group" groupIndex "PatternCount", 0)
            groupName := SettingsLoader.Read(iniPath, section, "group" groupIndex "Name", "Secondary Group " groupIndex)
            patterns := []
            loop patternCount {
                pattern := SettingsLoader.Read(iniPath, section, "group" groupIndex "Pattern" A_Index, "")
                if pattern != "" {
                    patterns.Push(pattern)
                }
            }
            groups.Push(Map("name", groupName, "patterns", patterns))
        }
        return groups
    }

    static SaveSecondaryAffixGroups(iniPath, profileId, groups, setIndex := 1) {
        section := ProfileOverrides.SecondaryAffixSectionName(profileId, setIndex)
        ProfileOverrides.ClearSection(iniPath, section)
        IniWrite(groups.Length, iniPath, section, "groupCount")

        for groupIndex, group in groups {
            normalizedGroup := ProfileOverrides.NormalizeGroup(group, "Secondary Group " groupIndex)
            IniWrite(normalizedGroup["name"], iniPath, section, "group" groupIndex "Name")
            IniWrite(normalizedGroup["patterns"].Length, iniPath, section, "group" groupIndex "PatternCount")
            for patternIndex, pattern in normalizedGroup["patterns"] {
                IniWrite(pattern, iniPath, section, "group" groupIndex "Pattern" patternIndex)
            }
        }
    }

    static LoadRelativeAffixGroups(iniPath, profileId, setIndex := 1, defaultGroups := "") {
        section := ProfileOverrides.RelativeAffixSectionName(profileId, setIndex)
        groupCount := SettingsLoader.ReadInt(iniPath, section, "groupCount", -1)
        if groupCount < 0 {
            return defaultGroups
        }

        groups := []
        loop groupCount {
            groupIndex := A_Index
            patternCount := SettingsLoader.ReadInt(iniPath, section, "group" groupIndex "PatternCount", 0)
            groupName := SettingsLoader.Read(iniPath, section, "group" groupIndex "Name", "Relative Group " groupIndex)
            patterns := []
            loop patternCount {
                pattern := SettingsLoader.Read(iniPath, section, "group" groupIndex "Pattern" A_Index, "")
                if pattern != "" {
                    patterns.Push(pattern)
                }
            }
            groups.Push(Map("name", groupName, "patterns", patterns))
        }
        return groups
    }

    static SaveRelativeAffixGroups(iniPath, profileId, groups, setIndex := 1) {
        section := ProfileOverrides.RelativeAffixSectionName(profileId, setIndex)
        ProfileOverrides.ClearSection(iniPath, section)
        IniWrite(groups.Length, iniPath, section, "groupCount")

        for groupIndex, group in groups {
            normalizedGroup := ProfileOverrides.NormalizeGroup(group, "Relative Group " groupIndex)
            IniWrite(normalizedGroup["name"], iniPath, section, "group" groupIndex "Name")
            IniWrite(normalizedGroup["patterns"].Length, iniPath, section, "group" groupIndex "PatternCount")
            for patternIndex, pattern in normalizedGroup["patterns"] {
                IniWrite(pattern, iniPath, section, "group" groupIndex "Pattern" patternIndex)
            }
        }
    }

    static NormalizeGroup(group, defaultName := "Group") {
        if group is Map {
            patterns := []
            sourcePatterns := group.Has("patterns") ? group["patterns"] : []
            if IsObject(sourcePatterns) {
                for _, pattern in sourcePatterns {
                    patterns.Push(pattern)
                }
            }
            return Map(
                "name", Trim(group.Has("name") ? group["name"] : "") != "" ? group["name"] : defaultName,
                "patterns", patterns
            )
        }

        patterns := []
        if IsObject(group) {
            for _, pattern in group {
                patterns.Push(pattern)
            }
        }
        return Map("name", defaultName, "patterns", patterns)
    }

    static GroupSetSectionName(profileId) {
        return "profile_groupsets_" profileId
    }

    static LegacyAffixSectionName(profileId) {
        return "profile_affixgroups_" profileId
    }

    static AffixSectionName(profileId, setIndex := 1) {
        return "profile_affixgroups_" profileId "_set" setIndex
    }

    static SecondaryAffixSectionName(profileId, setIndex := 1) {
        return "profile_secondaryaffixgroups_" profileId "_set" setIndex
    }

    static RelativeAffixSectionName(profileId, setIndex := 1) {
        return "profile_relativeaffixgroups_" profileId "_set" setIndex
    }

    static TargetSectionName(profileId) {
        return "profile_targets_" profileId
    }

    static BehaviorSectionName(profileId) {
        return "profile_behavior_" profileId
    }

    static ClearSection(iniPath, section) {
        try {
            IniDelete(iniPath, section)
        } catch {
        }
    }
}
