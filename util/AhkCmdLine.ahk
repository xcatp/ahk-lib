#Requires AutoHotkey v2.0

#Include ..\Extend.ahk
; <p>
; Any special flags (e.g. /force and /restart) must appear prior to the script filespec.
; The script filespec (if present) must be the first non-backslash arg.
; All args that appear after the filespec are considered to be parameters for the script
; and will be stored in A_Args.
; </p>
; Some correct command-line :
; - C:\Program\AutoHotkey64.exe /restart /force "C:\scripts\foo .ahk" "foo=bar"
; - C:\Program\AutoHotkey64.exe   /restart         C:\scripts\foo.ahk   foo=bar
;
; InCorrect command-line:
; - C:\Program\AutoHotkey64.exe C:\\.ahk s\foo.ahk "foo=bar"  # path with space should surround with quote
ParseCmdLine(cmdLine) {
  if !cmdLine
    throw Error('invalid command line:blank input')
  switchs := [], args := [], _s := '', _q := false, i := 1
  while i <= cmdLine.length {
    if (_c := cmdLine.charAt(i)) = '\' && i < cmdLine.length && cmdLine.charAt(i + 1) = '"' {
      _s .= '"', i++
    } else if _c = '"' {
      if _q
        _s[1] = '/' ? switchs.push(_s) : args.push(_s), _s := ''
      _q := !_q
    } else if _c = ' ' && !_q {
      if _s.length > 0
        _s[1] = '/' ? switchs.push(_s) : args.push(_s), _s := ''
    } else _s .= _c
    i++
  }
  if _s.length > 0
    args.push(_s)
  if args.Length < 2
    throw Error('invalid command line:bad command line')
  return { ahkExePath: args.shift(), switchs: switchs, filespec: args.shift(), params: args }
}

GetCommandLine() => commandLine := StrGet(DllCall('GetCommandLineW'))