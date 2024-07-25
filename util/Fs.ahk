#Requires AutoHotkey v2.0

#Include g:\AHK\git-ahk-lib\Extend.ahk

class FS {

  static IsDir(_p) => InStr(FileGetAttrib(_p), 'D') != 0
  static IsHidden(_p) => InStr(FileGetAttrib(_p), 'H') != 0

  static ReadDir(_dir, _filter, _mode := 'F', recursive := false, withHiddenFile := false) {
    if recursive
      _mode .= 'R'
    switch _filter.MaxParams {
      case 0: _fn := _filter
      case 1: _fn := (v, *) => _filter(v)
      case 2: _fn := (v1, v2, *) => _filter(v1, v2)
      default: throw Error('invalid callback function')
    }
    r := []
    loop files _dir '/*.*', _mode {
      if withHiddenFile && FS.IsHidden(A_LoopFileFullPath)
        continue
      if _fn(A_LoopFileName, A_LoopFileDir)
        r.Push(A_LoopFileName)
    }
    return r
  }
}