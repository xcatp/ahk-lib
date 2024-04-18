#Requires AutoHotkey v2.0

#Include ..\Extend.ahk
; <p>
; Examine command line args.  Rules:
;
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
  idx := 1

  return {
    exePath: _getExePath(),
    switchs: _getSwitchs(),
    scriptPath: _getScriptPath(),
    args: _getArgs()
  }

  _getExePath() {
    _i := idx
    while cmdLine[idx] != A_Space
      idx++
    return cmdLine.substring(_i, idx)
  }

  _getSwitchs() {
    _i := idx, switchs := []

    while true {
      if cmdLine[idx] = A_Space
        _skipChar()
      if cmdLine[idx] = '/'
        _i := idx, _jumpToChar()
      else break
      switchs.Push(cmdLine.substring(_i, idx))
    }

    return switchs
  }

  _skipChar(char := A_Space) {
    while idx <= cmdLine.Length && cmdLine[idx] = char
      idx++
  }

  _jumpToChar(char := A_Space) {
    while idx <= cmdLine.Length && cmdLine[idx] != char
      idx++
  }
  _getScriptPath() {
    _i := idx, _skipChar()
    if cmdLine[idx] = '"' {  ; surround with quote
      while cmdLine[++idx] != '"'
      { }
      return cmdLine.substring(_i, ++idx)
    } else { ; In this case [c:\.ahk s\foo.ahk], [s\foo.ahk] is mistakenly considered a arg and [c:\.ahk] is considered script path
      _jumpToChar()
      return '"' cmdLine.substring(_i, idx) '"'
    }
  }

  _getArgs() {
    if idx >= cmdLine.Length
      return ''
    else {
      _skipChar()
      return cmdLine.substring(idx)
    }
  }
}

GetCommandLine() => commandLine := StrGet(DllCall('GetCommandLineW'))