#Requires AutoHotkey v2.0

DecodeUniCodeString(Str) {
  spo := 1, out := ""
  while (fpo := RegexMatch(Str, "\\u([0-9a-fA-F]{4})", &m, spo)) {
    out .= SubStr(Str, spo, fpo - spo) chr('0x' m[1])
    spo := fpo + StrLen(m[0])
  }
  return out SubStr(Str, spo)
}