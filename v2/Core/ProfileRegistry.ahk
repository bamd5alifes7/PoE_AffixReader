class ProfileRegistry {
    static Create() {
        profiles := Map()

        profiles["alteration_single_or_aug_two"] := ProfileRegistry.BaseProfile(Map(
            "id", "alteration_single_or_aug_two",
            "name", "Alteration single / augment double",
            "type", "alterationAugment",
            "targetAffixNum", 2,
            "clipboardDelay", 200,
            "affixGroups", [
                ["(2[6-9]|3[0-5])% chance to gain a Flask Charge when you deal a Critical Strike","(4[4-9]|5[0-5])% increased Critical Strike Chance during Effect","(5[1-9]|60)% increased Evasion Rating during Effect","(9|1[0-4])% increased Movement Speed during Effect","(3[5-9])% less Duration\nImmunity to Bleeding and Corrupted Blood during Effect"],["3 Charges when you are Hit by an Enemy","(5[1-9]|60)% increased Armour during Effect","(5[2-9]|6[0-5])% reduced Effect of Curses on you during Effect"]
            ]
        ))

        profiles["alteration_aug_single"] := ProfileRegistry.BaseProfile(Map(
            "id", "alteration_aug_single",
            "name", "Alteration augment single",
            "type", "alterationAugment",
            "targetAffixNum", 1,
            "clipboardDelay", 200,
            "augmentOnZero", true,
            "affixGroups", [
                ["Level 20 Concentrated", "Level 20 Burning", "Level 20 Increased Area", "Level 20 Trap", "Nearby Enemies take 6% increased Elemental"]
            ]
        ))

        profiles["chaos_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "chaos_cycle",
            "name", "Chaos cycle",
            "type", "chaos",
            "targetAffixNum", 3,
            "clipboardDelay", 200,
            "affixGroups", [
                ["Vicious Skewering","Arcing Shot","Tempered Arrowheads","Broadside","Smite the Weak","Heavy Hitter","Martial Prowess","Calamitous","Devastator","Fuel the Fight","Drive the Destruction","Feed the Fury"]
            ]
        ))

        profiles["essence_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "essence_cycle",
            "name", "Essence cycle",
            "type", "essence",
            "targetAffixNum", 1,
            "clipboardDelay", 200,
            "affixGroups", [
                ["\\+(3[6789]|4[01])% to Cold Resistance", "(3[6789]|4[01])% to fire Resistance"]
            ]
        ))

        profiles["scouring_alchemy_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "scouring_alchemy_cycle",
            "name", "Scouring + alchemy cycle",
            "type", "scouringAlchemy",
            "targetAffixNum", 3,
            "clipboardDelay", 200,
            "affixGroups", [
                ["Vicious Skewering","Arcing Shot","Tempered Arrowheads","Broadside","Smite the Weak","Heavy Hitter","Martial Prowess","Calamitous","Devastator","Fuel the Fight","Drive the Destruction","Feed the Fury"]
            ]
        ))

        profiles["scouring_alchemy_secondary"] := ProfileRegistry.BaseProfile(Map(
            "id", "scouring_alchemy_secondary",
            "name", "Scouring + alchemy with secondary target",
            "type", "scouringAlchemy",
            "targetAffixNum", 1,
            "targetSecondAffixNum", 1,
            "clipboardDelay", 200,
            "affixGroups", [
                ["to maximum Life"]
            ],
            "secondaryAffixGroups", [
                ["Fire Resistance", "Cold Resistance", "Lightning Resistance", "Chaos Resistance", "Damage taken Recouped as Life", "all Elemental Resistances", "Master of Fire", "to Dexterity", "to Intelligence"]
            ]
        ))

        profiles["crafting_cycle"] := ProfileRegistry.BaseProfile(Map(
            "id", "crafting_cycle",
            "name", "Crafting cycle",
            "type", "crafting",
            "targetAffixNum", 2,
            "clipboardDelay", 200,
            "affixGroups", [
                ["Sadist", "Corrosive Elements", "Doryani's Lesson", "Disorienting Display", "Prismatic Heart", "Widespread Destruction", "Snowstorm", "Blanketed Snow", "Cold to the Core", "Cold-Blooded Killer", "Inspired Oppression", "Deep Chill", "Blast-Freeze", "Stormrider"]
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
        return profile
    }
}
