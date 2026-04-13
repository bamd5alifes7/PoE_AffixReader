class PatternValidator {
    static ValidateGroupCollections(groupCollections) {
        for _, collection in groupCollections {
            groupType := collection["groupType"]
            groups := collection["groups"]
            if !IsObject(groups) {
                continue
            }

            for groupIndex, group in groups {
                groupName := PatternValidator.GroupName(group, groupType, groupIndex)
                patterns := group is Map && group.Has("patterns") ? group["patterns"] : []
                if !IsObject(patterns) {
                    continue
                }

                for patternIndex, pattern in patterns {
                    result := PatternValidator.ValidatePattern(pattern)
                    if result["ok"] {
                        continue
                    }

                    return Map(
                        "ok", false,
                        "groupType", groupType,
                        "groupIndex", groupIndex,
                        "groupName", groupName,
                        "patternIndex", patternIndex,
                        "pattern", pattern,
                        "message", result["message"]
                    )
                }
            }
        }

        return Map("ok", true)
    }

    static ValidatePattern(pattern) {
        try {
            RegExMatch("", pattern)
            return Map("ok", true, "message", "")
        } catch as err {
            return Map("ok", false, "message", err.Message)
        }
    }

    static GroupName(group, groupType, groupIndex) {
        if group is Map && group.Has("name") && Trim(group["name"]) != "" {
            return group["name"]
        }
        return groupType " Group " groupIndex
    }
}
