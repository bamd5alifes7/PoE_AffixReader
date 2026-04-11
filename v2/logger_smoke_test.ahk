#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Core\Logger.ahk

logger := AffixLogger(A_ScriptDir "\logger_smoke_test.log")
logger.Log("INFO", "smoke_test", Map("status", "ok"))
ExitApp
