#Requires AutoHotkey v2.0

#Include ..\..\Extend.ahk
#Include ..\..\Path.ahk

class CustomFS {

  data := Map(), cfgs := Map(), vital := Map()
    , escChar := '``', refChar := '$', commentChar := '#', importChar := '@', vitalChar := '*', literalChar := '~', q := "'"

  static preset := Map(
    'a_mydocuments', A_MyDocuments,
    'a_username', A_UserName,
    'a_startup', A_Startup,
    'a_now', A_Now,
    'a_desktop', A_Desktop,
    'a_scriptdir', A_ScriptDir,
    'a_scriptfullpath', A_ScriptFullPath,
    'a_ahkpath', A_AhkPath,
    'a_tab', A_Tab,
    'a_newline', '`n',
  )

  __New(_path, _warn) {
    if !FileExist(_path)
      throw Error('读取的文件不存在:' _path)
    this.path := !Path.IsAbsolute(_path) ? Path.Resolve(A_ScriptDir, _path) : _path, this.doWarn := _warn, this.Init(this.path)
  }

  static Of(_path, _warn := false) => CustomFS(_path, _warn)

  Init(_path) {
    f := FileOpen(_path, 'r', 'utf-8'), r := 0, ec := this.escChar, rc := this.refChar, cc := this.commentChar, lc := this.literalChar
      , ic := this.importChar, vc := this.vitalChar, import := false, cp := _path, this.cfgs.Set(cp.toLowerCase(), this.cfgs.Count + 1)
    while !f.AtEOF {
      r++, l := f.ReadLine()
      if !import and l and l[1] = ic
        l := _processImport(l, _path)
      if !l or l[1] = cc or l ~= '^---'
        continue
      if l[1] = A_Space {
        Warn('忽略了一行以空格开头的内容(' l ')', 0, l, cp)
        continue
      }
      if l[1] = '-'
        ThrowErr('错误的语法: 以-开头而不在数组定义范围内', 0, l, cp)
      else if l[1] = '+'
        ThrowErr('错误的语法: 以+开头而不在对象定义范围内', 0, l, cp)

      import := true, _processLine(l)
    }
    return f.Close()

    _processImport(_l, _cp) {
      while true {
        if this.cfgs.Has((_cp := _getNextPath()).toLowerCase())
          ThrowErr('导入重复文件:' _cp, 1, _l, cp)
        if !FileExist(_cp)
          ThrowErr('导入不存在的文件:' _cp, 1, _l, cp)
        this.Init(_cp), _l := f.ReadLine(), r++
        if !_l or _l[1] != ic or f.AtEOF
          break
      }
      return _l
      _getNextPath() => Path.Join(Path.Dir(_cp), _processValue(_l, 2))
    }

    _processLine(_line) {
      if _line[1] = ic
        Warn('以导入符开头的键，考虑是否为导入语句', 1, _line, cp)
      else if _line[1] = lc {
        _line := _line.subString(2), ori := true
      } else if _line[1] = vc
        _line := _line.subString(2), impt := true
      i := 1, cs := _line.toCharArray(), _jumpToChar(cs, ':', &i, '无效的键，键须以:结尾'), k := _processValue(_line.substring(1, i++), 1, true)
      if k[1] = ':'
        Warn('以键值分隔符开头的键会造成混淆', 1, _line, cp)
      if IsSet(ori) and ori
        return _set(k, _line.substring(i), i, l, cp)
      if i <= cs.Length and cs[i] = A_Space
        _skipChar(cs, A_Space, &i)
      if i > cs.Length or cs[i] = cc {
        if f.AtEOF
          ThrowErr('不允许空的复杂类型', i, _line, cp)
        l := f.ReadLine(), r++, isArr := l[1] = '-'
        if l[1] != '-' and l[1] != '+'
          ThrowErr('第一个子项必须与键连续', i, l, cp)
        vs := isArr ? [] : {}, pc := isArr ? '-' : '+', _set(k, vs, 1, l, cp)
        while true {
          if !l or l[1] != pc
            break
          if isArr
            _l := LTrim(l.substring(2), A_Space), vs.Push(_processValue(_l, 1))
          else {
            cs := (_l := LTrim(l.substring(2), A_Space)).toCharArray(), _jumpToChar(cs, ':', &_i := 1, '无效的键')
            _k := RTrim(_l.substring(1, _i)), vs.%_k% := _processValue(LTrim(_l.substring(_i + 1)), 1)
          }
          l := f.ReadLine(), r++
        }
        if !f.AtEOF and l
          _processLine(l)
      } else _set(k, _processValue(_line, i), 1, _line, cp)
      IsSet(impt) && this.vital.Set(k, [cp, r])
    }

    _processValue(_lt, _idx, _raw := false) {
      s := '', cs := _lt.toCharArray(), inQ := false, q := this.q
      if !_raw and cs[_idx] = ic {
        _p := _processValue(_lt, _idx + 1, true)
        if !FileExist(_p)
          ThrowErr('文件不存在:' _p, _idx, _lt, cp)
        else return CustomFS(Path.IsAbsolute(_p) ? _p : Path.Join(Path.Dir(cp), _p), true).data
      }
      while _idx <= cs.Length {
        esc := false
        if cs[_idx] = A_Tab
          ThrowErr('不允许使用Tab', _idx, _lt, cp)
        else if cs[_idx] = ec
          esc := true, _idx++
        if _idx > cs.Length
          ThrowErr('转义符后应接任意字符', _idx, _lt, cp)
        if !inQ and cs[_idx] = A_Space {
          _i := _idx, _skipChar(cs, A_Space, &_idx)
          if _idx <= cs.Length and cs[_idx] != cc
            Warn(JoinStr('', '忽略了一条值的后续内容(', _lt.substring(_i), ')，因为没有在', q, '内使用空格'), _idx, _lt, cp)
          break
        } else if !esc and cs[_idx] = q
          inQ := !inQ
        else if !esc and cs[_idx] = cc {
          if inQ
            Warn('错误的读取到注释符，考虑是否需要转义', _idx, _lt, cp), s .= cs[_idx]
          else Warn('错误的读取到注释符，考虑是否正确闭合引号', _idx, _lt, cp), s .= cs[_idx]
        } else if !_raw and cs[_idx] = rc and !esc {
          _i := ++_idx, _jumpToChar(cs, rc, &_idx, '未找到成对的引用符'), _k := _lt.substring(_i, _idx)
          if !_has(_k) {
            if RegExMatch(_k, '\[(.*?)\]$', &o) {
              _k := _k.substring(1, o.Pos)
              try _v := _get(_k)[o[1]]
              catch
                ThrowErr('无效的引用:' o[1], _idx, _lt, cp)
              if !_v
                ThrowErr('无效的引用:' o[1], _idx, _lt, cp)
            } else ThrowErr('引用不存在的键或预设值:' _k, _idx, _lt, cp)
          } else _v := _get(_k)
          if !IsPrimitive(_v)
            ThrowErr('无法引用复杂类型', _idx, _lt, cp)
          s .= _v
        } else s .= cs[_idx]
        if _idx = cs.Length and inQ
          ThrowErr('未正确闭合引号', _idx, _lt, cp)
        _idx++
      }
      return s
    }

    _set(_k, _v, _c, _l, _f) {
      if this.vital.Has(_k)
        DCon(this.vital.Get(_k), &_f, &_r), ThrowErr('无法覆盖标记为重要的键:' _k, 1, '*' _l, '(重要键所在文件)' _f, _r)
      if this.data.Has(_k)
        Warn('覆盖已有的键:' _k, _c, _l, _f)
      this.data.Set(_k, _v)
    }
    _has(_k) => this.data.Has(_k) || CustomFS.preset.Has(_k)
    _get(_k) => this.data.Has(_k) ? this.data.Get(_k) : CustomFS.preset.Get(_k.toLowerCase())

    _jumpToChar(_chars, _char, &_idx, _msg) {
      while _idx <= _chars.Length and _chars[_idx] != _char
        _idx++
      if _msg and _idx > _chars.Length
        ThrowErr(_msg, _idx - 1, _chars.Join(''), cp)
    }

    _skipChar(_chars, _char, &_idx) {
      while _idx <= _chars.Length and _chars[_idx] = _char
        _idx++
    }

    ThrowErr(msg, _c, _l, _f, _r := r) {
      throw Error(JoinStr('', msg, '`n异常文件:', _f, '`n[行' _r, '列' _c ']', _l))
    }

    Warn(msg, _c, _l, _f, _r := r) => (
      this.doWarn && MsgBox(JoinStr(
        '', '`n' msg, '`n异常文件:', _f, '`n[行' _r, '列' _c ']', _l
      ), , 0x30)
    )

  }

  Get(key, default := '') => this.data.Get(key, default)
}