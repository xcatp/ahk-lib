#Requires AutoHotkey v2.0

; Usage:
; ```
; g:: {
;   action() => MsgBox('double clk me')
;   DobuleClick(A_ThisHotkey, action)
;   ; DobuleClick('f', action)
; }
; ```
DobuleClick(key, action) {
  KeyWait(key)
  if KeyWait(key, "D T0.3") {
    action()
  }
}

; ; **Note that error(nonexistent hotkey) will not throw**
; ```
; HotKeysOff('LButton', 'Esc')
; ```
HotKeysOff(hks*) {
  loop hks.Length {
    try Hotkey hks[A_Index], 'Off'
  }
}