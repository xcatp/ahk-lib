#Requires AutoHotkey v2.0

#Include G:\AHK\git-ahk-lib\Extend.ahk
#Include G:\AHK\git-ahk-lib\Path.ahk

class CustomFSEx {

  data := Map(), cfgs := Map(), vital := Map(), encoding := 'utf-8', crlf := '`r`n', __data := [], __map := {}
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

  NT := {
    deleted: -1,
    ignore: 0,
    comment: 1,
    import: 3,
    empty: 4,
    literal: 5,
    func: 6,
    vital: 12,
    normal: 10,
    arr: 20,
    obj: 21,
    zipArr: 22
  }
  __New(_path, _warn, _init := true) {
    if !FileExist(_path)
      throw Error('读取的文件不存在:' _path)
    this.path := !Path.IsAbsolute(_path) ? Path.Resolve(A_ScriptDir, _path) : _path, this.doWarn := _warn
    if _init
      this.Init(this.path)
  }

  static Of(_path, _warn := false) => CustomFSEx(_path, _warn)
  static Empty(_path) => CustomFSEx(_path, false, false)

  Init(_path, _serId := 0) {
    f := FileRead(_path, this.encoding).split(this.crlf), r := 1, ec := this.escChar, rc := this.refChar, cc := this.commentChar, lc := this.literalChar
      , e := f.Length, ic := this.importChar, vc := this.vitalChar, import := false, cp := _path, this.cfgs.Set(cp.toLowerCase(), this.cfgs.Count + 1)
      , fnc := this.fnChar, fnl := this.fn_l, fnr := this.fn_r, zal := this.za_l, zar := this.za_r

    while r <= e {
      l := f[r++]
      if !import and l and l[1] = ic
        l := _processImport(l, _path)
      if !l {
        _empty()
        continue
      }
      if l[1] = cc or l ~= '^---' {
        _comment(l)
        continue
      }
      if l[1] = A_Space {
        _ignore(l), Warn('忽略了一行以空格开头的内容(' l ')', 0, l, cp)
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
        fi := 0, _ori := _l
        if this.cfgs.Has((_cp := _getNextPath()).toLowerCase())
          ThrowErr('导入重复文件:' _cp, 1, _l, cp)
        if !FileExist(_cp)
          ThrowErr('导入不存在的文件:' _cp, 1, _l, cp)
        _import(SubStr(_ori, 1, fi - 1), LTrim(_ori.substring(fi)))
        this.Init(_cp, _serId + 1), _l := f[r++]
        if !_l or _l[1] != ic or r > e
          break
      }
      return _l
      _getNextPath() => Path.IsAbsolute(_l := _processValue(_l, 2, , &fi)) ? _l : Path.Join(Path.Dir(_cp), _l)
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
        v := _processValue(_l, i, , &fi)
        DCon(_parseFuncDef(k), &name := 'fName', &params := 'params')
        postStr := _parseBody(v, params, &mapping := {})
        __f__ := (_p*) => __f.Bind(postStr, mapping, _p*)
        _set(name, __f__, i, _l, cp), _func(k, _l.substring(i, fi), _l.substring(fi))

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
        return (_set(k, _v := _l.substring(i), i, l, cp), _literal(k, _v))
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
        comment := def.substring(_i + 1).ltrim()
        def := def.substring(2, _i).trim()
        inQ := false, data := [], _i := 1, i := 0, rawData := []
        while ++i <= def.length {
          v := def[i]
          if i + 1 <= def.length and v = ec and def[i + 1] = this.q {
            i++
            continue
          }
          if !inQ and v = ',' {
            if _i != i and s := def.substring(_i, i).trim()
              data.push(_processValue(s, 1)), rawData.Push(s)
            _i := i + 1
          } else if v = this.q
            inQ := !inQ
        }
        if _i <= def.length
          data.Push(_processValue(s := def.substring(_i).trim(), 1)), rawData.Push(s)
        _set(k, data, _i, l, cp), _zipArr(k, rawData, comment)
        return
      }
      if i > cs.Length or cs[i] = cc {
        _c := _l.substring(i)
        if r > e
          ThrowErr('不允许空的复杂类型', i, _l, cp)
        l := f[r++]
        if !l or l[1] != '-' and l[1] != '+'
          ThrowErr('第一个子项必须与键连续', i, l, cp)
        isArr := l[1] = '-', vs := isArr ? [] : {}, pc := isArr ? '-' : '+', _set(k, vs, 1, l, cp), vsc := []
        while true {
          if !l or l[1] != pc
            break
          if isArr
            _l := LTrim(l.substring(2), A_Space), vs.Push(_v := _processValue(_l, 1, , &fi := 0))
              , vsc.push([_l.substring(1, fi), LTrim(_l.substring(fi))])
          else {
            cs := (_l := LTrim(l.substring(2), A_Space)).toCharArray(), _to(cs, ':', &_i := 1, '无效的键')
            _k := RTrim(_l.substring(1, _i)), vs.%_k% := _v := _processValue(_ := LTrim(_l.substring(_i + 1)), 1, , &fi := 0)
              , vsc.push([_k, _.substring(1, fi), LTrim(_.substring(fi))])
          }
          l := ''
          if r > e
            break
          l := f[r++]
        }
        isArr ? _array(k, vsc, _c) : _object(k, vsc, _c)
        if l
          _processLine(l)
        else _empty()
      } else {
        _set(k, v := _processValue(_l, i, , &fi := 0), 1, _l, cp)
        _fn := _normal
        IsSet(impt) ? (this.vital.Set(k, [cp, r]), _fn := _vital) : _fn := _normal
        _fn(k, _l.substring(i, fi), LTrim(_l.substring(fi)))
      }
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
        _s := _s.substring(2, _s.Length)
        _r := {}
        StrSplit(_s, ',').filter(v => v).foreach((v, i) => _r[v] := i)
        return _r
      }
    }

    _processValue(_l, _idx, _raw := false, &_fi := 0) {
      s := '', cs := _l.toCharArray(), inQ := false, q := this.q
      if !_raw and cs[_idx] = ic {
        _p := _processValue(_l, _idx + 1, true, &_fi)
        if !FileExist(_p)
          ThrowErr('文件不存在:' _p, _idx, _l, cp)
        else return CustomFSEx(Path.IsAbsolute(_p) ? _p : Path.Join(Path.Dir(cp), _p), true).data
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
            vals := params.keys.map(v => (v[1] = fnc) ? _doRef(v.substring(2)) : v)
            if CustomFSEx.buildinFunc.Has(name) {
              s .= CustomFSEx.buildinFunc.Get(name)(vals*), _idx++
              continue
            } else if _has(name) {
              s .= _get(name)(vals*)(), _idx++
              continue
            } else ThrowErr('未定义的函数', _idx, _l, cp)
          }
          _v := _doRef(_k)
          if !IsPrimitive(_v) {
            Warn('引用复杂类型', _idx, _l, cp)
            _fi := _idx
            return _v
          }
          s .= _v
        } else s .= cs[_idx]
        if _idx = cs.Length and inQ
          ThrowErr('未正确闭合引号', _idx, _l, cp)
        _idx++
      }
      _fi := _idx
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
    _has(_k) => this.data.Has(_k) || CustomFSEx.preset.Has(_k.toLowerCase())
    _get(_k) => this.data.Has(_k) ? this.data.Get(_k) : CustomFSEx.preset.Get(_k.toLowerCase())

    _ignore(v) => _serId = 0 && this.__data.Push({ v: v, t: this.NT.ignore })
    _comment(v) => _serId = 0 && this.__data.Push({ v: v, t: this.NT.comment })
    _import(v, c) => _serId = 0 && this.__data.Push({ v: v, t: this.NT.import, c: c })
    _empty() => _serId = 0 && this.__data.Push({ t: this.NT.empty })
    _literal(k, v) => _serId = 0 && this.__data.Push({ k: k, v: v, t: this.NT.literal })
    _func(k, v, c) => _serId = 0 && this.__data.Push({ k: k, v: v, t: this.NT.func, c: c })
    _vital(k, v, c) => _serId = 0 && (this.__data.Push({ k: k, v: v, t: this.NT.vital, c: c }), this.__map[k] := this.__data.Length)
    _normal(k, v, c) => _serId = 0 && (this.__data.Push({ k: k, v: v, t: this.NT.normal, c: c }), this.__map[k] := this.__data.Length)
    _array(k, v, c) => _serId = 0 && (this.__data.Push({ k: k, v: v, t: this.NT.arr, c: c }), this.__map[k] := this.__data.Length)
    _object(k, v, c) => _serId = 0 && (this.__data.Push({ k: k, v: v, t: this.NT.obj, c: c }), this.__map[k] := this.__data.Length)
    _zipArr(k, v, c) => _serId = 0 && (this.__data.Push({ k: k, v: v, t: this.NT.zipArr, c: c }), this.__map[k] := this.__data.Length)

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

  Has(key) => this.__map.HasOwnProp(key)

  Get(key, default := '') => this.data.Get(key, default)

  ; 为数组或对象添加子项。
  ; - 如果 key 不存在，返回 false
  ; - 如果为对象添加子项，需传入 subkey
  ; - 如果是 zipArr 的子项，comment 被忽略
  Append(key, val, subKey?, comment?) {
    if !(i := this.__map[key]) {
      return false
    }
    if IsArray(this.data[key]) {
      (this.__data[i].t = this.NT.arr)
      ? this.__data[i].v.Push([
        val,
        IsSet(comment) ? Format('  {} {}', this.commentChar, comment) : ''
      ])
      : this.__data[i].v.push(val)
      this.data[key].push(val)
    } else if TypeIsObj(this.data[key]) {
      this.data[key][subKey] := val
      this.__data[i].v.Push([
        subKey,
        val,
        IsSet(comment) ? Format('  {} {}', this.commentChar, comment) : ''
      ])
    } else return false
    return true
  }

  ; 设置值。
  ; - 如果key不存在，做add操作。
  ; - 如果是val对象类型，则认为是覆盖，删除此键，再重新添加(到末尾)。
  ; - 如果传入index，则认为是修改复合类型的子项；否则，直接设置key的值为val，是修改操作；
  ; - 如果是 zipArr 的子项，comment 被忽略
  Set(key, val, index?, comment?) {
    if !(i := this.__map[key]) {
      this.Add(key, val, comment?)
      return
    }
    if IsObject(val) {
      this.Del(key), this.Add(key, val, comment?)
      return
    }
    if IsSet(index) {
      if IsArray(this.data[key]) {
        if this.__data[i].t = this.NT.arr {
          this.data[key][index] := this.__data[i].v[index][1] := val
          IsSet(comment) && this.__data[i].v[index][2] := Format('  {} {}', this.commentChar, comment)
        } else this.data[key][index] := this.__data[i].v[index] := val
      } else {
        this.data[key][index] := (_v := (_v := this.__data[i].v)[_v.findIndex(_ => _[1] = index)])[2] := val
        this.__data[i].t := this.NT.obj
        IsSet(comment) && _v[3] := Format('  {} {}', this.commentChar, comment)
      }
    } else {
      this.data[key] := this.__data[i].v := val
      this.__data[i].t := this.NT.normal
      IsSet(comment) && this.__data[i].c := Format('  {} {}', this.commentChar, comment)
    }
  }

  Del(key, index?) {
    if !(i := this.__map[key])
      return false
    if IsSet(index) {
      if this.data[key].length = 1
        _DelItem()
      else
        IsArray(this.data[key]) ? _DelArrItem() : _DelObjItem()
    }
    else _DelItem()
    return true

    _DelItem() {
      this.data.Delete(key), this.__data[i].t := this.NT.deleted, this.__map[key] := 0
    }

    _DelArrItem() {
      this.data[key].RemoveAt(index), this.__data[i].v.RemoveAt(index)
    }

    _DelObjItem() {
      this.data[key].DeleteProp(index)
      (_v := this.__data[i].v).RemoveAt(_v.findIndex(_ => _[1] = index))
    }
  }

  ; 添加任意类型的数据
  ; - 如果 key 已存在，返回false
  ; - 根据 val 的类型决定添加的类型
  ; - 如果要添加 zipArr 类型，不要传入 subComment
  Add(key, val, comment := '', subComment?, preEmpty := true) {
    if this.__map[key]
      return false
    this.data[key] := val
    if preEmpty
      this.__data.Push({ t: this.NT.empty })
    switch {
      case IsArray(val):
        if IsSet(subComment) {
          this.__data.Push({
            k: key,
            v: val.map((_, _i) => [_, (subComment.Has(_i) && subComment[_i]) ? Format(' {} {}', this.commentChar, subComment[_i]) : '']),
            t: this.NT.arr,
            c: comment && Format('  {} {}', this.commentChar, comment)
          })
        } else {
          this.__data.Push({
            k: key,
            v: Array(val*),
            t: this.NT.zipArr,
            c: comment && Format('  {} {}', this.commentChar, comment)
          })
        }
      case TypeIsObj(val):
        _v := []
        for k, v in val.OwnProps()
          _v.push([k, v, !IsSet(subComment) ? '' : IsEmpty(subComment[k]) ? '' : Format('  {} {}', this.commentChar, subComment[k])])
        this.__data.Push({
          k: key,
          v: _v,
          t: this.NT.obj,
          c: comment && Format('  {} {}', this.commentChar, comment)
        })
      case IsString(val):
        this.__data.Push({ k: key,
          v: val,
          t: this.NT.normal,
          c: comment ? Format('  {} {}', this.commentChar, comment) : '' })
      default:
    }
    this.__map[key] := this.__data.Length
    return true
  }

  Sync(_path?) {
    t := '', _n := this.crlf
    for v in this.__data {
      switch v.t {
        case this.NT.ignore:
        case this.NT.comment: t .= Format('{}{}', v.v, _n)
        case this.NT.import: t .= Format('{} {}{}', v.v, v.c, _n)
        case this.NT.empty: t .= _n
        case this.NT.literal: t .= Format('{}{} :{}{}', this.literalChar, v.k, v.v, _n)
        case this.NT.func: t .= Format('{}{} : {} {}', this.fnChar, v.k, v.v v.c, _n)
        case this.NT.vital: t .= Format('{}{} : {} {}{}', this.vitalChar, v.k, v.v, v.c, _n)
        case this.NT.normal: t .= Format('{} : {} {}{}', v.k, v.v, v.c, _n)
        case this.NT.arr:
          t .= Format('{}:  {}{}', v.k, v.c, _n)
          for vv in v.v {
            _t .= Format('- {} {}{}', vv[1], vv[2], _n)
          }
          t .= _t, _t := ''
        case this.NT.obj:
          t .= Format('{}:  {}{}', v.k, v.c, _n)
          for vv in v.v {
            _t .= Format('+ {} : {} {}{}', vv[1], vv[2], vv[3], _n)
          }
          t .= _t, _t := ''
        case this.NT.zipArr:
          t .= Format('{}:  [ {} ]  {}{}', v.k, v.v.join(', '), v.c, _n)
        default:
      }
    }

    t := RTrim(_Format(t), this.crlf)
    f := FileOpen(IsSet(_path) ? _path : this.path, 'w', this.encoding)
    f.Write(t)
    f.Close()

    _Format(s) {
      r := StrSplit(s, this.crlf this.crlf).map(v => _alignBlock(v)).join(this.crlf this.crlf)
      if !r {
        throw Error('空输出，检查换行符是否匹配')
      }
      return r

      _alignBlock(block) {
        _b := StrSplit(block, this.crlf).filter(v => v), ml := 0, r := ''
        for v in _b {
          if i := InStr(v, ':') {
            key := RTrim(v.substring(1, i))
            ml := Max(ml, key.Length)
          }
        }
        for i, k in _b {
          if k[1] = '#' or k[1] = '@' or k[1] = '~'
            r .= k this.crlf
          else if index := InStr(k, ':') {
            key := Trim(k.substring(1, index))
            val := Trim(k.substring(index + 1))
            if i + 1 <= _b.Length and (_b[i + 1][1] = '-' or _b[i + 1][1] = '+') {
              r .= Format('{} : {}{}', key, val, this.crlf)
              continue
            }
            sl := ml - key.Length + 1
            r .= Format('{}{}: {}{}', key, A_Space.repeat(sl), val, this.crlf)
          } else r .= k this.crlf
        }
        return RTrim(r, this.crlf)
      }
    }
  }

}