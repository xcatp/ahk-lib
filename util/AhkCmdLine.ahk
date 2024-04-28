#Requires AutoHotkey v2.0

#Include ..\Extend.ahk
; <p>
; Any special flags (e.g. /force and /restart) must appear prior to the script filespec.
; The script filespec (if present) must be the first non-backslash arg.
; All args that appear after the filespec are considered to be parameters for the script
; and will be stored in A_Args.
; </p>
; Some correct command-line :
; - "C:\Program\AutoHotkey64.exe" /restart /force "C:\scripts\foo.ahk" "foo=bar"
; - C:\Program\AutoHotkey64.exe   /restart         C:\scripts\foo.ahk   foo=bar
;
; InCorrect command-line:
; - "C:\Program\AutoHotkey64.exe" C:\\.ahk s\foo.ahk "foo=bar"  # path with space should surround with quote
ParseCmdLine(cmdLine) {
  parts := cmdLine.Split(A_Space).filter(v => v)        ; convert to array and skip blank values
  ahkExePath := parts.Shift(), switchs := []
  if !parts.Length
    throw Error('invalid command-line')
  while parts.Length and parts[1][1] = '/'
    switchs.Push(parts.Shift())
  if !parts.Length
    throw Error('invalid command-line')
  filespec := parts.Shift(), args := parts
  return { ahkExePath: ahkExePath, switchs: switchs, filespec: filespec, params: args }
}

GetCommandLine() => commandLine := StrGet(DllCall('GetCommandLineW'))