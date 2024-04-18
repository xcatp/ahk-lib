#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Receiver.ahk

Persistent

Receiver.OnCopyDataCB := (data) => MsgBox('get data: ' data)

Receiver.ReceiveParam(0x5555, cb)
cb(wParam, lParam, msg, *) {
  MsgBox "Message " msg " arrived:`nWPARAM: " wParam "`nLPARAM: " lParam
}