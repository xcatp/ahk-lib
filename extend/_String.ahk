#Requires AutoHotkey v2.0

#Include _Base.ahk

DefProp("".base, "At", { call: _At_String })
DefProp("".base, "CharAt", { call: _CharAt })
DefProp("".base, "CharCodeAt", { call: _CharCodeAt })
DefProp("".base, "ToCharArray", { call: StrSplit })
DefProp("".base, "Concat", { call: _Concat_String })
DefProp("".base, "BeginWith", { call: _BeginWith })
DefProp("".base, "EndWith", { call: _EndWith })
DefProp("".base, "Repeat", { call: _Repeat })
DefProp("".base, "RTrim", { call: RTrim })
DefProp("".base, "Replace", { call: StrReplace })
DefProp("".base, "LTrim", { call: LTrim })
DefProp("".base, "Trim", { call: Trim })
DefProp("".base, "ToLowerCase", { call: StrLower })
DefProp("".base, "ToUpperCase", { call: StrUpper })
DefProp("".base, "ToTitleCase", { call: StrTitle })
DefProp("".base, "Split", { call: StrSplit })
DefProp("".base, "SubString", { call: _SubStr })
DefProp("".base, "Length", { get: StrLen })
DefProp("".base, "__item", { get: __item_String })
DefProp("".base, "__Enum", { call: String_Enum })

String_Enum(this, paramCnt) => this.tocharArray().__Enum()

__item_String(this, index) => this.CharAt(index)

; 返回指定位置的字符，如果是负数从字符串末尾开始。
_At_String(this, index) => this.ToCharArray()[index]

; 返回指定位置的字符，不接受负数。
_CharAt(this, index) {
  if index <= 0 || index > this.Length
    throw Error('Index ' index ' out of range')
  charArr := StrSplit(this)
  return charArr[index]
}
; 返回指定位置的字符码元
_CharCodeAt(this, index) {
  char := this.CharAt(index)
  return Ord(char)
}
; 将字符串参数连接到调用的字符串，并返回一个新的字符串。
_Concat_String(this, str*) {
  r := this
  for v in str {
    r .= v
  }
  return r
}
; 特殊字符需转义
_BeginWith(this, searchString, caseSense := false) {
  flag := caseSense ? '' : 'i)'
  return this ~= flag '^' searchString
}
; 判断一个字符串是否以指定字符串结尾，如果是则返回 true，否则返回 false。
; 第二个参数指定预期结尾位置，如果字符串在该位置结束，返回 true，否则返回 false。
_EndWith(this, searchString, endPostion?) {
  sl := searchString.Length
  if IsSet(endPostion) {
    if sl < endPostion {
      target := SubStr(this, endPostion - sl + 1, sl)
      if target = searchString
        return true
    }
    return false
  } else {
    return searchString = SubStr(this, this.Length - sl + 1)
  }
}

_SubStr(this, startPos, length?) {
  if IsSet(length) && length > startPos
    length := length - startPos
  return SubStr(this, startpos, length?)
}
; 构造并返回一个新字符串，其中包含指定数量的所调用的字符串副本，这些副本连接在一起。
_Repeat(this, count) {
  if count < 0
    throw Error('RangeError')
  else if count = 0
    return ''
  else if count = 1
    return this
  count := Floor(count)
  loop count {
    r .= this
  }
  return r
}