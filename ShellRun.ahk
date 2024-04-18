#Requires AutoHotkey v2.0

class ShellRun {

    static RunWaitOne_PS(command) {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec("powershell.exe -WindowStyle Minimized -Command " command)
        return exec.StdOut.ReadAll()
    }

    static RunWaitOne(command) {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(A_ComSpec " /C " command)
        return exec.StdOut.ReadAll()
    }

    static RunWaitMany(commands) {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(A_ComSpec " /Q /K echo off")
        exec.StdIn.WriteLine(commands "`nexit") 
        return exec.StdOut.ReadAll()
    }
}