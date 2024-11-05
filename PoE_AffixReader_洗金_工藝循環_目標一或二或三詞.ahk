
#SingleInstance force
#Include functions_affix.ahk


;===============================================================================
; affix:
; 詞墜設定區
;===============================================================================

/*
設定教學請詳閱"使用教學.txt"，此處不再贅述。
*/

;------設定目標詞綴------
global affix := Array()
;火傷星團
;affix.Push(["Sadist","Corrosive Elements","Doryani's Lesson","Disorienting Display","Prismatic Heart","Widespread Destruction","Master of Fire","Smoking Remains","Cremator","Burning Bright"])
;混傷星團
;affix.Push(["Grim Oath","Overwhelming Malice","Touch of Cruelty","Unwaveringly Evil","Unspeakable Gifts","Dark Ideation","Unholy Grace","Wicked Pall"])
;冰傷星團
affix.Push(["Sadist","Corrosive Elements","Doryani's Lesson","Disorienting Display","Prismatic Heart","Widespread Destruction","Snowstorm","Blanketed Snow","Cold to the Core","Cold-Blooded Killer","Inspired Oppression","Deep Chill","Blast-Freeze","Stormrider"])


;===============================================================================
; Settings:
; 數值設定由readIni設定於settings.ini文件中，也可手動修改
;===============================================================================

global targetAffixNum := 2
;default : 3 目標詞墜的數量

global allowRare2Affix := 1 
;default : 1 是否允許兩詞後富豪

global delay := 2 
;default : 2 滑鼠的移動速度，範圍1~10。數字越少越快。


global clipboardDelay := 140 
;default : 150 單位毫秒。對物品操作後，複製物品資訊前的Delay，目的是等待遊戲反應。是最重要的延遲屬性。

/*
會檢查 1.操作後的物品狀態和操作前不同 2.不是稀有度普通的物品，才進行後續的判斷動作。
若數字設定很低，程式其實也會重複複製動作，直到伺服器正確回應為止。只是動作會比較傻屌。

可檢查log紀錄是否有錯誤資料。如itemRarity = 0的資料，代表操作完的複製動作完成後，遊戲卻還沒給出點金石的回應，所以複製到了錯誤的物品狀態。例如稀有度為普通的物品。
若排除程式卡控的功能，測試實際伺服器回應速度。我在國際服的clipboardDelay是在150~180之間。可再依照實際的網路及電腦狀況進行調整。

garena時代的台服設定50很穩偏慢。
*/


global pingDelay := 20 
;default : 20 取得詞綴判斷之前的延遲。緩衝用，此處有就好意義不大。

global conformDelay := 20 
;default : 20 詞綴判斷前延遲。緩衝用。


global debugModeDelay := 10 
;default : 0 用來放慢每一輪的動作，debug用的。

global logFile
;logFile的路徑與檔案名稱

global logMaxSize := 5*1024*1024
; 設定logFile檔案的大小上限（以字節為單位，5MB = 5 * 1024 * 1024 字節）

global randomMin = 20
;在動作間會有一個亂數delay，這個delay是20ms的基礎間隔時間加上亂數，此處設置亂數的最小值。
global randomMax = 40
;在動作間會有一個亂數delay，這個delay是20ms的基礎間隔時間加上亂數，此處設置亂數的最大值。

global conformNum
global itemRarity

global ItemPos := [0,0]
global LShiftState := 0
global Increased := 0
global mouseState := 0

;從setting.ini中抓取設定，若沒有資料則使用readIni()中的預設值。預設解析度 default : 2560*1440
global Alteration_X
global Alteration_Y 
global Augmentation_X 
global Augmentation_Y 
global Scouring_X 
global Scouring_Y  
global Regal_X 
global Regal_Y  
global Transmutation_X 
global Transmutation_Y  
global Alchemy_X 
global Alchemy_Y 
global Chaos_X 
global Chaos_Y 
global Essence_X 
global Essence_Y  
global CraftingButton_X 
global CraftingButton_Y  

;-----------DON'T TOUCH-----------以下勿碰-----------

;將執行方式改為系統管理員
RunAsAdmin()

/*
;檢查是否生效
if A_IsAdmin
	{
		MsgBox, 你正在以系統管理員權限運行此腳本。
	}
else
	{
		MsgBox, 你並未以系統管理員權限運行此腳本。
	}
*/

readIni()
MsgBox, [F4]開始速刷`r`n[F7]通貨位置設定工具`r`n[F12]長案強制結束`r`n開始前請確認座標已設好且視窗已聚焦在POE上`r`n並將滑鼠移動到目標裝備上`r`n原作:加速器(Acc)`r`n修訂:bamd5alifes7


