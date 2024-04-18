#Requires AutoHotkey v2.0

#Include ..\..\Extend.ahk

; Usage:
; ```
;   list := GenericArray(Integer)
;   list.Add(1)   ; success
;   list.Add({})  ; error!
; ```
class GenericArray extends Array {

  __New(kind) {
    this.kind := kind
    super.__New()
  }

  ToString() => '[GenericArray]' ToString(this)

  Add(e) {
    if not e is this.kind
      throw TypeError('bad type: ' type(e))
    this.Push(e)
  }
}
