#Requires AutoHotkey v2.0

#Include ../Extend.ahk

class JSON {

  static Stringify(object, expandLevel := unset, space := '  ') => ToString(object, true, true, expandLevel?, space)

  static Format(jsonData, indent := 4) {
    s := '', l := 0, inQ := false
    for i, ch in jsonData {
      IfThen(ch == '"' and jsonData[i - 1] != '\', (*) => inQ := !inQ)
      if !inQ {
        if ch == '{' or ch == '[' {
          s .= ch '`n' A_Space.repeat(l * indent + indent)
          l++
        } else if ch == '}' or ch == ']' {
          l--
          s .= '`n' A_Space.repeat(l * indent) . ch
        } else if ch == ',' {
          s .= ch '`n' A_Space.repeat(l * indent)
        } else s .= ch
      } else s .= ch
    }

    return Trim(s)
  }

  static Parse(text, asMap := false) {
    ; [HotKeyIt/Yaml](https://github.com/HotKeyIt/Yaml)
    asMap ? (_set := (maptype := Map).Prototype.Set) : (_set := (o, k, v) => o[k] := v, maptype := Object)
    NQ := '', LF := '', LP := 0, P := '', R := '', _true := true, _false := false, _null := ''
    D := [C := (A := InStr(text := LTrim(text, " `t`r`n"), "[") = 1) ? [] : maptype()], text := LTrim(SubStr(text, 2), " `t`r`n")
      , L := 1, N := 0, V := K := "", J := C, !(Q := InStr(text, '"') != 1) ? text := LTrim(text, '"') : ""
    Loop Parse text, '"' {
      Q := NQ ? 1 : !Q
      NQ := Q && (SubStr(A_LoopField, -3) = "\\\" || (SubStr(A_LoopField, -1) = "\" && SubStr(A_LoopField, -2) != "\\"))
      if !Q {
        if (t := Trim(A_LoopField, " `t`r`n")) = "," || (t = ":" && V := 1)
          continue
        else if t && (InStr("{[]},:", SubStr(t, 1, 1)) || A && RegExMatch(t, "m)^(null|false|true|-?\d+(\.\d*(e[-+]\d+)?)?)\s*[,}\]\r\n]")) {
          Loop Parse t {
            if N && N--
              continue
            if InStr("`n`r `t", A_LoopField)
              continue
            else if InStr("{[", A_LoopField) {
              if !A && !V
                throw Error("Malformed JSON - missing key.", 0, t)
              C := A_LoopField = "[" ? [] : maptype(), A ? D[L].Push(C) : _set(D[L], K, C)
                , D.Has(++L) ? D[L] := C : D.Push(C), V := "", A := IsArray(C)
              continue
            } else if InStr("]}", A_LoopField) {
              if !A && V
                throw Error("Malformed JSON - missing value.", 0, t)
              else if L = 0
                throw Error("Malformed JSON - to many closing brackets.", 0, t)
              else C := --L = 0 ? "" : D[L], A := IsArray(C)
            } else if !(InStr(" `t`r,", A_LoopField) || (A_LoopField = ":" && V := 1)) {
              if RegExMatch(SubStr(t, A_Index), "m)^(null|false|true|-?\d+(\.\d*(e[-+]\d+)?)?)\s*[,}\]\r\n]", &R) && (N := R.Len(0) - 2, R := R.1, 1) {
                if A
                  C.Push(R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R)
                else if V
                  _set(C, K, R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R), K := V := ""
                else throw Error("Malformed JSON - missing key.", 0, t)
              } else {
                ; Added support for comments without '"'
                if A_LoopField == '/' {
                  nt := SubStr(t, A_Index + 1, 1), N := 0
                  if nt == '/' {
                    if nt := InStr(t, '`n', , A_Index + 2)
                      N := nt - A_Index - 1
                  } else if nt == '*' {
                    if nt := InStr(t, '*/', , A_Index + 2)
                      N := nt + 1 - A_Index
                  } else nt := 0
                  if N
                    continue
                }
                throw Error("Malformed JSON - unrecognized character.", 0, A_LoopField " in " t)
              }
            }
          }
        } else if A || InStr(t, ':') > 1
          throw Error("Malformed JSON - unrecognized character.", 0, SubStr(t, 1, 1) " in " t)
      } else if NQ && (P .= A_LoopField '"', 1)
        continue
      else if A
        LF := P A_LoopField, C.Push(InStr(LF, "\") ? UC(LF) : LF), P := ""
      else if V
        LF := P A_LoopField, _set(C, K, InStr(LF, "\") ? UC(LF) : LF), K := V := P := ""
      else
        LF := P A_LoopField, K := InStr(LF, "\") ? UC(LF) : LF, P := ""
    }
    return J
    UC(S, e := 1) {
      static m := Map(Ord('"'), '"', Ord("a"), "`a", Ord("b"), "`b", Ord("t"), "`t",
        Ord("n"), "`n", Ord("v"), "`v", Ord("f"), "`f", Ord("r"), "`r")
      local v := ""
      Loop Parse S, "\"
        if !((e := !e) && A_LoopField = "" ? v .= "\" : !e ? (v .= A_LoopField, 1) : 0)
          v .= (t := InStr("ux", SubStr(A_LoopField, 1, 1))
            ? SubStr(A_LoopField, 1, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K") - 1)
            : "") && RegexMatch(t, "i)^[ux][\da-f]+$")
            ? Chr(Abs("0x" SubStr(t, 2))) SubStr(A_LoopField, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K"))
            : m.has(Ord(A_LoopField)) ? m[Ord(A_LoopField)] SubStr(A_LoopField, 2) : "\" A_LoopField, e := A_LoopField = "" ? e : !e
      return v
    }
  }
}