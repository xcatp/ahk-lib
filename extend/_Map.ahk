#Requires AutoHotkey v2.0

#Include _Base.ahk

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