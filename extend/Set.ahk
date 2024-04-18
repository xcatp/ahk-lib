#Requires AutoHotkey v2.0

#Include _Array.ahk

class Set extends Map {
  __new(value*) {
    kv := []
    value.foreach(v => kv.Push(v, 0))
    super.__New(kv*)
  }

  Add(e*) {
    for v in e {
      if this.Has(v) {
        return false
      }
      super.Set(v, 0)
    }
    return true
  }

  Count => super.Count

  Has(e) => super.Has(e)
  Clear() => super.Clear()
  Delete(e) => super.Delete(e)
}