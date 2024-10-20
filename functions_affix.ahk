
alchemyItem()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,請確認視窗已聚焦在POE上!
		return
	}
	IfWinActive,Path of Exile 
	{	
		Send {LShift UP}
		LShiftState := 0
		saveMousePos()
		
		MouseClick, Right,Alchemy_X,Alchemy_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
		
	}
	return
}



augmentationItem()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,請確認視窗已聚焦在POE上!
		return
	}
	IfWinActive,Path of Exile 
	{	
		Send {LShift UP}
		LShiftState := 0
		saveMousePos()
		MouseClick, Right,Augmentation_X,Augmentation_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
	}
	return
}

regalItem()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,請確認視窗已聚焦在POE上!
		return
	}
	IfWinActive,Path of Exile 
	{	
		Send {LShift UP}
		LShiftState := 0
		saveMousePos()
		MouseClick, Right,Regal_X,Regal_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
	}
	return
}

scouringTransmutation()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,請確認視窗已聚焦在POE上!
		return
	}
	IfWinActive,Path of Exile 
	{	
		Send {LShift UP}
		LShiftState := 0
		SaveMousePos()
		MouseClick, Right,Scouring_X,Scouring_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
		Random, rand, %randomMin%, %randomMax%
		sleep % rand + 20 
		MouseClick, Right,Transmutation_X,Transmutation_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
		Random, rand, %randomMin%, %randomMax%
		sleep % rand + 20 
	}
	return
}

scouringAlchemy()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,請確認視窗已聚焦在POE上!
		return
	}
	IfWinActive,Path of Exile 
	{	
		Send {LShift UP}
		LShiftState := 0
		SaveMousePos()
		MouseClick, Right,Scouring_X,Scouring_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
		Random, rand, %randomMin%, %randomMax%
		sleep % rand + 20 
		MouseClick, Right,Alchemy_X,Alchemy_Y,1,delay
		MouseClick, Left,ItemPos[0],ItemPos[1],1,delay
		Random, rand, %randomMin%, %randomMax%
		sleep % rand + 20 
	}
	return
}

saveCoordinatesTool()
{
	IfWinnotActive,Path of Exile
	{
		MsgBox,Please make sure the window is focused on POE!`r`n請確認視窗已聚焦在POE上!
		return
	}
	MouseGetPos, thisPosX, thisPosY
	;1=改造,2=增幅,3=重鑄,4=富豪,5=蛻變,6=點金,7=混沌,8=精髓
	PosX := ["Alteration_X","Augmentation_X","Scouring_X","Regal_X","Transmutation_X","Alchemy_X","Chaos_X","Essence_X"]
	PosY := ["Alteration_Y","Augmentation_Y","Scouring_Y","Regal_Y","Transmutation_Y","Alchemy_Y","Chaos_Y","Essence_Y"]
	InputBox, affixID,其他解析度通貨座標指定工具, 座標[ %thisPosX% `, %thisPosY% ]`r`n請輸入此座標之通貨ID`n1=改造 `, 2=增幅 `, 3=重鑄 `, 4=富豪 `, 5=蛻變 `, 6=點金`, 7=混沌`, 8=精髓`r`n若你確定此物品不為4連以上物品，可改點金石的座標，把束縛石當點金石用。`r`n精髓部分可設置任意精髓座標。,,450,250
	if not ErrorLevel
	{
		checkAffixID := RegExMatch(affixID, "[1-8]$")
		if checkAffixID = 1
		{
			iniWrite,% thisPosX, setting.ini, coordinate, % PosX[affixID]
			iniWrite,% thisPosY, setting.ini, coordinate, % PosY[affixID]
		}
		else
		{
			MsgBox,請輸入正確的通貨ID
		}
		;讀取ini
		readIni()
	}	
	return
}

saveMousePos()
{
	
	MouseGetPos,PosX,PosY
	ItemPos[0] := PosX
	ItemPos[1] := PosY
	return
}

getConformAffix()
{
	tempTarget := targetAffixNum
	found := 0
	loop , %tempTarget%
	{
		;MsgBox ,tempTarget `= %tempTarget%
		for  X_index, ele in affix
		{	
			found = 0
			if % affix[X_index]._MaxIndex() < targetAffixNum
			{
				MsgBox 有組詞綴過少
				continue			
			}			
			for Y_index, ele in affix[X_index]
			{				
				;MsgBox,%index%
				index := % affix[X_index,Y_index]
				FoundPos := % RegExMatch(clipboard ,index)
				if FoundPos > 0
				{
					;MsgBox,%index%
					found := % found + 1
				}
			}
			if % found >= tempTarget
			{
				return found
			}
		}
		tempTarget := % tempTarget - 1
	}
	
	return 0
}

getItemRarity()
{
	If InStr(clipboard,"稀有度: 普通") or InStr(clipboard,"Rarity: Normal")
		return 0
	If InStr(clipboard,"稀有度: 魔法") or InStr(clipboard,"Rarity: Magic")
		return 1
	If InStr(clipboard,"稀有度: 稀有") or InStr(clipboard,"Rarity: Rare")
		return 2
	If InStr(clipboard,"稀有度: 傳奇") or InStr(clipboard,"Rarity: Unique")
		return 3	
}

