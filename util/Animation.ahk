#Requires AutoHotkey v2.0

#Include ..\Extend.ahk

; g := Gui('+AlwaysOnTop +ToolWindow -Caption')
; g.AddEdit('w600 h500')

; Animation.FadeIn(g)
; Sleep 1000
; Animation.FadeOut(g, true)

; Animation.RollDown(g)
; Sleep 1000
; Animation.RollUp(g)

CoordMode 'Mouse'

class Animation {

  static FadeOut(target, hide := false, wait := 10) {
    loop 25 {
      Sleep(wait), WinSetTransparent(255 - A_Index * 10, target)
    }
    hide ? target.Hide() : target.Destroy()
  }

  static FadeIn(target, doAfterShow := Noop, doAdapter := unset, wait := 10) {
    target.Show('Hide'), WinSetTransparent(0, target), target.Restore()
    if IsSet(doAdapter)
      doAdapter(), target.getPos(&x, &y, &w, &h)
    else target.getPos(&x, &y, &w, &h), _setPos(&x, &y)
    target.Show('x' x ' y' y ' NA'), doAfterShow()
    loop 25 {
      Sleep(wait), WinSetTransparent(A_Index * 10, target)
    }
    WinSetTransparent(255, target)


    _setPos(&x, &y) {
      MouseGetPos(&mx, &my)
      x := mx, y := my
      if mx + w > A_ScreenWidth
        x := mx - w
      if my + h > A_ScreenHeight
        y := my - h
    }
  }

  static RollDown(target, doAfterShow := Noop, doAdapter := unset) {
    target.Show('Hide'), WinSetTransparent(0, target), target.Restore()
    if IsSet(doAdapter)
      doAdapter(), target.getPos(&x, &y, &w, &h)
    else target.getPos(&x, &y, &w, &h), _setPos(&x, &y)
    target.Move(, , , 0)
      , WinSetTransparent(255, target)
      , target.Show('x' x ' y' y ' NA')
      , doAfterShow()
    loop h
      target.Move(, , , A_Index)

    _setPos(&x, &y) {
      MouseGetPos(&mx, &my)
      x := mx, y := my
      if mx + w > A_ScreenWidth
        x := mx - w
      if my + h > A_ScreenHeight
        y := my - h
    }
  }


  static RollUp(target, hide := false) {
    target.GetPos(, , , &h)
    loop h
      target.Move(, , , h - A_Index)
    target.Move(, , , h), hide ? target.Hide() : target.Destroy()
  }

}