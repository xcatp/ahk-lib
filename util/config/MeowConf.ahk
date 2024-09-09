#Requires AutoHotkey v2.0

#Include G:\AHK\git-ahk-lib\Extend.ahk
#Include G:\AHK\git-ahk-lib\Path.ahk

class MeowConf {

  data := Map(), cfgs := Map(), vital := Map()
    , escChar := '``', refChar := '$', commentChar := '#', importChar := '@', vitalChar := '*', literalChar := '~', q := "'"
    , fnChar := '&', fn_l := '{', fn_r := '}', za_l := '[', za_r := ']'

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

  static buildinFunc := Map(  ; $1 presents params count
    'tc$1', StrTitle,
    'uc$1', StrUpper,
    'lc$1', StrLower,
  )

  __New(_path, _warn, _data, _encode, _eof) {
    this.encoding := _encode, this.eof := _eof, this.path := _path, this.doWarn := _warn
    this.Init(_path, _data)
  }

  class Builder {
    encoding := 'utf-8', eof := '`r`n'

    DataFromFile(_path) {
      if !FileExist(_path)
        throw Error('读取的文件不存在:' _path)
      this.path := !Path.IsAbsolute(_path) ? Path.Resolve(A_ScriptDir, _path) : _path
      this.data := FileRead(_path, this.encoding).split(this.eof)
      return this
    }
    DataFromArray(data, _p := Path.Join(A_ScriptDir, 'out.txt')) => (this.data := data, this.path := _p, this)
    SetEncoding(v) => (this.encoding := v, this)
    SetEOF(v) => (this.eof := v, this)
    SetWarn(v) => (this.doWarn := v, this)
    Build() => MeowConf(this.path, this.doWarn, this.data, this.encoding, this.eof)
  }

  static Of(_path, _warn := false) => MeowConf.Builder().DataFromFile(_path).SetWarn(_warn).Build()
  static Data(_data, _path?, _warn := false) => MeowConf.Builder().DataFromArray(_data, _path?).SetWarn(_warn).Build()

  static AddFunc(key, fn) {
    key .= '$' fn.MaxParams
    if MeowConf.buildinFunc.Has(key)
      throw Error('duplicate key: ' key)
    MeowConf.buildinFunc.Set(key, fn)
    return this
  }
  static DelFunc(key) => (MeowConf.buildinFunc.Delete(key), this)