readIni()
{	
	;從setting.ini中抓取設定，若沒有資料則使用預設值。預設解析度 default : 2560*1440
	IniRead, Alteration_X, setting.ini , coordinate, Alteration_X, 116
	IniRead, Alteration_Y, setting.ini , coordinate, Alteration_Y, 340
	IniRead, Augmentation_X, setting.ini , coordinate, Augmentation_X, 233
	IniRead, Augmentation_Y, setting.ini , coordinate, Augmentation_Y, 391
	IniRead, Scouring_X, setting.ini , coordinate, Scouring_X, 581
	IniRead, Scouring_Y, setting.ini , coordinate, Scouring_Y, 694
	IniRead, Regal_X, setting.ini , coordinate, Regal_X, 430
	IniRead, Regal_Y, setting.ini , coordinate, Regal_Y, 336
	IniRead, Transmutation_X, setting.ini , coordinate, Transmutation_X, 59
	IniRead, Transmutation_Y, setting.ini , coordinate, Transmutation_Y, 338
	IniRead, Alchemy_X, setting.ini , coordinate, Alchemy_X, 485
	IniRead, Alchemy_Y, setting.ini , coordinate, Alchemy_Y, 270
	IniRead, Chaos_X, setting.ini , coordinate, Chaos_X, 725
	IniRead, Chaos_Y, setting.ini , coordinate, Chaos_Y, 373	
	IniRead, Essence_X, setting.ini , coordinate, Essence_X, 68
	IniRead, Essence_Y, setting.ini , coordinate, Essence_Y, 313
	IniRead, logFile, setting.ini , coordinate, logFile,%A_ScriptDir%\log_affix.txt
	
	return
}

RunAsAdmin()
{
	Loop, %0%  
  	{
		param := %A_Index%  
		params .= A_Space . param
  	}
	ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA" 
	if not A_IsAdmin
	{
		If A_IsCompiled
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
		Else
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . A_Space . params, str, A_WorkingDir, int, 1)
		ExitApp
	}
}


logClipboard() {

    FormatTime, timeString,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timeString%`r`nItemData(物品資訊):`r`n%clipboard%ConformData(辨識資料):`r`nconformNum(符合目標的數量) `= %conformNum%`r`nitemRarity(物品稀有度) `= %itemRarity%`r`n`r`n, %logFile%
}

logFileSizeCheck()
{
	logFilePath = %A_ScriptDir%\%logFile%
	; 檢查log檔案大小
	FileGetSize, fileSize, %logFilePath%
	
	;開發時檢查用的
	;MsgBox,fileSize = %fileSize%`nlogMaxSize=%logMaxSize%
	
	; 如果檔案大小超過限制，提示使用者
	if (fileSize > logMaxSize)
	{
		MsgBox, 4, log_affix超過大小, log_affix.txt(操作紀錄檔)的大小已經超過 5MB。為了環境整潔，建議刪除檔案。是否刪除？若刪除，下次使用時會建立新的logFile檔。
		IfMsgBox, Yes
		{
			
			FileDelete, %logFilePath%
			MsgBox, 已刪除logFile。下次使用時會建立新的logFile檔。
		}
	}
}

getConformRelativeAffix()
{
	tempTarget := targetAffixNum
	found := 0
	loop , %tempTarget%
	{
		;MsgBox ,tempTarget `= %tempTarget%
		for  X_index, ele in RelativeAffix
		{	
			found = 0
			if % RelativeAffix[X_index]._MaxIndex() < targetAffixNum
			{
				MsgBox 有組詞綴過少
				continue			
			}			
			for Y_index, ele in RelativeAffix[X_index]
			{				
				;MsgBox,%index%
				index := % RelativeAffix[X_index,Y_index]
				FoundPos := % RegExMatch(clipboard ,index)
				if FoundPos > 0
				{
					;MsgBox,%index%
					found := % found + 1
				}
			}
			if % found >= tempTarget
			{
				return found
			}
		}
		tempTarget := % tempTarget - 1
	}
	
	return 0
}

getConformAssociateAffix()
{
	tempTarget := targetAffixNum
	found := 0
	loop , %tempTarget%
	{
		;MsgBox ,tempTarget `= %tempTarget%
		for  X_index, ele in AssociateAffix
		{	
			found = 0
			if % AssociateAffix[X_index]._MaxIndex() < targetAffixNum
			{
				MsgBox 有組詞綴過少
				continue			
			}			
			for Y_index, ele in AssociateAffix[X_index]
			{				
				;MsgBox,%index%
				index := % AssociateAffix[X_index,Y_index]
				FoundPos := % RegExMatch(clipboard ,index)
				if FoundPos > 0
				{
					;MsgBox,%index%
					found := % found + 1
				}
			}
			if % found >= tempTarget
			{
				return found
			}
		}
		tempTarget := % tempTarget - 1
	}
	
	return 0
}

getConformSecondAffix()
{
	tempTarget := targetSecondAffixNum
	found := 0
	loop , %tempTarget%
	{
		;MsgBox ,tempTarget `= %tempTarget%
		for  X_index, ele in secondAffix
		{	
			found = 0
			if % secondAffix[X_index]._MaxIndex() < targetSecondAffixNum
			{
				MsgBox 有組詞綴過少
				continue			
			}			
			for Y_index, ele in secondAffix[X_index]
			{				
				;MsgBox,%index%
				index := % secondAffix[X_index,Y_index]
				FoundPos := % RegExMatch(clipboard ,index)
				if FoundPos > 0
				{
					;MsgBox,%index%
					found := % found + 1
				}
			}
			if % found >= tempTarget
			{
				return found
			}
		}
		tempTarget := % tempTarget - 1
	}
	
	return 0
}