
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
affix.Push(["(24|25|26)% 持續傷害加成"])


;邏輯解釋：當改造完沒有出現目標詞墜時，會使用增幅石。
;此處設置不使用增幅石的詞綴條件。例如與目標詞綴相同前後的詞墜。
/*
例如目標詞墜是後綴，當已出現下列屬於後綴類型的詞墜時不使用增幅石。能減少增幅石的浪費並增加運作效率。
在此範例中為後綴。

當前後綴有無法獨特表示的詞綴時，無可避免的會有小浪費，以數值盡量區分即可。

例如武器的前綴與後綴都會有# to Accuracy Rating類型的詞綴。可以前綴的頂roll配上後綴的頂roll來表示。
前綴的頂roll： +(175–200) to Accuracy Rating
後綴的頂roll： +(625–780) to Accuracy Rating
表示範例如下，表示了201-799的命中值：
"\+(20[1-9]|2[1-9][0-9]|[3-7][0-9][0-9]) to Accuracy Rating"

*/

;------設定同綴------
global RelativeAffix := Array()
RelativeAffix.Push(["[0-9]* 敏捷","攻擊速度","火焰抗性","冰冷抗性","閃電抗性","混沌抗性","敵人暈眩時間","投射物速度","每擊中一個敵人","擊殺回復生命","擊殺回復魔力","增加 [0-9]*% 暴擊率","全域暴擊加成","額外投射物","能力值需求","全域命中率","使目標中毒","機率造成流血","流血傷害加速","中毒傷害加速","傷害轉換為混沌","擊中鎮壓","機率威嚇敵人"])

/*

關於前後綴可能都有相同的詞綴，導致增幅石砸下去沒變化的問題，需要辨識同時有前後綴的物品狀態：
留待開發的思路：
拆剪貼簿，找特定位置之後的分行符號，確定該物品是否同時有兩行以上的詞綴敘述，就可推定該物品的狀態是同時有前後綴。
只要排除這種物品，就可以避免增幅石砸下去沒變化，也就無法確定是否真的有複製到正確狀態的情境。

以往的思路：
舊思路是再設置一個反綴AssociateconformNum，圈定能使用增幅石的範圍。
這樣在情境表示
前綴： +(1–200) to Accuracy Rating
後綴： +(201–799) to Accuracy Rating

兩者其一大於2或皆等於1，表示同時有前後綴。
但設置太繁瑣，已刪除

*/

;===============================================================================
; Settings:
; 數值設定由readIni設定於settings.ini文件中，也可手動修改
;===============================================================================

global targetAffixNum := 1
;default : 3 目標詞墜的數量

global allowRare2Affix := 1 
;default : 1 是否允許兩詞後富豪

global delay := 2 
;default : 2 滑鼠的移動速度，範圍1~10。數字越少越快。


global clipboardDelay := 180 
;default : 150 單位毫秒。對物品操作後，複製物品資訊前的Delay，目的是等待遊戲反應。是最重要的延遲屬性。
;點增幅石若沒做同綴異綴的檢查，會有操作完物品無改變的狀況。此處延遲就非常需要。

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
global mouseState := 0 ;[勿動] 0=空,1=改造,2=增幅,3=重鑄,4=富豪,5=蛻變,6=點金,7=混沌, 8=精髓

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
MsgBox, [F4]開始速刷`r`n[F7]通貨位置設定工具`r`n[F12]長案強制結束`r`n開始前請確認座標已設好且視窗已聚焦在POE上`r`n並將滑鼠移動到目標裝備上`r`n原作:加速器(Acc) 修訂:吟月氏樹海


F4:: alterationAugmentationLoopAssociateCheck()
F7:: saveCoordinatesTool()



