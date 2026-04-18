class ProfileGroupSets {
    static Apply(groupSetsPath, profiles, legacyOverridesPath := "") {
        document := ProfileGroupSets.LoadDocument(groupSetsPath)
        profileData := document["profiles"]

        if profileData.Count = 0 && legacyOverridesPath != "" {
            profileData := ProfileGroupSets.LoadLegacyProfileData(legacyOverridesPath)
        }

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

            activeIndex := stored.Has("activeGroupSetIndex") ? stored["activeGroupSetIndex"] + 0 : 1
            ProfileRegistry.ActivateGroupSet(profile, activeIndex)
        }
    }

    static Save(groupSetsPath, profile) {
        document := ProfileGroupSets.LoadDocument(groupSetsPath)
        entry := ProfileGroupSets.EnsureProfileEntry(document, profile["id"])
        entry["groupSets"] := ProfileGroupSets.CloneGroupSets(profile["groupSets"])
        entry["activeGroupSetIndex"] := profile["activeGroupSetIndex"]
        JsonData.SaveFile(groupSetsPath, document)
    }

    static LoadDocument(groupSetsPath) {
        if FileExist(groupSetsPath) {
            loaded := JsonData.LoadFile(groupSetsPath)
            if loaded is Map && loaded.Has("profiles") && loaded["profiles"] is Map {
                ProfileGroupSets.NormalizeSchemaVersion(loaded)
                return loaded
            }
        }
        return Map(
            "schemaVersion", 1,
            "profiles", Map()
        )
    }

    static LoadLegacyProfileData(legacyOverridesPath) {
        if !FileExist(legacyOverridesPath) {
            return Map()
        }

        loaded := JsonData.LoadFile(legacyOverridesPath)
        if !(loaded is Map) || !loaded.Has("profiles") || !(loaded["profiles"] is Map) {
            return Map()
        }

        legacyProfiles := loaded["profiles"]
        migrated := Map()
        for profileId, stored in legacyProfiles {
            if !(stored is Map) {
                continue
            }
            if !(stored.Has("groupSets") && stored["groupSets"] is Array && stored["groupSets"].Length > 0) {
                continue
            }

            migrated[profileId] := Map(
                "groupSets", ProfileGroupSets.CloneGroupSets(stored["groupSets"]),
                "activeGroupSetIndex", stored.Has("activeGroupSetIndex") ? stored["activeGroupSetIndex"] + 0 : 1
            )
        }
        return migrated
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
                "affixGroups", ProfileGroupSets.CloneGroups(normalizedSet["affixGroups"]),
                "secondaryAffixGroups", ProfileGroupSets.CloneGroups(normalizedSet["secondaryAffixGroups"]),
                "relativeAffixGroups", ProfileGroupSets.CloneGroups(normalizedSet["relativeAffixGroups"])
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

    static NormalizeSchemaVersion(document) {
        if !document.Has("schemaVersion") || Type(document["schemaVersion"]) != "Integer" {
            document["schemaVersion"] := 1
        }
    }
}
