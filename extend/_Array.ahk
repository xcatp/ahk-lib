#Requires AutoHotkey v2.0

#Include _Base.ahk
#Include _String.ahk

Array.DefineProp('From', { call: _From })

arrProto := Array.Prototype
arrProto.DefineProp("Concat", { call: _Concat_Array })
arrProto.DefineProp("Peek", { call: _Peek })
arrProto.DefineProp("At", { call: _At_Array })
arrProto.DefineProp("Every", { call: _Every })
arrProto.DefineProp("Fill", { call: _Fill })
arrProto.DefineProp("Flat", { call: _Flat })
arrProto.DefineProp("Filter", { call: _Filter })
arrProto.DefineProp("Find", { call: _Find })
arrProto.DefineProp("FindIndex", { call: _FindIndex })
arrProto.DefineProp("FindLast", { call: _FindLast })
arrProto.DefineProp("FindLastIndex", { call: _FindLastIndex })
arrProto.DefineProp("ForEach", { call: _ForEach })
arrProto.DefineProp("DeepClone", { call: _DeepClone })
arrProto.DefineProp("Includes", { call: _Includes })
arrProto.DefineProp("Join", { call: _Join })
arrProto.DefineProp("Map", { call: _Map })
arrProto.DefineProp("Reduce", { call: _Reduce })
arrProto.DefineProp("Reverse", { call: _Reverse })
arrProto.DefineProp("ToReverse", { call: _ToReverse })
arrProto.DefineProp("Shift", { call: _Shift })
arrProto.DefineProp("Max", { call: _Max })

; 静态方法从字符串或数组创建一个新的**深拷贝**的数组实例。
_From(this, arrayLike, mapFn?) {
  if not (IsArray(arrayLike) or IsString(arrayLike))
    throw Error('invalid param')
  if IsSet(mapFn) {
    switch mapFn.MaxParams {
      case 1: _fn := (v, *) => mapFn(v)
      case 2: _fn := (v, index, *) => mapFn(v, index)
      default: throw Error('invalid callback function')
    }
  } else _fn := (v, *) => v
  arr := []
  if arrayLike is Array {
    for v in arrayLike
      arr.Push(_fn(v, A_Index))
  } else arr := arrayLike.ToCharArray()
  return arr
}

; 将两个或多个数组或值合并成一个新数组。
; 此方法不会更改现有数组，而是返回一个新数组。
_Concat_Array(this, value*) {
  r := this.DeepClone()
  for v in value
    IsArray(v) ? r.Push(v*) : r.Push(v)
  return r
}

; 查看数组末尾元素
_Peek(this) => this[this.Length]

; 方法接收一个整数值并返回该索引对应的元素，允许正数和负数。
; 负整数从数组中的最后一个元素开始倒数，0是无效索引。
_At_Array(this, index) => index > 0 ? this[index] : this[this.Length + index + 1]

; 测试一个数组内的所有元素是否都能通过指定函数的测试。
; 它返回一个布尔值。
_Every(this, cb) {
  copy := this
  switch cb.MaxParams {
    case 1: _fn := (v, *) => cb(v)
    case 2: _fn := (v, index, *) => cb(v, index)
    case 3: _fn := (v, index, arr) => cb(v, index, arr)
    default: throw Error('invalid callback function')
  }
  for v in copy {
    if !_fn(v, A_Index, copy)
      return false
  }
  return true
}

; 用一个固定值填充一个数组中从起始索引（默认为 0）到终止索引（默认为 array.length）内的全部元素。
; 它返回修改后的数组。
_Fill(this, value, start?, end?) {
  l := this.Length
  if IsSet(start) {
    if IsSet(end) {
      end := end > l ? l : end
      start := start > end ? end : start
      d := end - start
    } else d := start > l ? l : l - start
    loop d + 1
      this[start + A_Index - 1] := value
  } else loop l
    this[A_Index] := value
}

; 扁平化数组，传入-1表示无限
_Flat(this, depth) {
  stack := [this.map(item => [item, depth])*], res := []
  while (stack.Length > 0) {
    sub := stack.Pop(), _item := sub[1], _depth := sub[2]
    if (IsArray(_item) && (_depth > 0 || depth = -1))
      stack.Push(_item.map(el => [el, _depth - 1])*)
    else res.Push(_item)
  }
  return res.reverse()
}

; 创建给定数组一部分的**深拷贝**（与js不同），其包含通过所提供函数实现的测试的所有元素。
_Filter(this, cb) {
  r := []
  switch cb.MaxParams {
    case 1: _fn := (v, *) => cb(v)
    case 2: _fn := (v, index, *) => cb(v, index)
    case 3: _fn := (v, index, arr) => cb(v, index, arr)
    default: throw Error('invalid callback function')
  }
  for v in this {
    if _fn(v, A_Index, this)
      r.Push(v)
  }
  return r
}

