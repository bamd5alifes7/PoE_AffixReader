class LogPreviewReader {
    static Read(logFilePath, maxLines := 40, maxChars := 6000) {
        if !FileExist(logFilePath) {
            return "Log file not found yet. Run a profile or wait for the first log write."
        }

        try {
            text := FileRead(logFilePath, "UTF-8")
        } catch as err {
            return "Unable to read log file.`r`n" err.Message
        }

        if StrLen(text) > maxChars {
            text := SubStr(text, StrLen(text) - maxChars + 1)
        }

        lines := StrSplit(text, "`n", "`r")
        if lines.Length <= maxLines {
            return text
        }

        startIndex := lines.Length - maxLines + 1
        preview := ""
        loop maxLines {
            if A_Index > 1 {
                preview .= "`r`n"
            }
            preview .= lines[startIndex + A_Index - 1]
        }
        return preview
    }
}
