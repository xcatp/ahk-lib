#Requires AutoHotkey v2.0

#Include Extend.ahk

class Path {

  static sep := '\', delimiter := ';', workDir := A_WorkingDir

  ; 返回路径解析对象
  __New(_path) {
    pathObj := Path.Parse(_path)
    return pathObj
  }

  ; 返回一个对象，其属性表示 path 的重要元素。
  ; 返回的对象将具有以下属性：
  ; ```
  ;   fullPath  全路径
  ;   dir       目录
  ;   root      盘符
  ;   basename  文件名
  ;   name      无后缀文件名
  ;   ext       文件后缀
  ; ```
  static Parse(_path) {
    if not IsString(_path)
      throw TypeError('Path must be a string.')
    if !_path
      return {
        fullPath: '',
        dir: '',
        root: '',
        basename: '',
        name: '',
        ext: ''
      }

    _path := Path.Normalize(_path)

    lastSepPos := InStr(_path, Path.sep, , -1)
    dir := SubStr(_path, 1, lastSepPos - 1)
    if dir ~= 'i)^\w:[\\/]' {
      root := SubStr(dir, 1, 3)
    } else root := ''
    basename := SubStr(_path, lastSepPos + 1)
    dotPos := InStr(basename, '.')
    if dotPos {
      name := SubStr(basename, 1, dotPos - 1)
      ext := SubStr(basename, dotPos + 1)
    } else {
      name := ''
      ext := ''
    }

    return {
      fullPath: _path,
      dir: dir,
      root: root,
      basename: basename,
      name: name,
      ext: ext
    }
  }

  ; ON TEST
  static Basename(_path, ext := unset) {
    if not IsString(_path)
      throw TypeError('Path must be a string.')
    _path := Path.Normalize(_path)
    lastSepPos := InStr(_path, Path.sep, , -1)
    basename := SubStr(_path, lastSepPos + 1)
    IsSet(ext) && basename := StrReplace(basename, ext)
    return basename
  }

  static Dir(_path) {
    _path := Path.Normalize(_path), sepPos := InStr(_path, Path.sep, , -1)
    return _path.subString(1, sepPos)
  }

  ; 规范化给定的 path，解析 '..' 和 '.' 片段，并将分隔符转换为 Path.Sep，返回规范化后的路径。
  static Normalize(_path) {
    if not IsString(_path)
      throw TypeError('Path must be a string.')
    if !_path
      return ''
    target := Path.sep = '\' ? '/' : '\'
    _path := StrReplace(_path, target, Path.sep)

    stack := []

    segs := _path.Split(Path.sep)
    for v in segs {
      if stack.Length && stack.peek() != '..' && '..' == v {  ; 允许 ../../e
        stack.Pop()
      } else if '.' != v && '' != v {
        stack.Push(v)
      }
    }

    return _path ~= '^[\\/]'
      ? Path.sep stack.Join(Path.sep)
      : stack.Join(Path.sep)
  }

  ; 判断路径字符串中是否含有 .. 或 . 片段
  static IsStandard(_path) {
    if _path = '' || not IsString(_path)
      return false
    if InStr(_path, Path.sep '.')
      return false
    else if InStr(_path, Path.sep '..')
      return false
    return true
  }

  ; 判断路径字符串是否为绝对路径：以盘符或斜杠开头
  static IsAbsolute(_path) {
    if _path = '' || not IsString(_path)
      return false
    return _path ~= '^(?:\w:)?[\\/]'
  }

  ; 将所有给定的 path 片段连接在一起，然后规范化生成的路径。
  static Join(params*) {
    if !params.Length
      return
    for param in params {
      if param is String
        _path .= Path.sep param
      else
        throw TypeError('Path must be a string. Received ' param)
    }
    stack := []
    _path := Path.Normalize(_path)
    segs := _path.Split(Path.sep)
    for v in segs {
      if stack.Length && '..' == v {
        stack.Pop()
      } else if '.' != v && '' != v {
        stack.Push(v)
      }
    }
    return stack.Join(Path.sep)
  }

  ; 从对象返回路径字符串。 这与 path.parse() 相反。
  ; 该对象应包含:
  ; ```
  ;   dir       目录
  ;   root      盘符
  ;   basename  文件名
  ;   name      无后缀文件名
  ;   ext       文件后缀，ignore为忽略
  ; ```
  ; 中的任意组合。
  static Format(pathObj) {
    if pathObj.HasProp('dir') {
      _path .= pathObj.dir
    } else if pathObj.HasProp('root') {
      _path .= pathObj.root
    }
    if pathObj.HasProp('basename') {
      _path .= Path.sep pathObj.basename
    } else if pathObj.HasProp('name') {
      _path .= Path.sep pathObj.name
      if pathObj.HasProp('ext') && pathObj.ext != 'ignore'
        _path .= pathObj.ext
    }
    return Path.Normalize(_path)
  }

  ; 返回从 from 到 to 的相对路径。
  static Relative(from, to) {
    if !IsString(from) || !IsString(to)
      throw TypeError('Path must be a string.')
    if !from
      from := A_ScriptFullPath
    if !to
      to := A_ScriptFullPath

    from := Path.Resolve(from)
    to := Path.Resolve(to)

    if from = to
      return ''
    else {
      froms := from.Split(Path.sep)
      tos := to.Split(Path.sep)
      res := []
      i := j := 1
      while i != froms.Length && j != tos.Length {
        if froms[i] != tos[j]
          break
        i++, j++
      }
      loop froms.Length - i + 1 {
        res.Push('..')
      }
      loop tos.Length - j + 1 {
        res.Push(tos[j + A_Index - 1])
      }
      return res.Join(Path.sep)
    }
  }

  ; 将路径或路径片段的序列解析为绝对路径。
  static Resolve(params*) {
    for param in params {
      if !param || !IsString(param)
        continue
      if Path.IsAbsolute(param) {
        _path := ''
      }
      _path .= param Path.sep
    }
    _path := Path.Normalize(_path)
    return Path.IsAbsolute(_path)
      ? _path
      : A_ScriptFullPath
  }

  class PathObj {
    __New(fullPath) {

    }

    parse() {
      if !this.fullPath
        return this
    }
  }
}