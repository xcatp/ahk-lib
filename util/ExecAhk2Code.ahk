#Requires AutoHotkey v2.0

ExecCode(Script, Wait := true) {
  shell := ComObject("WScript.Shell")
  exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
  exec.StdIn.Write(script)
  exec.StdIn.Close()
  if Wait
    return exec.StdOut.ReadAll()
}