alterationAugmentationLoopAssociateCheck()
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
			
			;如果滑鼠上捏著改造，持續洗
			if(mouseState = 1)
				{

				MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
				
				;操作後，複製物品前Delay，目的是等待遊戲反應。這是最重要的延遲屬性。				
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
					if (clipboardold != Clipboard && itemRarity != 0)
						{
						break
						}
					}
				}

			;滑鼠上沒東西，物品稀有度為普通，丟一顆蛻變石
			else if (LShiftState = 0 && mouseState = 0 && itemRarity = 0 && Increased = 0)
			{		
				;確保滑鼠上沒捏東西
				Send {LShift Up}			
				MouseClick, Right,Transmutation_X,Transmutation_Y,1,delay
				MouseClick, Left,ItemPos[0],ItemPos[1],1,delay

				;操作後，複製物品前Delay，目的是等待遊戲反應。這是最重要的延遲屬性。
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
					if (clipboardold != Clipboard && itemRarity != 0)
						{
						break
						}
					}
			}


			;滑鼠上沒東西，物品狀態是魔法的話，點改造並把改造捏在手上
			else if (LShiftState = 0 && mouseState = 0 && itemRarity = 1 && Increased = 0)
				{		
				Send {LShift Up}
				Send {LShift Down}
				LShiftState := 1			
				MouseClick, Right,Alteration_X,Alteration_Y,1,delay
				mouseState = 1 
				MouseClick, Left,ItemPos[0],ItemPos[1],1,delay

				;操作後，複製物品前Delay，目的是等待遊戲反應。這是最重要的延遲屬性。
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
					if (clipboardold != Clipboard && itemRarity != 0)
						{
						break
						}
					}
				}
				
			;若滑鼠為空,物品為稀有,重鑄蛻變
			else if (LShiftState = 0 && mouseState = 0 && itemRarity = 3 && Increased = 0)
				{		
				;確保滑鼠上沒捏東西
				Send {LShift Up}	
				
				scouringTransmutation()

				;操作後，複製物品前Delay，目的是等待遊戲反應。這是最重要的延遲屬性。
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
					if (clipboardold != Clipboard && itemRarity != 0)
						{
						break
						}
					}
				}

			;取得詞綴判斷之前的延遲。緩衝用，此處有就好意義不大。
			sleep, %pingDelay%


			;雜詞增幅前，詞綴判斷
			RelativeconformNum = % getConformRelativeAffix()
			conformNum = % getConformAffix()
			itemRarity = % getItemRarity()
			
			;判斷前延遲
			sleep, %conformDelay%
			
			;若沒目標詞綴，也沒同綴，代表可以丟增幅
			if % conformNum = 0
				{
				if % RelativeconformNum = 0
					{
					if % itemRarity = 1
						{
						if Increased = 0
							{
							
							;點增幅石
							augmentationItem()
							;增幅完所以手上沒捏改造石，改滑鼠狀態
							mouseState = 0
							
							;點增幅石的檢查，因同綴設定避開了前後都有的詞，會有操作完物品無改變的狀況。此處延遲就非常需要。
							;操作後，複製物品前Delay，目的是等待遊戲反應。這是最重要的延遲屬性。
							sleep, %clipboardDelay%
							
							send ^c
							send ^c		
								
							}
						}
					}
				}
			
			;若直接丟出目標，停
			else if % conformNum = 1
				{				
				if % itemRarity = 1
					{
					;如果targetAffixNum等於1，代表已經完成目標
					if %  targetAffixNum = 1
						{
						;break前把資料寫進log檔，方便檢查
						logClipboard()
						break
						}
					}
				}

			else if % ConformNum = 2
				{
				if % itemRarity = 1
					{
					;如果targetAffixNum小於等於2，代表已經完成目標
					if % targetAffixNum <= 2
						{
						;break前把資料寫進log檔，方便檢查
						logClipboard()
						break
						}
					}
				}

			;取得詞綴判斷
			AssociateconformNum = % getConformAssociateAffix()
			RelativeconformNum = % getConformRelativeAffix()
			conformNum = % getConformAffix()		
			itemRarity = % getItemRarity()
			;MsgBox , conformNum `= %conformNum%`r`nitemRarity `= %itemRarity%`r`nRelativeconformNum `= %RelativeconformNum%
			
			;判斷後操作前延遲
			sleep, %conformDelay%
			
			;如果雜詞增幅完沒出目標單詞，把代表增幅過的Increased歸零繼續洗，此函式沒使用到此變數做檢查，其實沒差。
			if % ConformNum = 0
				{
				Increased = 0
				}
			
			;如果ConformNum = 1，targetAffixNum又只要1，代表點完增幅後完成目標
			if % ConformNum = 1
				{
				if % itemRarity = 1
					{
					if % targetAffixNum = 1
						{
						break
						}
					}
				}
				
			;如果ConformNum = 2，targetAffixNum又在2以下，代表點完增幅後完成目標。考慮可能目標詞綴同時都有
			else if % ConformNum = 2
				{
				if % itemRarity = 1
					{
					if % targetAffixNum <= 2
						{
						break
						}
					}
				}
				
			;預留一個發瘋狀態下的ConformNum，總之先break
			if % ConformNum >= 3
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

