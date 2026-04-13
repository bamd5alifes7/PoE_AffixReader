class ProfilePresenter {
    static HomeStatusTitle(runStatus) {
        status := StrLower(runStatus)
        if InStr(status, "running") {
            return "Running"
        }
        if InStr(status, "failed") {
            return "Needs Attention"
        }
        if InStr(status, "stop requested") {
            return "Stopping"
        }
        if InStr(status, "completed") {
            return "Completed"
        }
        return "Ready"
    }

    static TargetText(profile) {
        text := "Primary " profile["targetAffixNum"]
        if profile["targetSecondAffixNum"] > 0 {
            text .= " / Secondary " profile["targetSecondAffixNum"]
        }
        return text
    }

    static ProfileDetails(profile, previewSet, isActiveProfile := false, isActiveSet := false, activeSetName := "") {
        detailText := ""
        if isActiveProfile {
            detailText := "This is the active profile."
            if isActiveSet {
                detailText .= " This set is active."
            } else {
                detailText .= " Active set: " activeSetName "."
            }
            detailText .= "`r`n`r`n"
        }

        detailText .=
        (
            "Primary affix groups: " previewSet["affixGroups"].Length "`r`n"
            . "Secondary affix groups: " previewSet["secondaryAffixGroups"].Length "`r`n"
            . "Relative affix groups: " previewSet["relativeAffixGroups"].Length "`r`n"
            . "Skip augment on relative match: " (profile["skipAugmentationWhenRelativeMatch"] ? "On" : "Off") "`r`n"
            . "Clipboard delay: " profile["clipboardDelay"] " ms"
        )
        return detailText
    }

    static StopRuleSummary(profile) {
        summary := profile["targetAffixNum"] " Primary"
        if profile["targetSecondAffixNum"] > 0 {
            summary .= " + " profile["targetSecondAffixNum"] " Secondary"
        }
        return summary
    }

    static StopRuleTargets(profile, separator := "`r`n") {
        parts := []
        primaryNames := ProfilePresenter.GroupNameList(profile["affixGroups"])
        if primaryNames != "" {
            parts.Push("Primary: " primaryNames)
        }

        secondaryNames := ProfilePresenter.GroupNameList(profile["secondaryAffixGroups"])
        if secondaryNames != "" {
            parts.Push("Secondary: " secondaryNames)
        }

        if parts.Length = 0 {
            return "No named target groups configured."
        }

        return ProfilePresenter.JoinParts(parts, separator)
    }

    static AffixGroupSummary(groupSet, separator := " | ") {
        parts := []

        primaryNames := ProfilePresenter.GroupNameList(groupSet["affixGroups"])
        if primaryNames != "" {
            parts.Push("P: " primaryNames)
        }

        secondaryNames := ProfilePresenter.GroupNameList(groupSet["secondaryAffixGroups"])
        if secondaryNames != "" {
            parts.Push("S: " secondaryNames)
        }

        relativeNames := ProfilePresenter.GroupNameList(groupSet["relativeAffixGroups"])
        if relativeNames != "" {
            parts.Push("R: " relativeNames)
        }

        if parts.Length = 0 {
            return "-"
        }

        return ProfilePresenter.JoinParts(parts, separator)
    }

    static GroupNameList(groups) {
        if !IsObject(groups) || groups.Length = 0 {
            return ""
        }

        names := ""
        for index, group in groups {
            groupName := group is Map ? group["name"] : "Group " index
            if Trim(groupName) = "" {
                groupName := "Group " index
            }
            if names != "" {
                names .= ", "
            }
            names .= groupName
        }
        return names
    }

    static JoinParts(parts, separator) {
        text := ""
        for index, part in parts {
            if index > 1 {
                text .= separator
            }
            text .= part
        }
        return text
    }
}
