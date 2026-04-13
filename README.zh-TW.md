# PoE_AffixReader v2

[Project Overview](https://github.com/bamd5alifes7/PoE_AffixReader/blob/main/README.md)  
[English Guide](https://github.com/bamd5alifes7/PoE_AffixReader/blob/main/README.en.md)

這是此專案的 AutoHotkey v2 版本。

目前包含：
- dashboard 式主介面
- profile 系統
- profile 層級的 group set
- 可編輯的主要詞綴群組
- 方便除錯的 log 輸出

## 執行方式

1. 安裝 AutoHotkey v2。
2. 執行 `PoE_AffixReader_v2.ahk`。

## 開始前

- 程式會在每次通貨操作前後複製當前物品文字，並把複製到的內容與你設定的詞綴規則做比對。
- 使用前請先關閉或停用會干擾滑鼠、鍵盤自動化，或會影響物品複製行為的工具。
- 同一時間只建議執行一種 crafting 流程。
- 預設座標是依 2560x1440 的配置調整；如果你的介面不同，請先重新擷取座標。

## Dashboard

程式啟動後會開啟主視窗，包含四個分頁：
- `Home`：目前啟用的 profile、狀態與快捷操作
- `Profiles`：切換 profile、group set，並查看設定
- `Coordinates`：編輯已儲存座標，或使用擷取工具
- `Log`：預覽最新 log 內容

## 快捷鍵

- `F4`：啟動目前的 profile
- `F7`：把目前滑鼠位置寫入 `settings.json`
- `F8`：開啟 profile 選擇器
- `F9`：顯示 dashboard
- `F10`：編輯目前 group set 的 primary、secondary、relative `affixGroups`
- `F12`：請求停止

## 基本操作流程

1. 啟動腳本並打開 dashboard。
2. 在 `Profiles` 分頁選擇要使用的 crafting profile。
3. 如果該 profile 有多個 group set，切到你要用的那一組。
4. 在 `Coordinates` 分頁用 `F7` 或介面把通貨與 crafting 按鈕座標存好。
5. 確認 profile 的目標數值與 affix 群組設定。
6. 回到遊戲後按 `F4` 開始執行。
7. 想停止時按住 `F12`。

## Profiles 與設定檔位置

- 內建 profiles 會從 `v2/profiles/default/*.json` 載入。
- 使用者設定存放在 `v2/profiles/user/settings.json`。
- profile 覆寫資料存放在 `v2/profiles/user/overrides.json`。
- 即使某個內建 profile 只有一組預設條件，也會統一使用 `groupSets` 結構。

## 詞綴比對說明

- `targetAffixNum` 代表至少要命中幾個目標條件，流程才會停止。
- 有些 profile 也會使用 `targetSecondAffixNum` 來要求 secondary 群組命中數。
- 比對是向上相容的：如果需求是 `1` 個，但實際命中 `2` 個，仍然會視為成功並停止。
- 比對使用 regex 風格字串，因此你可以寫精確文字、數值範圍，或多種變化的條件。

範例：

```text
"(46|47|48)% Lightning Resistance"
"(110|111|112|113|114|115|116|117|118|119) maximum Life"
"Adds [0-9]* to [0-9]* Fire Damage"
```

撰寫 pattern 時建議：

- 盡量讓關鍵字夠明確，避免誤判。
- 如果同樣文字可能出現在裝備名稱、需求、或其他詞綴內，請補上更多上下文或數字限制。
- 想表示一般文字時，記得跳脫 regex 特殊字元，例如 `+` 要寫成 `\+`。
- 若某個模糊寫法太容易誤判，優先改成更完整的片段或更明確的數值範圍。

跳脫字元範例：

```text
"\+(3[6-9]|4[0-1])% to Cold Resistance"
```

## Group Set 與多條件組合

- 一個 profile 可以有多個 `groupSets`，每組裡又可包含 primary、secondary、relative 群組。
- 如果你想把多套目標條件包在同一個 profile 底下快速切換，就適合使用 group set。
- 一個 group 內可放多個可接受的 pattern。
- 多個 group 可以用來描述你希望物品同時滿足的條件組合。
- relative groups 適合處理某些輔助詞綴出現時，需要特殊流程的情況。

## 座標設定

- 通貨座標與 crafting 按鈕位置會儲存在 `v2/profiles/user/settings.json`。
- 如果預設座標不符合你的遊戲配置，請用 `F7` 重新擷取，或在 `Coordinates` 分頁中更新。
- `F7` 適合快速記錄目前滑鼠位置，不需要手動打開 JSON。

## 延遲與穩定性

常用的時間參數會依 profile 設定：

- `clipboardDelay`：最重要的延遲，用來等遊戲狀態更新後再複製物品資訊
- `pingDelay`：動作之間的小幅額外等待
- `conformDelay`：正式判定詞綴前的等待
- `debugDelay`：放慢流程，方便肉眼觀察
- `mouseSpeed`：自動點擊時的滑鼠移動速度

如果你覺得流程不穩：

- 先優先調高 `clipboardDelay`
- 檢查 log 內容，看是否有複製到不完整或過期的物品狀態
- 確定 `clipboardDelay` 穩定後，再去微調其他較小的延遲值

## Log 與驗證

- 每次執行都會把除錯資訊寫到 `log_affix_v2.txt`。
- 如果程式太早停下來、漏判、或讀到錯誤的物品狀態，第一步就是先看 log。
- 無效的 regex pattern 會在儲存前被擋下，profile override 也會在啟動與 reload 時再次驗證。
- 如果更新後的設定或 overrides 無效，reload 會還原到前一份仍可運作的記憶體狀態。

## 補充

- dashboard 的設計是要和既有快捷鍵操作並存。
- affix editor 會儲存目前 active set 的 primary、secondary 與 relative `affixGroups`。
- `Profiles` 分頁只會在對應流程安全支援的 profile 類型上，開放可編輯的數值目標。
- 使用 relative group 的 profile 可以設定 relative match 的行為。

## 核心結構

v2 程式碼依職責拆分，讓主程式更專注在 UI 與整體串接。

- `v2/Core/App.ahk`：程式啟動、主視窗建立、事件綁定與高層協調
- `v2/Core/AppStateLoader.ahk`：重新載入使用者 JSON 設定、重建 profiles，並在失敗時回滾
- `v2/Core/RunController.ahk`：啟動 profile、處理停止請求與執行結束清理
- `v2/Core/DashboardController.ahk`：刷新 `Home` 與 `Log` 分頁
- `v2/Core/ProfilePanelController.ahk`：刷新 `Profiles` 分頁、同步控制項並儲存設定變更
- `v2/Core/CoordinatePanelController.ahk`：更新 `Coordinates` 分頁並處理擷取與儲存流程
- `v2/Core/ProfilePresenter.ahk`：整理目標摘要、profile 細節與 dashboard 顯示文字
- `v2/Core/ProfileCapabilities.ahk`：決定各種 profile 類型可編輯哪些設定
- `v2/Core/ProfileInputValidator.ahk`：驗證 profile 數值輸入與完整 profile/set 資料
- `v2/Core/PatternValidator.ahk`：在寫入前檢查 regex pattern 是否有效
- `v2/Core/LogPreviewReader.ahk`：安全讀取目前 log 的預覽內容
- `v2/Core/ProfileRegistry.ahk`：定義內建 profiles，並統一 group/set 結構
- `v2/Core/ProfileOverrides.ahk`：載入與儲存 `v2/profiles/user/overrides.json`
- `v2/Core/CraftingEngine.ahk`、`v2/Core/PoeClient.ahk`、`v2/Core/AffixMatcher.ahk`：核心 crafting 流程、遊戲互動與詞綴比對

## 開發修改入口

如果你要擴充或調整功能，通常可以從這些位置開始：

- 新增或修改內建 profiles：`v2/Core/ProfileRegistry.ahk`
- 修改 `v2/profiles/user/overrides.json` 的保存方式：`v2/Core/ProfileOverrides.ahk`
- 修改 dashboard、profile、coordinate 分頁行為：對應的 `*Controller.ahk`
- 只調整顯示文字或摘要格式：`v2/Core/ProfilePresenter.ahk`
- 修改輸入驗證或 regex 驗證規則：`v2/Core/ProfileInputValidator.ahk` 與 `v2/Core/PatternValidator.ahk`
- 修改實際 crafting 流程或停止邏輯：`v2/Core/RunController.ahk` 與 `v2/Core/CraftingEngine.ahk`
