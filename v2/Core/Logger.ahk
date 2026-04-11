class AffixLogger {
    __New(filePath, maxBytes := 5 * 1024 * 1024) {
        this.filePath := filePath
        this.maxBytes := maxBytes
        this.writeRetries := 2
        this.retryDelayMs := 10
        SplitPath(filePath, , &dirPath)
        if dirPath != "" {
            DirCreate(dirPath)
        }
    }

    Log(level, eventName, data := "") {
        line := Format("{1} [{2}] {3}", FormatTime(, "yyyy-MM-dd HH:mm:ss"), level, eventName)
        if IsObject(data) {
            line .= " | " . this.SerializeValue(data)
        } else if data != "" {
            line .= " | " . this.Sanitize(data)
        }
        this.AppendWithRetry(line . "`r`n")
    }

    LogError(eventName, err, data := "") {
        payload := Map(
            "message", err.Message,
            "what", err.What,
            "extra", err.Extra,
            "file", err.File,
            "line", err.Line
        )
        if IsObject(data) {
            for key, value in data {
                payload[key] := value
            }
        } else if data != "" {
            payload["data"] := this.Sanitize(data)
        }
        this.Log("ERROR", eventName, payload)
    }

    CheckSize() {
        if !FileExist(this.filePath) {
            return
        }
        if FileGetSize(this.filePath) <= this.maxBytes {
            return
        }

        backupPath := this.filePath . ".1"
        if FileExist(backupPath) {
            FileDelete(backupPath)
        }
        FileMove(this.filePath, backupPath, true)
        this.Log("INFO", "log_rotated", backupPath)
    }

    Sanitize(value) {
        text := value . ""
        text := StrReplace(text, "`r", "\r")
        text := StrReplace(text, "`n", "\n")
        return text
    }

    SerializeValue(value) {
        if value is Map {
            return this.SerializeMap(value)
        }
        if value is Array {
            output := "["
            for index, item in value {
                if index > 1 {
                    output .= ", "
                }
                output .= this.SerializeValue(item)
            }
            output .= "]"
            return output
        }
        return this.Sanitize(value)
    }

    SerializeMap(data) {
        output := ""
        for key, value in data {
            if output != "" {
                output .= " | "
            }
            output .= key . "=" . this.SerializeValue(value)
        }
        return output
    }

    AppendWithRetry(text) {
        loop this.writeRetries {
            try {
                FileAppend(text, this.filePath, "UTF-8")
                return
            } catch as err {
                if err.Extra != 32 || A_Index >= this.writeRetries {
                    throw err
                }
                Sleep(this.retryDelayMs)
            }
        }
    }
}
