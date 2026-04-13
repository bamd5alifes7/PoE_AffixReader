class JsonData {
    static LoadFile(path) {
        return JsonData.Parse(FileRead(path, "UTF-8"))
    }

    static SaveFile(path, value, indent := "  ") {
        SplitPath(path, , &dirPath)
        if dirPath != "" {
            DirCreate(dirPath)
        }
        tempPath := path ".tmp"
        try {
            if FileExist(tempPath) {
                FileDelete(tempPath)
            }
        }
        FileAppend(JsonData.Stringify(value, indent) . "`r`n", tempPath, "UTF-8")
        FileMove(tempPath, path, true)
    }

    static Parse(text) {
        parser := JsonData.Parser(text)
        value := parser.ParseValue()
        parser.SkipWhitespace()
        if !parser.AtEnd() {
            throw Error("Unexpected trailing data in JSON.")
        }
        return value
    }

    static Stringify(value, indent := "  ") {
        return JsonData.WriteValue(value, indent, 0)
    }

    static WriteValue(value, indent, level) {
        if value is Map {
            return JsonData.WriteMap(value, indent, level)
        }
        if value is Array {
            return JsonData.WriteArray(value, indent, level)
        }
        if value == true {
            return "true"
        }
        if value == false {
            return "false"
        }
        if value = "" {
            return '""'
        }
        if value is Number {
            return value ""
        }
        return JsonData.WriteString(value . "")
    }

    static WriteMap(mapValue, indent, level) {
        if mapValue.Count = 0 {
            return "{}"
        }

        lines := []
        for key, value in mapValue {
            lines.Push(JsonData.Indent(indent, level + 1) . JsonData.WriteString(key) . ": " . JsonData.WriteValue(value, indent, level + 1))
        }
        return "{`n" . JsonData.Join(lines, ",`n") . "`n" . JsonData.Indent(indent, level) . "}"
    }

    static WriteArray(arrayValue, indent, level) {
        if arrayValue.Length = 0 {
            return "[]"
        }

        lines := []
        for _, value in arrayValue {
            lines.Push(JsonData.Indent(indent, level + 1) . JsonData.WriteValue(value, indent, level + 1))
        }
        return "[`n" . JsonData.Join(lines, ",`n") . "`n" . JsonData.Indent(indent, level) . "]"
    }

    static WriteString(text) {
        escaped := text
        escaped := StrReplace(escaped, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`r", "\r")
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`t", "\t")
        return '"' escaped '"'
    }

    static Indent(indent, level) {
        text := ""
        loop level {
            text .= indent
        }
        return text
    }

    static Join(items, separator) {
        output := ""
        for index, item in items {
            if index > 1 {
                output .= separator
            }
            output .= item
        }
        return output
    }

    class Parser {
        __New(text) {
            this.text := text
            this.length := StrLen(text)
            this.index := 1
        }

        AtEnd() {
            return this.index > this.length
        }

        ParseValue() {
            this.SkipWhitespace()
            if this.AtEnd() {
                throw Error("Unexpected end of JSON input.")
            }

            ch := SubStr(this.text, this.index, 1)
            switch ch {
                case "{":
                    return this.ParseObject()
                case "[":
                    return this.ParseArray()
                case '"':
                    return this.ParseString()
                case "t":
                    this.ExpectLiteral("true")
                    return true
                case "f":
                    this.ExpectLiteral("false")
                    return false
                case "n":
                    this.ExpectLiteral("null")
                    return ""
                default:
                    if ch = "-" || RegExMatch(ch, "\d") {
                        return this.ParseNumber()
                    }
                    throw Error("Unexpected token in JSON: " ch)
            }
        }

        ParseObject() {
            obj := Map()
            this.index += 1
            this.SkipWhitespace()
            if this.Peek() = "}" {
                this.index += 1
                return obj
            }

            loop {
                this.SkipWhitespace()
                key := this.ParseString()
                this.SkipWhitespace()
                this.ExpectChar(":")
                value := this.ParseValue()
                obj[key] := value
                this.SkipWhitespace()
                ch := this.Peek()
                if ch = "}" {
                    this.index += 1
                    return obj
                }
                this.ExpectChar(",")
            }
        }

        ParseArray() {
            arr := []
            this.index += 1
            this.SkipWhitespace()
            if this.Peek() = "]" {
                this.index += 1
                return arr
            }

            loop {
                arr.Push(this.ParseValue())
                this.SkipWhitespace()
                ch := this.Peek()
                if ch = "]" {
                    this.index += 1
                    return arr
                }
                this.ExpectChar(",")
            }
        }

        ParseString() {
            this.ExpectChar('"')
            result := ""

            while !this.AtEnd() {
                ch := SubStr(this.text, this.index, 1)
                this.index += 1
                if ch = '"' {
                    return result
                }
                if ch = "\" {
                    if this.AtEnd() {
                        throw Error("Unexpected end of JSON string.")
                    }
                    escape := SubStr(this.text, this.index, 1)
                    this.index += 1
                    switch escape {
                        case '"', "\", "/":
                            result .= escape
                        case "b":
                            result .= Chr(8)
                        case "f":
                            result .= Chr(12)
                        case "n":
                            result .= "`n"
                        case "r":
                            result .= "`r"
                        case "t":
                            result .= "`t"
                        case "u":
                            hex := SubStr(this.text, this.index, 4)
                            if StrLen(hex) < 4 || !RegExMatch(hex, "^[0-9A-Fa-f]{4}$") {
                                throw Error("Invalid unicode escape in JSON string.")
                            }
                            this.index += 4
                            result .= Chr("0x" hex)
                        default:
                            throw Error("Unsupported escape sequence in JSON string: \" . escape)
                    }
                    continue
                }
                result .= ch
            }

            throw Error("Unterminated JSON string.")
        }

        ParseNumber() {
            start := this.index

            if this.Peek() = "-" {
                this.index += 1
            }
            this.ConsumeDigits()
            if this.Peek() = "." {
                this.index += 1
                this.ConsumeDigits()
            }
            if this.Peek() = "e" || this.Peek() = "E" {
                this.index += 1
                if this.Peek() = "+" || this.Peek() = "-" {
                    this.index += 1
                }
                this.ConsumeDigits()
            }

            literal := SubStr(this.text, start, this.index - start)
            return literal + 0
        }

        ConsumeDigits() {
            if !RegExMatch(this.Peek(), "\d") {
                throw Error("Invalid number in JSON.")
            }
            while RegExMatch(this.Peek(), "\d") {
                this.index += 1
            }
        }

        SkipWhitespace() {
            while !this.AtEnd() {
                ch := SubStr(this.text, this.index, 1)
                if ch != " " && ch != "`t" && ch != "`r" && ch != "`n" {
                    break
                }
                this.index += 1
            }
        }

        ExpectChar(expected) {
            this.SkipWhitespace()
            if this.Peek() != expected {
                throw Error("Expected '" expected "' in JSON.")
            }
            this.index += 1
        }

        ExpectLiteral(literal) {
            if SubStr(this.text, this.index, StrLen(literal)) != literal {
                throw Error("Expected '" literal "' in JSON.")
            }
            this.index += StrLen(literal)
        }

        Peek() {
            return this.AtEnd() ? "" : SubStr(this.text, this.index, 1)
        }
    }
}
