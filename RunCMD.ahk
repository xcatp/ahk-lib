#Requires AutoHotkey v2.0

#Include Extend.ahk

RunCMD(CmdLine, WorkingDir := "", Codepage := "CP0", Fn := "RunCMD_Output", Slow := 1) {
  ; RunCMD v0.97 by SKAN on D34E/D67E
  ;            @ autohotkey.com/boards/viewtopic.php?t=74647
  ; Based on StdOutToVar.ahk by Sean
  ;            @ autohotkey.com/board/topic/15455-stdouttovar
  ; Modified by TAC109 to not use A_Args (disrupts Ahk2Exe)

  Slow := !!Slow, Fn := IsFunction(Fn) ? Fn : 0, P8 := (A_PtrSize = 8)
    , DllCall("CreatePipe", "ptr*", &hPipeR := 0, "ptr*", &hPipeW := 0, "Ptr", 0, "Int", 0)
    , DllCall("SetHandleInformation", "Ptr", hPipeW, "Int", 1, "Int", 1)
    , DllCall("SetNamedPipeHandleState", "Ptr", hPipeR, "UIntP", PIPE_NOWAIT := 1, "Ptr", 0, "Ptr", 0)
    , SI := Buffer(P8 ? 104 : 68, 0) ; STARTUPINFO structure
    , NumPut('uint', P8 ? 104 : 68, SI) ; size of STARTUPINFO
    , NumPut('uint', STARTF_USESTDHANDLES := 0x100, SI, P8 ? 60 : 44) ; dwFlags
    , NumPut('uint', hPipeW, SI, P8 ? 88 : 60) ; hStdOutput
    , NumPut('uint', hPipeW, SI, P8 ? 96 : 64) ; hStdError
    , PI := Buffer(P8 ? 24 : 16) ; PROCESS_INFORMATION structure

  If !DllCall("CreateProcess", "Ptr", 0, "Str", CmdLine, "Ptr", 0, "Int", 0, "Int", 1
    , "Int", 0x08000000 | DllCall("GetPriorityClass", "Ptr", -1, "UInt"), "Int", 0
    , "Ptr", WorkingDir ? StrPtr(WorkingDir) : 0, "Ptr", SI.Ptr, "Ptr", PI.Ptr)
    Return Format("{1:}", "", ErrorLevel := -1
      , DllCall("CloseHandle", "Ptr", hPipeW), DllCall("CloseHandle", "Ptr", hPipeR))


  DllCall("CloseHandle", "Ptr", hPipeW)
    , RnCMD := { PID: NumGet(PI, P8 ? 16 : 8, "UInt") }
    , File := FileOpen(hPipeR, "h", Codepage), LineNum := 1, sOutput := ""
  While (RnCMD.PID | DllCall("Sleep", "Int", Slow))
    and DllCall("PeekNamedPipe", "Ptr", hPipeR, "Ptr", 0, "Int", 0, "Ptr", 0
      , "Ptr", 0, "Ptr", 0)
    While RnCMD.PID and StrLen(Line := File.ReadLine())
      sOutput .= Fn ? Fn.Call(Line, LineNum++) : Line

  RnCMD.PID := 0, hProcess := NumGet(PI, 0, 'uint'), hThread := NumGet(PI, A_PtrSize, 'uint')
    , DllCall("GetExitCodeProcess", "Ptr", hProcess, "ptr*", &ExitCode := 0)
    , DllCall("CloseHandle", "Ptr", hProcess), DllCall("CloseHandle", "Ptr", hThread)
    , DllCall("CloseHandle", "Ptr", hPipeR), ErrorLevel := ExitCode
  Return sOutput
}