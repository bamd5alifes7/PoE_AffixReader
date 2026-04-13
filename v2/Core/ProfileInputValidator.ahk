class ProfileInputValidator {
    static ValidateTargetValues(primaryValue, secondaryValue, allowSecondary := true) {
        primaryText := Trim(primaryValue)
        secondaryText := Trim(secondaryValue)

        if !RegExMatch(primaryText, "^\d+$") {
            return Map("ok", false, "message", "Primary target must be a whole number.")
        }

        if secondaryText = "" {
            secondaryText := "0"
        }
        if !RegExMatch(secondaryText, "^\d+$") {
            return Map("ok", false, "message", "Secondary target must be a whole number.")
        }

        primaryTarget := primaryText + 0
        secondaryTarget := secondaryText + 0
        if primaryTarget < 1 || primaryTarget > 3 {
            return Map("ok", false, "message", "Primary target must be between 1 and 3.")
        }
        if secondaryTarget < 0 || secondaryTarget > 3 {
            return Map("ok", false, "message", "Secondary target must be between 0 and 3.")
        }
        if !allowSecondary {
            secondaryTarget := 0
        }

        return Map(
            "ok", true,
            "primaryTarget", primaryTarget,
            "secondaryTarget", secondaryTarget
        )
    }

    static ValidateProfiles(profiles) {
        for profileId, profile in profiles {
            validation := ProfileInputValidator.ValidateProfile(profile)
            if validation["ok"] {
                continue
            }
            validation["profileId"] := profileId
            validation["profileName"] := profile["name"]
            return validation
        }
        return Map("ok", true)
    }

    static ValidateProfile(profile) {
        if !profile.Has("groupSets") || !IsObject(profile["groupSets"]) {
            return Map("ok", true)
        }

        for setIndex, groupSet in profile["groupSets"] {
            setName := groupSet.Has("name") && Trim(groupSet["name"]) != "" ? groupSet["name"] : "Set " setIndex
            validation := PatternValidator.ValidateGroupCollections([
                Map("groupType", "Primary", "groups", groupSet["affixGroups"]),
                Map("groupType", "Secondary", "groups", groupSet["secondaryAffixGroups"]),
                Map("groupType", "Relative", "groups", groupSet["relativeAffixGroups"])
            ])
            if validation["ok"] {
                continue
            }

            validation["setIndex"] := setIndex
            validation["setName"] := setName
            return validation
        }

        return Map("ok", true)
    }
}
