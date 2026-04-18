class PoeClient {
    __New(settings, logger) {
        this.settings := settings
        this.logger := logger
        this.itemPos := Map("x", 0, "y", 0)
        this.heldCurrency := ""
        this.shiftHeld := false
    }

    EnsureWindowActive() {
        if WinActive("Path of Exile") {
            return true
        }
        MsgBox("Please make sure the window is focused on POE.")
        return false
    }

    SaveItemPos() {
        MouseGetPos(&x, &y)
        this.itemPos["x"] := x
        this.itemPos["y"] := y
        return this.itemPos.Clone()
    }

    CaptureItemText(profile, oldText := "", requireChange := false, action := "", retries := "") {
        if retries = "" {
            retries := profile["captureRetries"]
        }
        retrySleepMs := profile["captureRetrySleepMs"]
        sameStateFallbackAfter := profile["sameStateFallbackAfter"]
        if action = "augmentation" {
            sameStateFallbackAfter := profile["augmentationSameStateFallbackAfter"]
        }
        fallbackText := ""
        fallbackSnapshot := ""
        lastSnapshot := Map(
            "attempt", 0,
            "clipWaitOk", 0,
            "hasRarityHeader", 0,
            "changed", 0,
            "sameAsOld", 0,
            "rarity", -1,
            "requireChange", requireChange ? 1 : 0,
            "oldItemText", oldText,
            "newItemText", ""
        )
        loop retries {
            attempt := A_Index
            A_Clipboard := ""
            Send("^c")
            Sleep(30)
            Send("^c")
            clipWaitOk := ClipWait(profile["clipWaitSeconds"])
            if !clipWaitOk {
                lastSnapshot := Map(
                    "attempt", attempt,
                    "clipWaitOk", 0,
                    "hasRarityHeader", 0,
                    "changed", 0,
                    "sameAsOld", oldText != "" ? 1 : 0,
                    "rarity", -1,
                    "requireChange", requireChange ? 1 : 0,
                    "oldItemText", oldText,
                    "newItemText", ""
                )
                this.logger.Log("DEBUG", "clipboard_capture_retry", lastSnapshot)
                Sleep(retrySleepMs)
                continue
            }

            text := A_Clipboard
            rarity := this.GetItemRarity(text)
            hasRarityHeader := InStr(text, "Rarity:")
            sameAsOld := (oldText != "" && text = oldText)
            changed := !sameAsOld
            lastSnapshot := Map(
                "attempt", attempt,
                "clipWaitOk", 1,
                "hasRarityHeader", hasRarityHeader ? 1 : 0,
                "changed", changed ? 1 : 0,
                "sameAsOld", sameAsOld ? 1 : 0,
                "rarity", rarity,
                "requireChange", requireChange ? 1 : 0,
                "oldItemText", oldText,
                "newItemText", text
            )
            this.logger.Log("DEBUG", "clipboard_capture_attempt", lastSnapshot)

            if hasRarityHeader && (!requireChange || !sameAsOld) {
                return text
            }

            if hasRarityHeader && (!requireChange || attempt >= sameStateFallbackAfter) {
                fallbackText := text
                fallbackSnapshot := lastSnapshot
                if requireChange && sameAsOld && attempt >= sameStateFallbackAfter {
                    this.logger.Log("DEBUG", "clipboard_capture_fallback_same_state", fallbackSnapshot)
                    return fallbackText
                }
            }

            Sleep(retrySleepMs)
        }

        if fallbackText != "" {
            this.logger.Log("DEBUG", "clipboard_capture_fallback_same_state", fallbackSnapshot)
            return fallbackText
        }

        this.logger.Log("ERROR", "clipboard_capture_failed", lastSnapshot)
        throw Error("Failed to capture a new valid item state from clipboard after the action. Check the log for clipboard previews and retry details.")
    }

    GetItemRarity(text) {
        if InStr(text, "Rarity: Normal") {
            return 0
        }
        if InStr(text, "Rarity: Magic") {
            return 1
        }
        if InStr(text, "Rarity: Rare") {
            return 2
        }
        if InStr(text, "Rarity: Unique") {
            return 3
        }
        return -1
    }

    UseCurrencyOnItem(currencyName, profile) {
        this.EnsureWindowActiveOrThrow()
        this.EnsureCurrencyReady(currencyName, profile)
        this.ClickItem(profile)
    }

    UseScouringTransmutation(profile) {
        this.UseCurrencyOnItem("Scouring", profile)
        this.RandomSleep(profile)
        this.UseCurrencyOnItem("Transmutation", profile)
    }

    UseScouringAlchemy(profile) {
        this.UseCurrencyOnItem("Scouring", profile)
        this.RandomSleep(profile)
        this.UseCurrencyOnItem("Alchemy", profile)
    }

    UseCraftingButton(profile) {
        this.ResetHeldCurrency()
        this.EnsureWindowActiveOrThrow()
        this.MoveTo(this.settings["CraftingButton_X"], this.settings["CraftingButton_Y"], profile)
        this.RandomSleep(profile, 30)
        Click("Left")
        this.RandomSleep(profile)
        this.MoveTo(this.itemPos["x"], this.itemPos["y"], profile)
    }

    ClickCurrency(currencyName, profile) {
        coords := this.GetCurrencyPosition(currencyName)
        this.MoveTo(coords["x"], coords["y"], profile)
        this.RandomSleep(profile, 30)
        Click("Right")
        this.RandomSleep(profile)
    }

    ClickItem(profile) {
        this.MoveTo(this.itemPos["x"], this.itemPos["y"], profile)
        this.RandomSleep(profile, 30)
        Click("Left")
        Sleep(profile["clipboardDelay"])
    }

    RandomSleep(profile, baseMs := 20) {
        randomValue := Random(profile["randomMin"], profile["randomMax"])
        Sleep(baseMs + randomValue)
    }

    GetCurrencyPosition(currencyName) {
        switch currencyName {
            case "Alteration":
                return Map("x", this.settings["Alteration_X"], "y", this.settings["Alteration_Y"])
            case "Augmentation":
                return Map("x", this.settings["Augmentation_X"], "y", this.settings["Augmentation_Y"])
            case "Scouring":
                return Map("x", this.settings["Scouring_X"], "y", this.settings["Scouring_Y"])
            case "Regal":
                return Map("x", this.settings["Regal_X"], "y", this.settings["Regal_Y"])
            case "Transmutation":
                return Map("x", this.settings["Transmutation_X"], "y", this.settings["Transmutation_Y"])
            case "Alchemy":
                return Map("x", this.settings["Alchemy_X"], "y", this.settings["Alchemy_Y"])
            case "Chaos":
                return Map("x", this.settings["Chaos_X"], "y", this.settings["Chaos_Y"])
            case "Essence":
                return Map("x", this.settings["Essence_X"], "y", this.settings["Essence_Y"])
            default:
                throw Error("Unknown currency: " currencyName)
        }
    }

    EnsureWindowActiveOrThrow() {
        if !this.EnsureWindowActive() {
            throw Error("Path of Exile window is not active.")
        }
    }

    EnsureCurrencyReady(currencyName, profile) {
        if (this.heldCurrency = currencyName && this.shiftHeld) {
            this.logger.Log("DEBUG", "currency_reused", Map("currency", currencyName))
            return
        }

        if (this.heldCurrency != "" || this.shiftHeld) {
            this.ResetHeldCurrency()
            this.RandomSleep(profile, 30)
        }

        Send("{LShift Down}")
        this.shiftHeld := true
        this.ClickCurrency(currencyName, profile)
        this.heldCurrency := currencyName
        this.logger.Log("DEBUG", "currency_held", Map("currency", currencyName))
    }

    ResetHeldCurrency() {
        if this.shiftHeld {
            Send("{LShift Up}")
        }
        this.shiftHeld := false
        this.heldCurrency := ""
    }

    MoveTo(x, y, profile) {
        MouseMove(x, y, profile["mouseSpeed"])
    }
}
