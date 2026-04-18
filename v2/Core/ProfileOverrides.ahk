class ProfileOverrides {
    static Apply(overridesPath, profiles) {
        document := ProfileOverrides.LoadDocument(overridesPath)
        profileData := document["profiles"]

        for id, profile in profiles {
            if !profileData.Has(id) || !(profileData[id] is Map) {
                continue
            }

            stored := profileData[id]
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

            ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
        }
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
                ProfileOverrides.NormalizeSchemaVersion(loaded)
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

    static NormalizeSchemaVersion(document) {
        if !document.Has("schemaVersion") || Type(document["schemaVersion"]) != "Integer" {
            document["schemaVersion"] := 1
        }
    }
}
