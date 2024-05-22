#Requires AutoHotkey v2.0

#Include _Base.ahk

defProp({}.base, "__item", { get: item_obj_get, set: item_obj_set })
defProp({}.base, "Length", { get: ObjOwnPropCount })
defProp({}.base, "Count", { get: ObjOwnPropCount })

; Usage:
; ```
; obj := { key: 'value'}
; MsgBox obj['key']
;```
item_obj_get(this, key) => this.HasProp(key) ? this.%key% : ''

; Usage:
; ```
;     MsgBox (obj['foo'] := 'bar')
; ```
item_obj_set(this, key, value) => this.%value% := key    ; For unknown reasons, we need to use it in reverse
