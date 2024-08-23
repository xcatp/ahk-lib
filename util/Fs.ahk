#Requires AutoHotkey v2.0

#Include g:\AHK\git-ahk-lib\Extend.ahk

class FS {

  static IsDir(_p) => InStr(FileGetAttrib(_p), 'D') != 0
  static IsHidden(_p) => InStr(FileGetAttrib(_p), 'H') != 0

  static ReadDir(_dir, _filter, _cb, _match := '*.*', _mode := 'F', recursive := false, withHiddenFile := false) {
    if recursive
      _mode .= 'R'
    switch _cb.MaxParams {
      case 0: _fn := Noop
      case 1: _fn := (v, *) => _cb(v)
      case 2: _fn := (v1, v2, *) => _cb(v1, v2)
      case 3: _fn := (v1, v2, v3) => _cb(v1, v2, v3)
      default: throw Error('invalid callback function')
    }
    r := []
    loop files _dir '/' _match, _mode {
      if withHiddenFile && FS.IsHidden(A_LoopFileFullPath)
        continue
      _fn(A_LoopFileFullPath, A_LoopFileName, A_LoopFileDir)
      if _filter(A_LoopFileName)
        r.Push(A_LoopFileName)
    }
    return r
  }
}