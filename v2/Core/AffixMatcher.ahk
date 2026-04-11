class AffixMatcher {
    CountMatches(text, groups, target := 1) {
        if !IsObject(groups) || groups.Length = 0 {
            return 0
        }

        tempTarget := Max(target, 1)
        while tempTarget >= 1 {
            for _, group in groups {
                found := 0
                if group.Length < tempTarget {
                    continue
                }
                for _, pattern in group {
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
}
