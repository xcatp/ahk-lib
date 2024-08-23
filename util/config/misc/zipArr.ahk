/* 
  此脚本是压缩数组的实现demo。
  2024/08/08 xcatp
*/

#Include G:\AHK\git-ahk-lib\Extend.ahk

; zipArr : [ a, 'b c', ',', ']' ]

def := "[ a, 'b\' c',, , ']']  # comment"

inQ := false, _i := 1, i := 0
while ++i <= def.length {
  v := def[i]
  if i + 1 <= def.length and v = '\' and def[i + 1] = "'" {
    i++
    continue
  }
  if !inQ and v = ']' {
    _i := i
    break
  } else if v = "'" {
    inQ := !inQ
  }
}

comment := def.substring(_i + 1)
def := def.substring(2, _i).trim()
; MsgBox def ' - ' comment

inQ := false, data := [], _i := 1, i := 0

while ++i <= def.length {
  v := def[i]
  if i + 1 <= def.length and v = '\' and def[i + 1] = "'" {
    i++
    continue
  }
  if !inQ and v = ',' { ; do split
    ; ignore blank value and value of white space only
    if _i != i and s := def.substring(_i, i).trim()
      data.push(s)
    _i := i + 1
  } else if v = "'" {
    inQ := !inQ
  }
}

if _i <= def.length
  data.Push(def.substring(_i).trim())


MToString data