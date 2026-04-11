class CraftingEngine {
    __New(profile, client, matcher, logger, app) {
        this.profile := profile
        this.client := client
        this.matcher := matcher
        this.logger := logger
        this.app := app
        this.lastAction := ""
    }

    Run() {
        this.logger.CheckSize()
        this.client.EnsureWindowActiveOrThrow()
        this.client.SaveItemPos()

        state := this.ReadState("", "")
        this.logger.Log("INFO", "profile_started", this.StatePayload(state))

        if this.ShouldStop(state) {
            MsgBox("The item already matches this profile. Please review it manually before continuing.")
            this.logger.Log("INFO", "profile_precheck_stop", this.StatePayload(state))
            return
        }

        loop {
            if this.app.stopRequested || GetKeyState("F12", "P") {
                this.app.stopRequested := true
                this.logger.Log("INFO", "profile_stopped_by_user", this.StatePayload(state))
                break
            }

            action := this.DecideAction(state)
            this.logger.Log("INFO", "action_selected", Map("profile", this.profile["id"], "action", action))
            this.PerformAction(action)
            this.lastAction := action
            Sleep(this.profile["pingDelay"])

            state := this.ReadState(state["itemText"], action)
            this.logger.Log("INFO", "round_state", this.StatePayload(state))

            if this.app.stopRequested || GetKeyState("F12", "P") {
                this.app.stopRequested := true
                this.logger.Log("INFO", "profile_stopped_by_user", this.StatePayload(state))
                break
            }

            if this.ShouldStop(state) {
                this.logger.Log("INFO", "profile_target_met", this.StatePayload(state))
                break
            }

            Sleep(this.profile["debugDelay"])
        }
    }

    ReadState(oldText, action := "") {
        text := this.client.CaptureItemText(this.profile, oldText, oldText != "", action)
        primaryCount := this.matcher.CountMatches(text, this.profile["affixGroups"], this.profile["targetAffixNum"])
        secondaryTarget := this.profile["targetSecondAffixNum"] > 0 ? this.profile["targetSecondAffixNum"] : 1
        secondaryCount := this.matcher.CountMatches(text, this.profile["secondaryAffixGroups"], secondaryTarget)
        relativeCount := this.matcher.CountMatches(text, this.profile["relativeAffixGroups"], 1)
        rarity := this.client.GetItemRarity(text)

        return Map(
            "itemText", text,
            "itemRarity", rarity,
            "primaryCount", primaryCount,
            "secondaryCount", secondaryCount,
            "relativeCount", relativeCount
        )
    }

    ShouldStop(state) {
        type := this.profile["type"]
        target := this.profile["targetAffixNum"]
        rarity := state["itemRarity"]
        primary := state["primaryCount"]

        if type = "alteration" || type = "alterationAugment" {
            if rarity = 1 && primary >= target {
                if this.profile["targetSecondAffixNum"] <= 0 {
                    return true
                }
            }
            if rarity = 1 && target <= 2 && primary >= target && this.SecondarySatisfied(state) {
                return true
            }
            return false
        }

        if rarity != 2 {
            return false
        }

        if primary < target {
            return false
        }

        return this.SecondarySatisfied(state)
    }

    SecondarySatisfied(state) {
        if this.profile["targetSecondAffixNum"] <= 0 || this.profile["secondaryAffixGroups"].Length = 0 {
            return true
        }
        return state["secondaryCount"] >= this.profile["targetSecondAffixNum"]
    }

    DecideAction(state) {
        type := this.profile["type"]
        rarity := state["itemRarity"]
        primary := state["primaryCount"]

        switch type {
            case "chaos":
                if rarity = 0 {
                    return "alchemy"
                }
                if rarity = 1 || rarity = 3 {
                    return "scouringAlchemy"
                }
                return "chaos"

            case "essence":
                if rarity = 0 {
                    return "essence"
                }
                return "scouringEssence"

            case "scouringAlchemy":
                if rarity = 0 {
                    return "alchemy"
                }
                return "scouringAlchemy"

            case "crafting":
                if rarity != 2 {
                    throw Error("Crafting mode expects a rare item. Please make the item rare before starting.")
                }
                return "crafting"

            case "alteration":
                return this.DecideAlterationAction(rarity, primary, false, state)

            case "alterationAugment":
                return this.DecideAlterationAction(rarity, primary, true, state)

            default:
                throw Error("Unsupported profile type: " type)
        }
    }

    DecideAlterationAction(rarity, primary, allowAugment, state) {
        if rarity = 0 {
            return "transmutation"
        }
        if rarity = 2 || rarity = 3 {
            return "scouringTransmutation"
        }
        if rarity != 1 {
            throw Error("Unexpected item rarity for alteration flow: " rarity)
        }

        target := this.profile["targetAffixNum"]
        if primary >= target {
            return "noop"
        }

        if allowAugment {
            shouldAugment := (primary >= 1 && target >= 2) || (primary = 0 && this.profile["augmentOnZero"])
            if shouldAugment {
                if this.profile["skipAugmentationWhenRelativeMatch"] && state["relativeCount"] > 0 {
                    return "alteration"
                }
                if this.lastAction = "augmentation" {
                    return "alteration"
                }
                return "augmentation"
            }
        } else if primary >= 1 && target >= 2 {
            if this.lastAction = "augmentation" {
                return "alteration"
            }
            return "augmentation"
        }

        return "alteration"
    }

    PerformAction(action) {
        switch action {
            case "noop":
                return
            case "transmutation":
                this.client.UseCurrencyOnItem("Transmutation", this.profile)
            case "alteration":
                this.client.UseCurrencyOnItem("Alteration", this.profile)
            case "augmentation":
                this.client.UseCurrencyOnItem("Augmentation", this.profile)
            case "alchemy":
                this.client.UseCurrencyOnItem("Alchemy", this.profile)
            case "chaos":
                this.client.UseCurrencyOnItem("Chaos", this.profile)
            case "essence":
                this.client.UseCurrencyOnItem("Essence", this.profile)
            case "scouringAlchemy":
                this.client.UseScouringAlchemy(this.profile)
            case "scouringTransmutation":
                this.client.UseScouringTransmutation(this.profile)
            case "scouringEssence":
                this.client.UseCurrencyOnItem("Scouring", this.profile)
                this.client.RandomSleep(this.profile)
                this.client.UseCurrencyOnItem("Essence", this.profile)
            case "crafting":
                this.client.UseCraftingButton(this.profile)
            default:
                throw Error("Unsupported action: " action)
        }
    }

    StatePayload(state) {
        return Map(
            "profile", this.profile["id"],
            "rarity", state["itemRarity"],
            "primaryCount", state["primaryCount"],
            "secondaryCount", state["secondaryCount"],
            "relativeCount", state["relativeCount"],
            "itemPreview", SubStr(StrReplace(StrReplace(state["itemText"], "`r", " "), "`n", " "), 1, 120)
        )
    }
}