; 返回数组中满足提供的测试函数的第一个元素的值。否则返回 空。
_Find(this, cb) {
  for v in this {
    if cb(v)
      return v
  }
}

; 返回数组中满足提供的测试函数的第一个元素的索引。
; 若没有找到对应元素则返回 -1。
_FindIndex(this, cb) {
  for v in this {
    if cb(v)
      return A_Index
  }
  return -1
}

; 反向迭代数组，并返回满足提供的测试函数的第一个元素的值。
_FindLast(this, cb) {
  loop l := this.Length {
    if cb(v := this[l - A_Index + 1])
      return v
  }
}

; 反向迭代数组，并返回满足提供的测试函数的第一个元素的索引。
_FindLastIndex(this, cb) {
  loop l := this.Length {
    if cb(this[l - A_Index + 1])
      return l - A_Index + 1
  }
  return -1
}

; 对数组的每个元素执行一次给定的函数。
; 仅执行，而不返回任何结果
_ForEach(this, cb) {
  switch cb.MaxParams {
    case 1: _fn := (v, *) => cb(v)
    case 2: _fn := (v, index, *) => cb(v, index)
    case 3: _fn := (v, index, arr) => cb(v, index, arr)
    default: throw Error('invalid callback function')
  }
  for v in this
    _fn(v, A_Index, this)
}

; 返回数组的深拷贝。
_DeepClone(this) {
  arr := []
  for v in this
    arr.Push(v)
  return arr
}

; 用指定分隔符连接数组元素。
; 返回一个字符串
_Join(this, separator := ',') {
  if this.Length {
    for v in this {
      if IsSet(v)
        r .= v (A_Index != this.Length ? separator : '')
    }
    return r || ''
  }
}

; 用来判断一个数组是否包含一个指定的值，根据情况，如果包含则返回 true，否则返回 false。
_Includes(this, searchElement, fromIndex?) {
  if IsSet(fromIndex) {
    l := this.Length
    if fromIndex > 0 {
      if fromIndex > l
        return false
      i := fromIndex
    } else {
      if fromIndex < -l || fromIndex = 0
        return this.FindIndex((v) => v = searchElement) != -1
      i := l + fromIndex + 1
    }
    c := l - i + 1
    loop c {
      if this[i + A_Index - 1] = searchElement
        return true
    }
    return false
  } else {
    return this.FindIndex((v) => v = searchElement) != -1
  }
}
; 创建一个新数组，这个新数组由原数组中的每个元素都调用一次提供的函数后的返回值组成。
_Map(this, cb) {
  switch cb.MaxParams {
    case 1: _fn := (v, *) => cb(v)
    case 2: _fn := (v, index, *) => cb(v, index)
    case 3: _fn := (v, index, arr) => cb(v, index, arr)
    default: throw Error('invalid callback function')
  }
  res := []
  for v in this
    res.push(_fn(v, A_Index, this))
  return res
}
; 对数组中的每个元素按序执行一个提供的 reducer 函数，每一次运行 reducer 会将先前元素的计算结果作为参数传入。
; 最后将其结果汇总为单个返回值。
_Reduce(this, cb, initialValue?) {
  if !this.Length and !IsSet(initialValue)
    throw TypeError('Reduce of empty array with no initial value')
  switch cb.MaxParams {
    case 1: _fn := (accumulator, *) => cb(accumulator)
    case 2: _fn := (accumulator, curVal, *) => cb(accumulator, curVal)
    case 3: _fn := (accumulator, curVal, index, *) => cb(accumulator, curVal, index)
    case 4: _fn := (accumulator, curVal, index, arr) => cb(accumulator, curVal, index, arr)
    default: throw Error('invalid callback function')
  }
  accumulator := initialValue ?? this[1], i := IsSet(initialValue) ? 1 : 2
  loop this.Length - i + 1
    accumulator := _fn(accumulator, this[i], i, this), i++
  return accumulator
}

; 就地反转数组中的元素，并返回同一数组的引用。
_Reverse(this) {
  l := this.Length
  loop l / 2 {
    temp := this[A_Index]
    this[A_Index] := this[l - A_Index + 1]
    this[l - A_Index + 1] := temp
  }
  return this
}
; 反转数组中的元素，并返回新数组的引用。
_ToReverse(this) {
  l := this.Length, arr := []
  loop l
    arr.Push(this[l - A_Index + 1])
  return arr
}
; 从数组中删除第一个元素，并返回该元素的值。此方法更改数组的长度。
_Shift(this) => this.RemoveAt(1)

_Max(this) {
  if !this.Length
    return
  ans := this[1]
  for v in this
    ans := Max(v, ans)
  return ans
}
_Min(this) {
  if !this.Length
    return
  ans := this[1]
  for v in this
    ans := Min(v, ans)
  return ans
}

; @dev
_DeepEquals(this, other) {
  if this.Length != other.Length {
    return false
  }

}