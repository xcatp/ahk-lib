#Requires AutoHotkey v2.0

#Include ..\Extend.ahk

ExecScript(scriptFullPath, switchs := [], args := '', exePath := A_AhkPath) {
  if not FileExist(Trim(scriptFullPath, '"'))
    throw Error('script not exist: ' scriptFullPath)
  cmd := exePath A_Space
    . switchs.join(A_Space) A_Space
    . SurroundWith(scriptFullPath, '"') A_Space
    . (args ? SurroundWith(args, '"') : '')
  Run(A_ComSpec ' /c' cmd, , 'hide')
}