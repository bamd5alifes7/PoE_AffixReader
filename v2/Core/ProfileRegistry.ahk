class ProfileRegistry {
    static Create(baseDir := "") {
        profiles := ProfileRegistry.LoadDefaultProfiles(baseDir)
        if profiles.Count > 0 {
            return profiles
        }
        return ProfileRegistry.CreateEmbedded()
    }

    static LoadDefaultProfiles(baseDir := "") {
        profiles := Map()
        if baseDir = "" {
            return profiles
        }

        defaultDir := baseDir "\v2\profiles\default"
        if !DirExist(defaultDir) {
            return profiles
        }

        foundFiles := 0
        loop files defaultDir "\*.json" {
            foundFiles += 1
            data := JsonData.LoadFile(A_LoopFileFullPath)
            profile := ProfileRegistry.ProfileFromObject(data)
            profiles[profile["id"]] := profile
        }

        return foundFiles > 0 ? profiles : Map()
    }

    static ProfileFromObject(data) {
        overrides := Map()
        for key, value in data {
            if key = "schemaVersion" {
                continue
            }
            overrides[key] := ProfileRegistry.CloneJsonValue(value)
        }
        return ProfileRegistry.BaseProfile(overrides)
    }

    static CloneJsonValue(value) {
        if value is Map {
            cloned := Map()
            for key, item in value {
                cloned[key] := ProfileRegistry.CloneJsonValue(item)
            }
            return cloned
        }
        if value is Array {
            cloned := []
            for _, item in value {
                cloned.Push(ProfileRegistry.CloneJsonValue(item))
            }
            return cloned
        }
        return value
    }

    static CreateEmbedded() {
        profiles := Map()

        profiles["alteration_single_or_aug_two"] := ProfileRegistry.BaseProfile(Map(
            "id", "alteration_single_or_aug_two",
            "name", "Alt 1 / Aug 2",
            "type", "alterationAugment",
            "targetAffixNum", 2,
            "clipboardDelay", 200,
            "affixGroups", [
                Map("name", "Critical Flask", "patterns", ["(2[6-9]|3[0-5])% chance to gain a Flask Charge when you deal a Critical Strike","(4[4-9]|5[0-5])% increased Critical Strike Chance during Effect","(5[1-9]|60)% increased Evasion Rating during Effect","(9|1[0-4])% increased Movement Speed during Effect","(3[5-9])% less Duration`nImmunity to Bleeding and Corrupted Blood during Effect","(5[1-9]|60)% increased Armour during Effect","(5[2-9]|6[0-5])% reduced Effect of Curses on you during Effect"]),
                Map("name", "Hit Flask", "patterns", ["3 Charges when you are Hit by an Enemy","(5[1-9]|60)% increased Armour during Effect","(5[2-9]|6[0-5])% reduced Effect of Curses on you during Effect","(9|1[0-4])% increased Movement Speed during Effect"])
            ]
        ))

        profiles["alteration_aug_single"] := ProfileRegistry.BaseProfile(Map(
            "id", "alteration_aug_single",
            "name", "Alt + Aug 1",
            "type", "alterationAugment",
            "targetAffixNum", 1,
            "clipboardDelay", 200,
            "augmentOnZero", true,
            "affixGroups", [
                Map("name", "Helmet Righteous Fire", "patterns", ["Level 20 Concentrated", "Level 20 Burning", "Level 20 Increased Area", "Level 20 Trap", "Nearby Enemies take 6% increased Elemental"])
            ]
        ))

        profiles["alteration_aug_relative"] := ProfileRegistry.BaseProfile(Map(
            "id", "alteration_aug_relative",
            "name", "Alt + Aug Relative",
            "type", "alterationAugment",
            "targetAffixNum", 2,
            "clipboardDelay", 200,
            "skipAugmentationWhenRelativeMatch", true,
            "affixGroups", [
                Map("name", "Flask Speed", "patterns", ["(9|1[0-4])% increased Movement Speed during Effect","(5[1-9]|60)% increased Evasion Rating during Effect","(5[1-9]|60)% increased Armour during Effect"])
            ],
            "relativeAffixGroups", [
                Map("name", "Relative Skip Example", "patterns", ["relative Modifiers that don't want to use Augmentation"])
            ]
        ))

        profiles["chaos_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "chaos_cycle",
            "name", "Chaos",
            "type", "chaos",
            "targetAffixNum", 3,
            "clipboardDelay", 200,
            "groupSets", [
                Map(
                    "name", "Bow Cluster",
                    "affixGroups", [
                        Map("name", "Bow All Passive", "patterns", ["Vicious Skewering","Arcing Shot","Tempered Arrowheads","Broadside","Smite the Weak","Heavy Hitter","Martial Prowess","Calamitous","Devastator","Fuel the Fight","Drive the Destruction","Feed the Fury"])
                    ]
                ),
                Map(
                    "name", "Chaos Cluster",
                    "affixGroups", [
                        Map("name", "Chaos All Passive", "patterns", ["Grim Oath","Overwhelming Malice","Touch of Cruelty","Unwaveringly Evil","Unspeakable Gifts","Dark Ideation","Unholy Grace","Wicked Pall"])
                    ]
                ),
                Map(
                    "name", "Fire Cluster",
                    "affixGroups", [
                        Map("name", "Fire All Passive", "patterns", ["Sadist","Corrosive Elements","Doryani's Lesson","Disorienting Display","Prismatic Heart","Widespread Destruction","Master of Fire","Smoking Remains","Cremator","Burning Bright"])
                    ]
                )
            ]
        ))

        profiles["essence_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "essence_cycle",
            "name", "Essence",
            "type", "essence",
            "targetAffixNum", 1,
            "clipboardDelay", 200,
            "affixGroups", [
                Map("name", "Resist", "patterns", ["(3[6-9]|4[0-8])% to Cold Resistance", "(3[6-9]|4[0-8])% to fire Resistance"])
            ]
        ))

        profiles["scouring_alchemy_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "scouring_alchemy_cycle",
            "name", "Scour + Alch",
            "type", "scouringAlchemy",
            "targetAffixNum", 3,
            "clipboardDelay", 200,
            "affixGroups", [
                Map("name", "Bow Cluster", "patterns", ["Vicious Skewering","Arcing Shot","Tempered Arrowheads","Broadside","Smite the Weak","Heavy Hitter","Martial Prowess","Calamitous","Devastator","Fuel the Fight","Drive the Destruction","Feed the Fury"])
            ]
        ))

        profiles["scouring_alchemy_secondary"] := ProfileRegistry.BaseProfile(Map(
            "id", "scouring_alchemy_secondary",
            "name", "Scour + Alch + Secondary",
            "type", "scouringAlchemy",
            "targetAffixNum", 1,
            "targetSecondAffixNum", 1,
            "clipboardDelay", 200,
            "affixGroups", [
                Map("name", "Life", "patterns", ["to maximum Life"])
            ],
            "secondaryAffixGroups", [
                Map("name", "Useful Suffix", "patterns", ["Fire Resistance", "Cold Resistance", "Lightning Resistance", "Chaos Resistance", "Damage taken Recouped as Life", "all Elemental Resistances", "to Dexterity", "to Intelligence"])
            ]
        ))

        profiles["crafting_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "crafting_cycle",
            "name", "Crafting",
            "type", "crafting",
            "targetAffixNum", 2,
            "clipboardDelay", 200,
            "affixGroups", [
                Map("name", "Cold Cluster", "patterns", ["Sadist", "Corrosive Elements", "Doryani's Lesson", "Disorienting Display", "Prismatic Heart", "Widespread Destruction", "Snowstorm", "Blanketed Snow", "Cold to the Core", "Cold-Blooded Killer", "Inspired Oppression", "Deep Chill", "Blast-Freeze", "Stormrider"])
            ]
        ))

        return profiles
    }

    static BaseProfile(overrides) {
        profile := Map(
            "id", "",
            "name", "",
            "type", "",
            "targetAffixNum", 1,
            "targetSecondAffixNum", 0,
            "groupSets", [],
            "activeGroupSetIndex", 1,
            "affixGroups", [],
            "secondaryAffixGroups", [],
            "relativeAffixGroups", [],
            "clipboardDelay", 160,
            "pingDelay", 20,
            "conformDelay", 20,
            "debugDelay", 10,
            "randomMin", 40,
            "randomMax", 60,
            "clipWaitSeconds", 0.5,
            "captureRetries", 10,
            "captureRetrySleepMs", 50,
            "sameStateFallbackAfter", 10,
            "augmentationSameStateFallbackAfter", 2,
            "mouseSpeed", 2,
            "augmentOnZero", false,
            "skipAugmentationWhenRelativeMatch", false
        )
        for key, value in overrides {
            profile[key] := value
        }
        profile["affixGroups"] := ProfileRegistry.NormalizeGroupCollection(profile["affixGroups"], "Primary")
        profile["secondaryAffixGroups"] := ProfileRegistry.NormalizeGroupCollection(profile["secondaryAffixGroups"], "Secondary")
        profile["relativeAffixGroups"] := ProfileRegistry.NormalizeGroupCollection(profile["relativeAffixGroups"], "Relative")
        profile["groupSets"] := ProfileRegistry.NormalizeGroupSets(profile)
        if profile["groupSets"].Length = 0 {
            profile["groupSets"].Push(ProfileRegistry.DefaultGroupSet(profile))
        }
        ProfileRegistry.ActivateGroupSet(profile, profile["activeGroupSetIndex"])
        return profile
    }

    static NormalizeGroupSets(profile) {
        normalized := []
        sourceSets := profile.Has("groupSets") ? profile["groupSets"] : []
        if IsObject(sourceSets) && sourceSets.Length > 0 {
            for index, groupSet in sourceSets {
                normalized.Push(ProfileRegistry.NormalizeGroupSet(groupSet, ProfileRegistry.GroupSetFallbackName(profile, index)))
            }
            return normalized
        }

        normalized.Push(ProfileRegistry.DefaultGroupSet(profile))
        return normalized
    }

    static NormalizeGroupSet(groupSet, defaultName := "Set 1") {
        if !(groupSet is Map) {
            return Map(
                "name", defaultName,
                "affixGroups", [],
                "secondaryAffixGroups", [],
                "relativeAffixGroups", []
            )
        }

        name := groupSet.Has("name") && Trim(groupSet["name"]) != "" ? groupSet["name"] : defaultName
        affixGroups := groupSet.Has("affixGroups") ? groupSet["affixGroups"] : []
        secondaryGroups := groupSet.Has("secondaryAffixGroups") ? groupSet["secondaryAffixGroups"] : []
        relativeGroups := groupSet.Has("relativeAffixGroups") ? groupSet["relativeAffixGroups"] : []

        return Map(
            "name", name,
            "affixGroups", ProfileRegistry.NormalizeGroupCollection(affixGroups, "Primary"),
            "secondaryAffixGroups", ProfileRegistry.NormalizeGroupCollection(secondaryGroups, "Secondary"),
            "relativeAffixGroups", ProfileRegistry.NormalizeGroupCollection(relativeGroups, "Relative")
        )
    }

    static DefaultGroupSet(profile) {
        return Map(
            "name", ProfileRegistry.DefaultGroupSetName(profile),
            "affixGroups", ProfileRegistry.NormalizeGroupCollection(profile["affixGroups"], "Primary"),
            "secondaryAffixGroups", ProfileRegistry.NormalizeGroupCollection(profile["secondaryAffixGroups"], "Secondary"),
            "relativeAffixGroups", ProfileRegistry.NormalizeGroupCollection(profile["relativeAffixGroups"], "Relative")
        )
    }

    static DefaultGroupSetName(profile) {
        profileName := profile.Has("name") ? Trim(profile["name"]) : ""
        return profileName != "" ? profileName " Default" : "Default"
    }

    static GroupSetFallbackName(profile, index) {
        return index = 1 ? ProfileRegistry.DefaultGroupSetName(profile) : "Set " index
    }

    static ActivateGroupSet(profile, index := 1) {
        if !profile.Has("groupSets") || !IsObject(profile["groupSets"]) || profile["groupSets"].Length = 0 {
            profile["groupSets"] := [ProfileRegistry.DefaultGroupSet(profile)]
        }

        setCount := profile["groupSets"].Length
        if index < 1 || index > setCount {
            index := 1
        }

        activeSet := ProfileRegistry.NormalizeGroupSet(profile["groupSets"][index], "Set " index)
        profile["groupSets"][index] := activeSet
        profile["activeGroupSetIndex"] := index
        profile["affixGroups"] := activeSet["affixGroups"]
        profile["secondaryAffixGroups"] := activeSet["secondaryAffixGroups"]
        profile["relativeAffixGroups"] := activeSet["relativeAffixGroups"]
        return activeSet
    }

    static NormalizeGroupCollection(groups, prefix := "Group") {
        normalized := []
        if !IsObject(groups) {
            return normalized
        }

        for index, group in groups {
            normalized.Push(ProfileRegistry.NormalizeSingleGroup(group, prefix " Group " index))
        }
        return normalized
    }

    static NormalizeSingleGroup(group, defaultName := "Group") {
        if group is Map {
            normalizedPatterns := []
            patterns := group.Has("patterns") ? group["patterns"] : []
            if IsObject(patterns) {
                for _, pattern in patterns {
                    normalizedPatterns.Push(pattern)
                }
            }
            return Map(
                "name", Trim(group.Has("name") ? group["name"] : "") != "" ? group["name"] : defaultName,
                "patterns", normalizedPatterns
            )
        }

        normalizedPatterns := []
        if IsObject(group) {
            for _, pattern in group {
                normalizedPatterns.Push(pattern)
            }
        }
        return Map("name", defaultName, "patterns", normalizedPatterns)
    }
}
