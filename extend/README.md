# String

- 获取原型定义方法：
```
DefProp := {}.DefineProp
```

- Add Methods

```
DefProp("".base, "CharAt", { call: _CharAt })

_CharAt(this, index) {
  if index <= 0 || index > this.Length
    throw Error('Index ' index ' out of range')
  charArr := StrSplit(this)
  return charArr[index]
}
```
例：`'hello'.charAt(-1)`

- 使字符串可枚举
```
; __Enum
DefProp("".base, "__Enum", { call: String_Enum })
DefProp("".base, "ToCharArray", { call: StrSplit })
String_Enum(this, paramCnt) => this.toCharArray().__Enum()
```

例：
```
for i, v in 'hello'
  MsgBox i v
```

- 使字符串可使用下标
```
DefProp("".base, "__item", { get: __item_String })
__item_String(this, index) => this.CharAt(index)
```
例：`'hello'[1]`

- 添加属性

```
DefProp("".base, "Length", { get: StrLen })
```
例：`'hello'.Length`

# Array

数组与字符串大体一致，只是获取原型方式不一致:

```
arrProto := Array.Prototype
```

- 添加静态方法
```
Array.DefineProp('From', { call: _From })

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
```
例：`Array.from('Hello')`


# Object

以下代码添加了对象下标语法和两个实用属性：
```
defProp({}.base, "__item", { get: item_obj_get, set: item_obj_set })
defProp({}.base, "Length", { get: ObjOwnPropCount })
defProp({}.base, "Count", { get: ObjOwnPropCount })

; Usage:
; ```
; obj := { key: 'value'}
; MsgBox obj['key']
;```
item_obj_get(this, key) => this.HasProp(key) ? this.%key% : ''

; Usage:
; ```
;     MsgBox (obj['foo'] := 'bar')
; ```
item_obj_set(this, key, value) => this.%value% := key    ; For unknown reasons, we need to use it in reverse

```

# Integer

与对象类似。
```
DefProp(0.base, "BitCount", { call: _BitCount })
DefProp(0.base, "ToBase", { call: _ToBase })
DefProp(0.base, "Between", { call: _Between })

_BitCount(this) {
  n := this
  n := (n >> 1 & 0x55555555) + (n & 0x55555555)
  n := (n >> 2 & 0x33333333) + (n & 0x33333333)
  n := (n >> 4 & 0x0F0F0F0F) + (n & 0x0F0F0F0F)
  n := (n >> 8 & 0xff00ff) + (n & 0xff00ff)
  n := (n >> 16 & 0xffff) + (n & 0xffff)
  return n
}

_ToBase(this, b) => (this < b ? "" : _ToBase(this // b, b)) . ((d := Mod(this, b)) < 10 ? d : Chr(d + 55))
_Between(this, l, r) => this >= l && this <= r
```

# Map

与数组类似。
```
mapProto := Map.Prototype
mapProto.DefineProp('OwnProps', { call: _Map_OwnProps })
mapProto.DefineProp("Length", { get: (this) => this.Count })
mapProto.DefineProp('Keys', { get: _Map_Keys })

_Map_OwnProps(this) => this.__Enum()
_Map_Keys(this) {
  ks := []
  for k in this
    ks.Push(k)
  return ks
}
```

# 结语

以上，向许多内置对象上添加了属性和方法，以及更好的扩展。

对于未提到的，也可以使用类似的方法来自定义。
