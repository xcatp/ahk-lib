/*
  此脚本是实现函数语法的 demo
  2024/08/05 xcatp
*/

#Include G:\AHK\git-ahk-lib\Extend.ahk
; &func(a, b) : 'http://{a}:{b}'

def := '(a, b)'
def := StrReplace(def, A_Space)
if def[1] != '(' or def[-1] != ')'
  MsgBox 'err'
def := def.substring(2, def.Length)
params := {}
StrSplit(def, ',').filter(v => v).foreach((v, i) => params[v] := i)

; MToString params

body := 'http://{b}:{a}'

_pos := 1, idx := {}, post := ''
for i, v in body {
  if v = '{' {
    _pos := i
  } else if v = '}' {
    idx[idx.Length + 1] := body.substring(_pos + 1, i)
    post := SubStr(post, 1, post.Length - i + _pos + 1)
  }
  post .= v
}

; MsgBox post

; MToString idx

for k, v in idx.OwnProps() {
  idx[k] := params[v]
}

; MToString idx

__f__ := (_p*) => __f.Bind(post, idx, _p*)


__f(str, mapping, p*) {
  i := 1, _chs := str.toChararray(), _r := '', _c := 1
  while i + 1 <= _chs.Length {
    if _chs[i] = '{' and _chs[i + 1] = '}' {
      _r .= p[mapping[_c]], _c++, i++
    } else _r .= _chs[i]
    i++
  }
  return _r
}

; vm : $fn(2, 1)$
a := 2, b := 1
MsgBox __f__(a, b)()