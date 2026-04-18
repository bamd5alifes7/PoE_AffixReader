class ProfileCapabilities {
    static TargetEditable(profile) {
        return true
    }

    static SecondaryTargetEditable(profile) {
        return ProfileCapabilities.TargetEditable(profile) && profile["secondaryAffixGroups"].Length > 0
    }

    static RelativeSkipEditable(profile) {
        return profile["type"] = "alterationAugment" && profile["relativeAffixGroups"].Length > 0
    }

    static AugmentOnZeroEditable(profile) {
        return profile["type"] = "alterationAugment"
    }

    static EditableSummary(profile) {
        return Map(
            "targetEditable", ProfileCapabilities.TargetEditable(profile),
            "secondaryTargetEditable", ProfileCapabilities.SecondaryTargetEditable(profile),
            "relativeEditable", ProfileCapabilities.RelativeSkipEditable(profile),
            "augmentEditable", ProfileCapabilities.AugmentOnZeroEditable(profile)
        )
    }

    static TargetHint(profile) {
        capabilities := ProfileCapabilities.EditableSummary(profile)

        if capabilities["targetEditable"] {
            hint := capabilities["secondaryTargetEditable"]
                ? "Target values are configurable for this profile."
                : "Only the primary target is configurable for this profile."
        } else {
            hint := "Target values are not configurable for this profile."
        }

        if capabilities["relativeEditable"] {
            hint := hint = ""
                ? "Relative-match behavior is configurable for this profile."
                : hint . " Relative-match behavior is also configurable."
        }

        if capabilities["augmentEditable"] {
            hint := hint = ""
                ? "Augment behavior is configurable for this profile."
                : hint . " Augment behavior is also configurable."
        }

        return hint
    }
}
