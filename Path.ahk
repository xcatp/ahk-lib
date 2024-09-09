#Requires AutoHotkey v2.0

#Include Extend.ahk

class Path {
  static delimiter := '\' ; windows

  __New(_path) => Path.Parse(_path)

  ; 返回一个对象，其属性表示 path 的重要元素。
  ; 返回的对象将具有以下属性：
  ; ```
  ;   fullPath  全路径
  ;   name      文件名
  ;   dir       目录
  ;   ext       文件后缀
  ;   basename  无后缀文件名
  ;   root      盘符
  ; ```
  static Parse(_path) {
    if !Path or !IsString(_path)
      throw TypeError('Path must be a string.')
    _path := Path.Normalize(_path)
    SplitPath(_path, &name, &dir, &ext, &nameNoExt, &root)
    return { fullPath: _path, name: name, dir: dir, ext: ext, nameNoExt: nameNoExt, root: root }
  }

  ; 获取文件名，并删除可选后缀
  static Basename(_path, ext := unset) {
    ext := ext ?? '', bn := Path.Parse(_path).name
    if (el := ext.Length) > (bl := bn.Length)
      throw Error('extension error')
    return ext ? bn.substring(bl - el + 1) == ext ? bn.substring(1, bl - el + 1) : bn : bn
  }

  static Dir(_path) => Path.Parse(_path).dir

  ; 规范化给定的 path，解析 '..' 和 '.' 片段，并转换分隔符，返回规范化后的路径。
  static Normalize(_path) {
    if !_path or !IsString(_path)
      throw TypeError('Path must be a string.')
    _path := StrReplace(_path, Path.delimiter = '\' ? '/' : '\', Path.delimiter)
    stack := [], segs := _path.Split(Path.delimiter)
    for v in segs {
      if stack.Length && stack.peek() != '..' && '..' == v
        stack.Pop()
      else if '.' != v && '' != v
        stack.Push(v)
    }
    return _path ~= '^[\\/]' ? Path.delimiter stack.Join(Path.delimiter) : stack.Join(Path.delimiter)
  }

  ; 判断路径字符串中是否含有 .. 或 . 片段
  static IsStandard(_path) {
    if !_path or !IsString(_path)
      return false
    return InStr(_path, Path.delimiter '.') or InStr(_path, Path.delimiter '..')
  }

  ; 判断路径字符串是否为绝对路径：以盘符或斜杠开头
  static IsAbsolute(_path) {
    if !_path or !IsString(_path)
      return false
    return _path ~= '^(?:\w:)?[\\/]' || _path ~= '^\w:'
  }

  ; 将所有给定的 path 片段连接在一起，然后规范化生成的路径。
  static Join(params*) {
    if !params.Length
      return
    for s in params {
      if IsString(s)
        _path .= Path.delimiter s
      else throw TypeError('Path must be a string. Received ' s)
    }
    stack := [], segs := Path.Normalize(_path).Split(Path.delimiter)
    for v in segs {
      if stack.Length && '..' == v
        stack.Pop()
      else if '.' != v && '' != v
        stack.Push(v)
    }
    return stack.Join(Path.delimiter)
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
    if pathObj.HasProp('dir')
      _path .= pathObj.dir
    else if pathObj.HasProp('root')
      _path .= pathObj.root
    if pathObj.HasProp('basename')
      _path .= Path.delimiter pathObj.basename
    else if pathObj.HasProp('name') {
      _path .= Path.delimiter pathObj.name
      if pathObj.HasProp('ext') && pathObj.ext != 'ignore'
        _path .= pathObj.ext
    }
    return Path.Normalize(_path)
  }

  ; 返回从 from 到 to 的相对路径。
  ; 如果 to 是绝对路径，而 from 不是，返回 to
  static Relative(from, to) {
    if !IsString(from) or !IsString(to)
      throw TypeError('Path must be a string.')
    from := from || A_ScriptFullPath, to := to || A_ScriptFullPath
    from := Path.Normalize(from), to := Path.Normalize(to)
    if from = to
      return ''
    if Path.IsAbsolute(to) and !Path.IsAbsolute(from)
      return to
    res := [], froms := from.Split(Path.delimiter), tos := to.Split(Path.delimiter)
    i := j := 1
    while i != froms.Length && j != tos.Length {
      if froms[i] != tos[j]
        break
      i++, j++
    }
    loop froms.Length - i + 1
      res.Push('..')
    loop tos.Length - j + 1
      res.Push(tos[j + A_Index - 1])
    return res.Join(Path.delimiter)
  }

  ; 将路径或路径片段的序列解析为绝对路径。
  ; 如果最后还没有得到绝对路径，则与脚本目录连接
  static Resolve(params*) {
    for param in params {
      if !param or !IsString(param)
        continue
      if Path.IsAbsolute(param)
        _ := ''
      _ .= param Path.delimiter
    }
    return Path.IsAbsolute(_ := Path.Normalize(_)) ? _ : Path.Join(A_ScriptDir, _)
  }
}