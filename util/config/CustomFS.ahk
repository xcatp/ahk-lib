#Requires AutoHotkey v2.0

#Include ..\..\Extend.ahk
#Include ..\..\Path.ahk

class CustomFS {

  data := Map(), cfgs := Map(), vital := Map(), encoding := 'utf-8'
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
    f := FileRead(_path, this.encoding).split('`r`n'), r := 1, ec := this.escChar, rc := this.refChar, cc := this.commentChar, lc := this.literalChar
      , e := f.Length, ic := this.importChar, vc := this.vitalChar, import := false, cp := _path, this.cfgs.Set(cp.toLowerCase(), this.cfgs.Count + 1)
    while r <= e {
      l := f[r++]
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

    _processImport(_l, _cp) {
      while true {
        if this.cfgs.Has((_cp := _getNextPath()).toLowerCase())
          ThrowErr('导入重复文件:' _cp, 1, _l, cp)
        if !FileExist(_cp)
          ThrowErr('导入不存在的文件:' _cp, 1, _l, cp)
        this.Init(_cp), _l := f[r++]
        if !_l or _l[1] != ic or r > e
          break
      }
      return _l
      _getNextPath() => Path.IsAbsolute(_l := _processValue(_l, 2)) ? _l : Path.Join(Path.Dir(_cp), _l)
    }

    _processLine(_l) {
      if _l[1] = ic
        Warn('以导入符开头的键，考虑是否为导入语句', 1, _l, cp)
      else if _l[1] = lc {
        _l := _l.subString(2), ori := true
      } else if _l[1] = vc
        _l := _l.subString(2), impt := true
      i := 1, cs := _l.toCharArray(), _to(cs, ':', &i, '无效的键，键须以:结尾'), k := _processValue(_l.substring(1, i++), 1, true)
      if k[1] = ':'
        Warn('以键值分隔符开头的键会造成混淆', 1, _l, cp)
      if IsSet(ori) and ori
        return _set(k, _l.substring(i), i, l, cp)
      if i <= cs.Length and cs[i] = A_Space
        _go(cs, A_Space, &i)
      if i > cs.Length or cs[i] = cc {
        if r > e
          ThrowErr('不允许空的复杂类型', i, _l, cp)
        l := f[r++], isArr := l[1] = '-'
        if l[1] != '-' and l[1] != '+'
          ThrowErr('第一个子项必须与键连续', i, l, cp)
        vs := isArr ? [] : {}, pc := isArr ? '-' : '+', _set(k, vs, 1, l, cp)
        while true {
          if !l or l[1] != pc
            break
          isArr ? (_l := LTrim(l.substring(2), A_Space), vs.Push(_processValue(_l, 1)))
            : (cs := (_l := LTrim(l.substring(2), A_Space)).toCharArray(), _to(cs, ':', &_i := 1, '无效的键')
              , _k := RTrim(_l.substring(1, _i)), vs.%_k% := _processValue(LTrim(_l.substring(_i + 1)), 1))
          if r > e
            break
          l := f[r++]
        }
        if r <= e and l
          _processLine(l)
      } else _set(k, _processValue(_l, i), 1, _l, cp)
      IsSet(impt) && this.vital.Set(k, [cp, r])
    }

    _processValue(_l, _idx, _raw := false) {
      s := '', cs := _l.toCharArray(), inQ := false, q := this.q
      if !_raw and cs[_idx] = ic {
        _p := _processValue(_l, _idx + 1, true)
        if !FileExist(_p)
          ThrowErr('文件不存在:' _p, _idx, _l, cp)
        else return CustomFS(Path.IsAbsolute(_p) ? _p : Path.Join(Path.Dir(cp), _p), true).data
      }
      while _idx <= cs.Length {
        esc := false
        if cs[_idx] = A_Tab
          ThrowErr('不允许使用Tab', _idx, _l, cp)
        else if cs[_idx] = ec
          esc := true, _idx++
        if _idx > cs.Length
          ThrowErr('转义符后应接任意字符', _idx, _l, cp)
        if !inQ and cs[_idx] = A_Space {
          _i := _idx, _go(cs, A_Space, &_idx)
          if _idx <= cs.Length and cs[_idx] != cc
            Warn(JoinStr('', '忽略了一条值的后续内容(', _l.substring(_i), ')，因为没有在', q, '内使用空格'), _idx, _l, cp)
          break
        } else if !esc and cs[_idx] = q
          inQ := !inQ
        else if !esc and cs[_idx] = cc {
          inQ ? (Warn('错误的读取到注释符，考虑是否需要转义', _idx, _l, cp), s .= cs[_idx])
            : (Warn('错误的读取到注释符，考虑是否正确闭合引号', _idx, _l, cp), s .= cs[_idx])
        } else if !_raw and cs[_idx] = rc and !esc {
          _i := ++_idx, _to(cs, rc, &_idx, '未找到成对的引用符'), _k := _l.substring(_i, _idx)
          if !_has(_k) {
            if RegExMatch(_k, '\[(.*?)\]$', &re) {
              _k := _k.substring(1, re.Pos)
              try _v := (_o := _get(_k))[re[1]]
              catch
                ThrowErr('无效的引用:' re[1], _idx, _l, cp)
              if !_v and TypeIsObj(_o)
                ThrowErr('无效的对象子项引用:' re[1], _idx, _l, cp)
            } else ThrowErr('引用不存在的键或预设值:' _k, _idx, _l, cp)
          } else _v := _get(_k)
          if !IsPrimitive(_v) {
            Warn('引用复杂类型', _idx, _l, cp)
            return _v
          }
          s .= _v
        } else s .= cs[_idx]
        if _idx = cs.Length and inQ
          ThrowErr('未正确闭合引号', _idx, _l, cp)
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
    _has(_k) => this.data.Has(_k) || CustomFS.preset.Has(_k.toLowerCase())
    _get(_k) => this.data.Has(_k) ? this.data.Get(_k) : CustomFS.preset.Get(_k.toLowerCase())

    _to(_chars, _char, &_idx, _msg) {
      while _idx <= _chars.Length and _chars[_idx] != _char
        _idx++
      if _msg and _idx > _chars.Length
        ThrowErr(_msg, _idx - 1, _chars.Join(''), cp)
    }

    _go(_chars, _char, &_idx) {
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
  Has(key) => this.data.Has(key)
}