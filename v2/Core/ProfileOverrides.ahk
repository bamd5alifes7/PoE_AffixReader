class ProfileOverrides {
    static Apply(overridesPath, profiles) {
        document := ProfileOverrides.LoadDocument(overridesPath)
        profileData := document["profiles"]

        for id, profile in profiles {
            if !profileData.Has(id) || !(profileData[id] is Map) {
                continue
            }

            stored := profileData[id]
            if stored.Has("groupSets") && stored["groupSets"] is Array && stored["groupSets"].Length > 0 {
                groupSets := []
                for _, groupSet in stored["groupSets"] {
                    groupSets.Push(ProfileRegistry.NormalizeGroupSet(groupSet))
                }
                profile["groupSets"] := groupSets
            }

            if stored.Has("targetAffixNum") {
                profile["targetAffixNum"] := Max(1, stored["targetAffixNum"] + 0)
            }
            if stored.Has("targetSecondAffixNum") {
                profile["targetSecondAffixNum"] := Max(0, stored["targetSecondAffixNum"] + 0)
            }
            if stored.Has("skipAugmentationWhenRelativeMatch") {
                profile["skipAugmentationWhenRelativeMatch"] := stored["skipAugmentationWhenRelativeMatch"] ? true : false
            }
            if stored.Has("augmentOnZero") {
                profile["augmentOnZero"] := stored["augmentOnZero"] ? true : false
            }

            activeIndex := stored.Has("activeGroupSetIndex") ? stored["activeGroupSetIndex"] + 0 : 1
            ProfileRegistry.ActivateGroupSet(profile, activeIndex)
        }
    }

    static SaveProfileGroupSets(overridesPath, profile) {
        document := ProfileOverrides.LoadDocument(overridesPath)
        entry := ProfileOverrides.EnsureProfileEntry(document, profile["id"])
        entry["groupSets"] := ProfileOverrides.CloneGroupSets(profile["groupSets"])
        entry["activeGroupSetIndex"] := profile["activeGroupSetIndex"]
        JsonData.SaveFile(overridesPath, document)
    }

    static SaveTargetOverrides(overridesPath, profile) {
        document := ProfileOverrides.LoadDocument(overridesPath)
        entry := ProfileOverrides.EnsureProfileEntry(document, profile["id"])
        entry["targetAffixNum"] := profile["targetAffixNum"]
        entry["targetSecondAffixNum"] := profile["targetSecondAffixNum"]
        JsonData.SaveFile(overridesPath, document)
    }

    static SaveBehaviorOverrides(overridesPath, profile) {
        document := ProfileOverrides.LoadDocument(overridesPath)
        entry := ProfileOverrides.EnsureProfileEntry(document, profile["id"])
        entry["skipAugmentationWhenRelativeMatch"] := profile["skipAugmentationWhenRelativeMatch"] ? true : false
        entry["augmentOnZero"] := profile["augmentOnZero"] ? true : false
        JsonData.SaveFile(overridesPath, document)
    }

    static LoadDocument(overridesPath) {
        if FileExist(overridesPath) {
            loaded := JsonData.LoadFile(overridesPath)
            if loaded is Map && loaded.Has("profiles") && loaded["profiles"] is Map {
                return loaded
            }
        }
        return Map(
            "schemaVersion", 1,
            "profiles", Map()
        )
    }

    static EnsureProfileEntry(document, profileId) {
        profiles := document["profiles"]
        if !profiles.Has(profileId) || !(profiles[profileId] is Map) {
            profiles[profileId] := Map()
        }
        return profiles[profileId]
    }

    static CloneGroupSets(groupSets) {
        cloned := []
        for _, groupSet in groupSets {
            normalizedSet := ProfileRegistry.NormalizeGroupSet(groupSet)
            cloned.Push(Map(
                "name", normalizedSet["name"],
                "affixGroups", ProfileOverrides.CloneGroups(normalizedSet["affixGroups"]),
                "secondaryAffixGroups", ProfileOverrides.CloneGroups(normalizedSet["secondaryAffixGroups"]),
                "relativeAffixGroups", ProfileOverrides.CloneGroups(normalizedSet["relativeAffixGroups"])
            ))
        }
        return cloned
    }

    static CloneGroups(groups) {
        cloned := []
        for _, group in groups {
            normalized := group is Map ? group : Map("name", "", "patterns", group)
            patterns := []
            sourcePatterns := normalized.Has("patterns") ? normalized["patterns"] : []
            if sourcePatterns is Array {
                for _, pattern in sourcePatterns {
                    patterns.Push(pattern)
                }
            }
            cloned.Push(Map(
                "name", normalized.Has("name") ? normalized["name"] : "",
                "patterns", patterns
            ))
        }
        return cloned
    }
}