  Init(_path, f) {
    r := 1, ec := this.escChar, rc := this.refChar, cc := this.commentChar, lc := this.literalChar, e := f.Length
      , ic := this.importChar, vc := this.vitalChar, cp := _path, this.cfgs.Set(cp.toLowerCase(), this.cfgs.Count + 1)
      , import := false, fnc := this.fnChar, fnl := this.fn_l, fnr := this.fn_r, zal := this.za_l, zar := this.za_r
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
        this.Init(_cp, FileRead(_cp, this.encoding).split(this.eof)), _l := f[r++]
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
      } else if _l[1] = vc {
        _l := _l.subString(2), impt := true
      } else if _l[1] = fnc {
        _l := _l.subString(2), fnDef := true
      }
      i := 1, cs := _l.toCharArray(), _to(cs, ':', &i, '无效的键，键须以:结尾')
      if IsSet(fnDef) and fnDef {  ; process func define
        k := Trim(_l.substring(1, i++)), _go(cs, A_Space, &i)
        v := _processValue(_l, i)
        DCon(_parseFuncDef(k), &name := 'fName', &params := 'params')
        if MeowConf.buildinFunc.Has(name)
          ThrowErr('无效的函数名，与内置函数同名；考虑更改函数名或使用重载', i, _l, cp)
        postStr := _parseBody(v, params, &mapping := {})
        __f__ := (_p*) => __f.Bind(postStr, mapping, _p*)
        _set(name, __f__, i, _l, cp)

        __f(str, mapping, p*) {
          i := 1, _chs := str.toChararray(), _r := '', _c := 1
          while i + 1 <= _chs.Length {
            if _chs[i] = fnl and _chs[i + 1] = fnr
              _r .= p[mapping[_c]], _c++, i++
            else _r .= _chs[i]
            i++
          }
          return _r
        }

        _parseBody(_s, _p, &_m) {
          _pos := 1, idx := {}, _r := ''
          for i, v in _s {
            if v = fnl {
              _pos := i
            } else if v = fnr {
              idx[idx.Length + 1] := _s.substring(_pos + 1, i)
              _r := SubStr(_r, 1, _r.Length - i + _pos + 1)
            }
            _r .= v
          }
          for k, v in idx.OwnProps()
            _m[k] := _p[v]
          return _r
        }

        return
      }
      k := _processValue(_l.substring(1, i++), 1, true)
      if k[1] = ':'
        Warn('以键值分隔符开头的键会造成混淆', 1, _l, cp)
      if IsSet(ori) and ori
        return _set(k, _l.substring(i), i, l, cp)
      if i <= cs.Length and cs[i] = A_Space
        _go(cs, A_Space, &i)
      if i < l.Length and cs[i] = zal { ; process zip array
        def := l.substring(i), inQ := false, _i := 1, i := 0
        while ++i <= def.length { ; find the position of ']'
          v := def[i]
          if i + 1 <= def.length and v = ec and def[i + 1] = this.q {
            i++
            continue
          }
          if !inQ and v = zar {
            _i := i
            break
          } else if v = this.q
            inQ := !inQ
        }
        if def[_i] != zar
          ThrowErr('无效的压缩数组定义，未找到右边界', _i, l, cp)
        def := def.substring(2, _i).trim()
        inQ := false, data := [], _i := 1, i := 0
        while ++i <= def.length {
          v := def[i]
          if i + 1 <= def.length and v = ec and def[i + 1] = this.q {
            i++
            continue
          }
          if !inQ and v = ',' {
            if _i != i and s := def.substring(_i, i).trim()
              data.push(_processValue(s, 1))
            _i := i + 1
          } else if v = this.q
            inQ := !inQ
        }
        if _i <= def.length
          data.Push(_processValue(def.substring(_i).trim(), 1))
        _set(k, data, _i, l, cp)
        return
      }
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
          l := ''
          if r > e
            break
          l := f[r++]
        }
        if l
          _processLine(l)
      } else _set(k, _processValue(_l, i), 1, _l, cp)
      IsSet(impt) && this.vital.Set(k, [cp, r])
    }

    _parseFuncDef(k) {
      _i := 1, _chs := k.toCharArray(), _to(_chs, '(', &_i, '无效的函数定义')
      params := _parse(k.substring(_i))
      fName .= k.substring(1, _i) '$' params.Length
      return { fName: fName, params: params }

      _parse(_s) {
        _s := StrReplace(_s, A_Space)
        if _s[1] != '(' or _s[-1] != ')'
          ThrowErr('无效的函数定义', _i, k, cp)
        if _s = '()' ; 无参
          return {}
        _s := _s.substring(2, _s.Length)
        _r := {}
        StrSplit(_s, ',').filter(v => v).foreach((v, i) => _r[v] := i)
        return _r
      }
    }

    _processValue(_l, _idx, _raw := false) {
      s := '', cs := _l.toCharArray(), inQ := false, q := this.q
      if !_raw and cs[_idx] = ic {
        _p := _processValue(_l, _idx + 1, true)
        if !FileExist(_p)
          ThrowErr('文件不存在:' _p, _idx, _l, cp)
        else return MeowConf.Builder()
          .DataFromFile(Path.IsAbsolute(_p) ? _p : Path.Join(Path.Dir(cp), _p)).SetWarn(this.doWarn).Build().data
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
          ; if is func
          if _k ~= '^\w+\(.*?\)$' {
            DCon(_parseFuncDef(_k), &name := 'fName', &params := 'params')
            ; 未做类型检查
            vals := params.keys.map(v => (v[1] = fnc) ? _doRef(v.substring(2)) : v)
            if MeowConf.buildinFunc.Has(name) {
              s .= MeowConf.buildinFunc.Get(name)(vals*), _idx++
              continue
            } else if _has(name) {
              s .= _get(name)(vals*)(), _idx++
              continue
            } else ThrowErr('未定义的函数', _idx, _l, cp)
          }
          _v := _doRef(_k)
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

      _doRef(_k) {
        if _has(_k)
          return _get(_k)
        if RegExMatch(_k, '\[(.*?)\]$', &re) {
          _k := _k.substring(1, re.Pos)
          try _v := (_o := _get(_k))[re[1]]
          catch
            ThrowErr('无效的引用:' re[1], _idx, _l, cp)
          if !_v and TypeIsObj(_o)
            ThrowErr('无效的对象子项引用:' re[1], _idx, _l, cp)
        } else ThrowErr('引用不存在的键或预设值:' _k, _idx, _l, cp)
        return _v
      }
    }

    _set(_k, _v, _c, _l, _f) {
      if this.vital.Has(_k)
        DCon(this.vital.Get(_k), &_f, &_r), ThrowErr('无法覆盖标记为重要的键:' _k, 1, '*' _l, '(重要键所在文件)' _f, _r)
      if this.data.Has(_k)
        Warn('覆盖已有的键:' _k, _c, _l, _f)
      this.data.Set(_k, _v)
    }
    _has(_k) => this.data.Has(_k) || MeowConf.preset.Has(_k.toLowerCase())
    _get(_k) => this.data.Has(_k) ? this.data.Get(_k) : MeowConf.preset.Get(_k.toLowerCase())

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