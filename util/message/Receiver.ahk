#Requires AutoHotkey v2.0

OnMessage 0x004A, (wParam, lParam, *) => Receiver._Receive_WM_COPYDATA(lParam)

; Usage:
; ```
;   ; Receive string
;   Receiver.OnCopyDataCB := (data) => MsgBox('get data: ' data)
; 
;   ; Receive custom message
;   Receiver.ReceiveParam(0x5555, cb)
;   cb(wParam, lParam, msg, *) {
;    MsgBox "Message " msg " arrived:`nWPARAM: " wParam "`nLPARAM: " lParam
;   }
; ```
class Receiver {

  static OnCopyDataCB := (data) => ToolTip(A_ScriptName "`nReceived the following string:`n" data)

  static ReceiveParam(msgCode, cb) => OnMessage(msgCode, cb)

  static _Receive_WM_COPYDATA(lParam) {
    StringAddress := NumGet(lParam, 2 * A_PtrSize, "Ptr")
    CopyOfData := StrGet(StringAddress)
    SetTimer Receiver.OnCopyDataCB.Bind(CopyOfData), -1
    return true
  }
}