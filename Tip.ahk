/* 
  ; 使用静态方法（常用）
  Tip.ShowTip('hello')  ; 默认4s后隐藏
  ; 使用静态方法返回值
  clear := Tip.ShowTip('hello') ; clear方法仅在reuse为ture时返回
  Sleep(1000), clear()  ; 1s后手动销毁
 
  ; 使用构造方法
  _t := Tip('hello')
  _t.Display() ; 显示
  Sleep 1000
  _t.Recycle() ; 销毁
*/
#Requires AutoHotkey v2.0

#Include extend\Set.ahk

CoordMode 'ToolTip', 'Screen'

class Tip {
  static pool := Set()

  __New(text, weight := 1, x := unset, y := unset) {
    MouseGetPos(&mx, &my)
    IsSet(x) || x := mx, IsSet(y) || y := my
    if weight < 1 or weight >= 20
      throw Error('invalid weight')
    if Tip.pool.Has(weight)
      weight := this.GetAvailable()
    if !weight
      throw Error('no available')
    this.text := text, this.x := x, this.y := y, this.weight := weight
    Tip.pool.Add(weight)
  }

  GetAvailable() {
    index := 1
    while Tip.pool.Has(index)
      index++
    return index >= 20 ? 0 : index
  }

  Display() {
    ToolTip this.text, this.x, this.y, this.weight
    return this
  }

  Recycle() => (Tip.pool.Delete(this.weight), ToolTip(, , , this.weight))

  static ShowTip(text, x := 100, y := 50, duration := 4000, reuse := true) {
    return reuse
      ? _setTimerRemoveSingleToolTip(text, x, y, duration)
      : _setTimerRemoveMultiToolTip(text, x, y, duration)

    _setTimerRemoveSingleToolTip(text, x, y, time) {
      static clear := (*) => ToolTip(, , , 20)
      if !text
        return clear()
      ToolTip text, x, y, 20
      if !time
        return clear
      SetTimer clear, -time
    }

    _setTimerRemoveMultiToolTip(text, x, y, time) {
      if !text
        return
      t := Tip(text, , x, y), t.Display(), later := (*) => t.Recycle()
      SetTimer later, -time
    }
  }
}