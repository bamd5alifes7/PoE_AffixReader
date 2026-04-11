# PoE_AffixReader v2

這版是以 AutoHotkey v2 重構的整合版本，目標是把原本分散的多支腳本收斂成：

- 一套共用核心
- 多個可切換的 profile
- 比較完整的 log 機制

## 啟動方式

1. 安裝 AutoHotkey v2。
2. 執行 [`PoE_AffixReader_v2.ahk`](..\PoE_AffixReader_v2.ahk)。

## 熱鍵

- `F4`：開始目前 profile
- `F7`：記錄通貨或工藝按鈕座標
- `F8`：開啟 profile picker，直接從清單選擇
- `F9`：查看目前 profile
- `F10`：編輯目前 profile 的主 affixGroups，一行一條 regex
- `F12`：要求停止

## Log

預設 log 檔沿用 `setting.ini` 裡的 `logFile`；若設定的是相對路徑，會落在專案根目錄。

log 內容包含：

- 啟動了哪個 profile
- 每輪辨識到的稀有度與詞綴符合數
- 每次選到的 action
- 出錯時的例外資訊

## 目前內建的 profile

- `alteration_single_or_aug_two`：改造增幅雙詞版；先用改造洗，出 1 條目標詞後會補增幅，湊到同組 2 條目標詞才停。
- `alteration_aug_single`：增幅單詞版，主要用在目標 1 詞；改造後只要出現任一目標詞就直接停，不會強制再點增幅。
- `alteration_aug_relative_check`
- `chaos_cycle`
- `essence_cycle`
- `scouring_alchemy_cycle`
- `scouring_alchemy_secondary`
- `crafting_cycle`

這些 profile 是依照舊版腳本當下內容搬過來的第一版設定。後續如果要新增模式，建議直接在 [`v2\Core\ProfileRegistry.ahk`](.\Core\ProfileRegistry.ahk) 裡新增。
