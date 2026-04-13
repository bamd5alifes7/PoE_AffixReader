class AffixMatcher {
    CountMatches(text, groups, target := 1) {
        if !IsObject(groups) || groups.Length = 0 {
            return 0
        }

        tempTarget := Max(target, 1)
        while tempTarget >= 1 {
            for _, group in groups {
                patterns := this.GroupPatterns(group)
                found := 0
                if patterns.Length < tempTarget {
                    continue
                }
                for _, pattern in patterns {
                    if RegExMatch(text, pattern) {
                        found += 1
                    }
                }
                if found >= tempTarget {
                    return found
                }
            }
            tempTarget -= 1
        }
        return 0
    }

    GroupPatterns(group) {
        if group is Map {
            return group.Has("patterns") ? group["patterns"] : []
        }
        return group
    }
}
