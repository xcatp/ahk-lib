#Requires AutoHotkey v2.0

#Include extend\_Array.ahk
#Include extend\_String.ahk
#Include extend\_Object.ahk
#Include extend\_Integer.ahk
#Include extend\_Map.ahk
#Include extend\_UI.ahk
#Include extend\_Hotkey.ahk
#Include extend\_Deprecate.ahk

; remove space and `n
TrimAll(&str) => str := str.toCharArray().filter(v => v != ' ' && v != '`n').join('')

; Usage:
; ```
; ; we can do this :
; MsgBox IfThen(1, MsgBox, 'ok')
; ; instead of :
; if 1
;   MsgBox('ok')
; ```
IfThen(condition, action, params*) {
  if condition {
    try execRes := action(params*)
    catch 
      MsgBox 'error occu when exec func:' action.Name
    return true & IsTrue(execRes)
  } else return false
}

; Usage:
; ```
; ; we can do this:
; MsgBox JoinStr('|', 'str1', 'str2') ; don`t forget the ','
; ; instead of:
; MsgBox 'str1' '|' 'str2'
; ```
JoinStr(splitor := '', strs*) => strs.Join(splitor)

; Usage:
; ```
; ; NOTE_ it can not be used to [this], like [DCon({a : 1, b : 2}, &this.a, &this.b)]
; o := { x: 1, y: 2}
; arr := [1, 2, 3]
; prim := 1
;
; Deconstruction(o, &a := 'x', &b := 'y') ; object
; MsgBox JoinStr(, a, b)
; Deconstruction(arr, &a, &b, &c)       ; array
; MsgBox JoinStr(, a, b, c)
; Deconstruction(prim, &v)              ; primitive
; MsgBox v
; ```
Deconstruction(target, vars*) {
  if IsArray(target) {
    for i, v in target {
      if not IsVarRef(vars[i]) {
        throw TypeError('array deconstructing need varRef')
      }
      %vars[i]% := v
    }
  } else if IsObject(target) {
    for i, v in vars {
      if not IsVarRef(vars[i]) {
        throw TypeError('object deconstructing need varRef')
      }
      key := %vars[i]%
      %vars[i]% := target.%key% ; no syntax like %%key%%
    }
  } else if IsPrimitive(target) {
    if not IsVarRef(vars[1]) {
      throw TypeError('primitive deconstructing need varRef')
    }
    %vars[1]% := target
  } else throw TypeError('target error')
}
; short for Decontruction
DCon(params*) => Deconstruction(params*)

; ; we can do this :
; ```
; IfOrElse(1
;   , (*) => MsgBox('true')
;   , (*) => MsgBox('false'))
; ; instead of :
; if 1 {
;   MsgBox('true')
; } else MsgBox('flase')
; ```
IfOrElse(condition, trueAction, falsyAction) => condition ? trueAction() : falsyAction()

; create a lambda
; ```
; Lambda(MsgBox, "Hello")()
; ```
Lambda(name, params*) => (*) => name(params*)

; for simplify : str := '"' str '"'
SurroundWith(str, chars) => chars str chars
IsSurroundWith(str, chars) => !chars || str.substring(1, chars.Length + 1) = chars && str.substring(str.Length - chars.Length + 1) = chars

; ```
; Msgbox ToString({ foo: 'bar' })
; ```
ToString(o, q := false, esc := false, expandLevel := unset, space := '  ') {
  ;改自[HotKeyIt/Yaml](https://github.com/HotKeyIt/Yaml)
  expandLevel := IsSet(expandLevel) ? Abs(expandlevel) : 10000000
  if IsPrimitive(o)
    return o
  return Trim(_convert(o, expandLevel))

  _convert(o, el := 0, l := 0, _ := '') {
    static cb := '{}', sb := '[]', nc := '`n', cc := ',', sc := ':'
    if IsArray(o) {
      s := !l ? '[' : ''
      for k, v in o {
        b := IsArray(v) ? sb : (IsMap(v) or IsObject(v)) ? cb : '', r := !IsPrimitive(v) && !IsEmpty(v)
        s .= (el > l ? nc _getIndent(l + 2) : '') (b ? (b[1] (r ? _convert(v, el, l + 1, b) : '') b[2]) : _escape(v))
          . (IsArray(o) && o.Length = A_Index ? '' : cc)
      }
    } else {
      s := !l ? '{' : ''
      for k, v in o.OwnProps() {
        b := IsArray(v) ? sb : (IsMap(v) or IsObject(v)) ? cb : '', r := !IsPrimitive(v) && !IsEmpty(v)
        s .= (el > l ? nc _getIndent(l + 2) : '') (_ = sb && A_Index = 1 ? cb : '') _escape(k) sc
          . (b ? (b[1] (r ? _convert(v, el, l + 1, b) : '') b[2]) : _escape(v)) (_ = sb && A_Index = o.Count ? '}' : '')
          . (el != 0 || l ? (A_Index = O.count ? '' : cc) : '')
        if el = 0 and !l
          s .= (A_Index < o.Count ? cc : '')
      }
    }
    if el > l
      s .= nc _getIndent(l + 1)
    return !l ? RegExReplace(s, '^\R+') (IsArray(o) ? ']' : '}') : s
  }

  _escape(_s) {
    if !esc
      return q ? IsString(_s) ? ('"' _s '"') : _s : _s
    switch {
      case IsFloat(_s):
        if (_v := '', _d := InStr(_s, 'e'))
          _v := SubStr(_s, _d), _s := SubStr(_s, 1, _d - 1)
        if ((StrLen(_s) > 17) && (_d := RegExMatch(_s, "(99999+|00000+)\d{0,3}$")))
          _s := Round(_s, Max(1, _d - InStr(_s, ".") - 1))
        return _s _v
      case IsInteger(_s): return _s
      case IsString(_s):
        _s := StrReplace(_s, "\", "\\")
        _s := StrReplace(_s, "`t", "\t")
        _s := StrReplace(_s, "`r", "\r")
        _s := StrReplace(_s, "`n", "\n")
        _s := StrReplace(_s, "`b", "\b")
        _s := StrReplace(_s, "`f", "\f")
        _s := StrReplace(_s, "`v", "\v")
        _s := StrReplace(_s, '"', '\"')
        return q ? '"' _s '"' : _s
      default: return _s
    }
  }

  _getIndent(_l) => space.repeat(_l - 1)
}