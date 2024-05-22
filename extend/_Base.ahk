#Requires AutoHotkey v2.0

DefProp := {}.DefineProp
Noop(*) => {}

IsMap(_obj) => _obj is Map
IsArray(_obj) => _obj is Array
IsString(_obj) => _obj is String
IsVarRef(_obj) => _obj is VarRef
IsComObj(_obj) => _obj is ComObject
IsFunction(_obj) => _obj is Func
IsPrimitive(_obj) => _obj is Primitive

; [] is array also object
TypeIsObj(_obj) => Type(_obj) = 'object'

; > "a blank or zero result is considered false and all other results are considered true"
IsTrue(var) => var != '' && var != 0
IsFalse(var) => !IsTrue(var)

IsEmpty(var) => IsFalse(var)
  || IsArray(var) and var.Length = 0
  || IsMap(var) and var.Count = 0
  || TypeIsObj(var) and ObjOwnPropCount(var) = 0