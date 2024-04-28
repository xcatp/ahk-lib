#Requires AutoHotkey v2.0

; # Iterator
; Wrap native Enumrator objects.
; Usage:
; ```
;   iter := GetIterator([1, 2, 3])
;   MsgBox iter.key '\' iter.value '\' iter.done
;   iter.Next()
;   MsgBox iter.key '\' iter.value '\' iter.done
;   iter.Next()
;   MsgBox iter.key '\' iter.value '\' iter.done
; ```
GetIterator(source) {
  if source is Primitive
    throw TypeError('Expect an object but get the primitive type')
  if source is Array or source is Map
    enum := source.__Enum()
  else enum := source.OwnProps()
  iter := { next: Next, enum: enum }
  iter.next()

  Next(this) {
    this.enum.call(&index, &value)
    done := false
    if not (IsSet(index) and IsSet(value))
      index := '', value := '', done := true
    this.key := index, this.value := value, this.done := done
  }

  return iter
}