F4:: CraftingLoop()
F7:: saveCoordinatesTool()



CraftingLoop()
	{
		
	;檢查運作時是否處於Path of Exile視窗
	IfWinnotActive,Path of Exile
		{
			MsgBox,Please make sure the window is focused on POE!`r`n請確認視窗已聚焦在POE上！
			return
		}
	
	;紀錄增幅石的使用狀態
	Increased = 0
	;紀錄左Shift的使用狀態
	LShiftState = 0
	;紀錄游標上捏物品的使用狀態
	mouseState = 0
	
	;把游標的xy存到ItemPos[0]和ItemPos[1]
	saveMousePos()
	
	;行前檢查放在迴圈外。

	;複製物品資訊
	send ^c
	send ^c
	
	;檢查物品的稀有度
	itemRarity = % getItemRarity()
	
	;取得詞綴判斷
	conformNum = % getConformAffix()
	
	;詞綴判斷前延遲。緩衝用。
	sleep, %conformDelay%
	
	;根據需求內容，行前檢查
	if % ConformNum = targetAffixNum
		{
		MsgBox,The item has met the target requirements. To avoid making mistakes, please modify the item manually before using this function.`r`n物品已符合目標要求。為了防呆，請手動修改物品詞墜再使用此功能。
		return
		}
			
	;正式動作
	loop
		{
		
		IfWinActive,Path of Exile 
			{
			;用以中斷程式
			if GetKeyState("F12", "P") 
				{
					Send {LShift Up}
					break
				}		
			
			;保留剪貼簿內容，用來檢查操作後有沒有變化
			clipboardold = %Clipboard%		
						
			;若物品稀有度不是稀有,丟出提示訊息
			if (itemRarity != 2 )
				{
				MsgBox,The itemrarity is not rare, so the crafting will be stuck. Please alchemy item yourself.`r`n物品並非稀有，工藝台將會無法卡住，請自行點金。
				return
				}
						
			;確認此前的程式狀態。Shift沒按下、滑鼠沒捏東西、沒用過增幅石,點選工藝按鈕
			else if (LShiftState = 0 && mouseState = 0 && Increased = 0)
				{					
				craftingButton()

				;操作後，複製物品前Delay，目的是等待遊戲反應
				sleep, %clipboardDelay%
				
				;複製物品資訊，檢查是否和操作前一樣，不一樣才離開。最大10圈，因為低機率操作完會一模一樣。
				loop, 10
					{
					send ^c
					send ^c
					;檢查物品的稀有度
					itemRarity = % getItemRarity()
					;檢查是否和操作前一樣，不一樣才離開。因可能有重鑄動作，再加上itemRarity不可為普通的條件。
					;括號內自動為表達式所以無須用%來表示變數。另外，Clipboard是內建變量，即使括號外也不可被%包圍，包圍時剪貼簿內簡短語句卻可行，句子一長就爆炸。
					if (%clipboardold% != Clipboard) and (itemRarity != 0)
						{
						break
						}
					}
				
				}
			
			;取得詞綴判斷之前的延遲。緩衝用，此處有就好意義不大。
			sleep, %pingDelay%

			;取得詞綴判斷 getConformAffix
			conformNum = % getConformAffix()		
			itemRarity = % getItemRarity()
			;MsgBox , conformNum `= %conformNum%`r`nitemRarity `= %itemRarity%
			
			;詞綴判斷前延遲。緩衝用。
			sleep, %conformDelay%
			
			;判斷前把資料寫進log檔，方便檢查
			logClipboard()
			
			;根據ConformNum符合詞綴數、itemRarity裝備稀有度、targetAffixNum希望的目標詞綴數進行動作
			
			;骰出二詞、目標一詞，停
			if % ConformNum = 1
			{
				if % itemRarity = 2
				{
					if % targetAffixNum = 1
					{
						break
					}
				}
			}			
			
			;骰出二詞、目標小於等於二詞，停
			if % ConformNum = 2
			{
				if % itemRarity = 2
				{
					if % targetAffixNum <= 2
					{
						break
					}
				}
			}
			
			
			;骰出三詞、目標小於等於三詞，停
			if % ConformNum = 3
				{
				if % itemRarity = 2
					{
					if % targetAffixNum <= 3
						{
							break
						}
					}
				}

			;假如這個世界發瘋，骰出大於三，總之先break給使用者自行判斷
			if % ConformNum > 3
				{
				break
				}

			;額外延遲
			sleep, %debugModeDelay%			
			}
		}
		
	;退出前檢查LOG檔會不會太大，預設為5MB
	logFileSizeCheck()
	
	Send {LShift Up}
	return
}