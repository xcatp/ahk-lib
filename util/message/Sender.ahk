#Requires AutoHotkey v2.0

; Usage:
; ```
;   ; Send string of any length
;   Sender.SendStr('Receiver.ahk', 'hello')
;   ; Send a custom message and up to two numbers
;   Sender.SendParam('Receiver.ahk', 10, 20)
; ```
class Sender {

  static SendStr(target, message, timeOutTime := 4000) {
    CopyDataStruct := Buffer(3 * A_PtrSize)

    SizeInBytes := (StrLen(message) + 1) * 2
    NumPut("Ptr", SizeInBytes
      , "Ptr", StrPtr(message)
      , CopyDataStruct, A_PtrSize)

    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows True
    SetTitleMatchMode 2

    RetValue := SendMessage(0x4a, 0, CopyDataStruct, , target, , , , timeOutTime) ; WM_COPYDATA.

    DetectHiddenWindows Prev_DetectHiddenWindows
    SetTitleMatchMode Prev_TitleMatchMode
    return RetValue
  }

  static SendParam(targetStr, wprama, lparam, msgCode := 0x5555) {
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows True
    if WinExist(targetStr)
      PostMessage 0x5555, wprama, lparam
    DetectHiddenWindows Prev_DetectHiddenWindows
  }
}