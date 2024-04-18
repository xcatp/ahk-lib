#Requires AutoHotkey v2.0

#Include ../../Extend.ahk

class Log {

  __New(logFile, r := true) {
    this.logFile := logFile, this.slient := false, this.level := Log.LogLevel.Debug
    if r and !FileExist(logFile) {
      FileOpen(logFile, 'w').Close()
    }
  }

  class LogLevel {
    static Debug := 2, Info := 3, Warn := 4, Error := 5

    static GetLevel(level) {
      switch level {
        case 'DEBUG': return Log.LogLevel.Debug
        case 'INFO': return Log.LogLevel.Info
        case 'WARN': return Log.LogLevel.Warn
        case 'ERROR': return Log.LogLevel.Error
      }
    }
  }

  Debug(msg) => this._Log(msg, 'DEBUG')
  Info(msg) => this._Log(msg, 'INFO')
  Warn(msg) => this._Log(msg, 'WARN')
  Err(msg) => this._Log(msg, 'ERROR')

  _Log(msg, level) {
    if this.slient or Log.LogLevel.GetLevel(level) < this.level
      return
    timeString := FormatTime(, 'yyyy/MM/dd_HH:mm:ss')
    FileAppend('[ ' timeString ' ][ ' level ' ] ' msg '`r`n', this.logFile, 'utf-8')
  }
}