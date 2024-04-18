#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Sender.ahk

Sender.SendStr('Receiver.ahk', 'hello')
Sender.SendParam('Receiver.ahk', 10, 20)