#Requires AutoHotkey v2.0

#Include ..\Extend.ahk

class Cursor {

  static x => Cursor._Methods.GetXY().x
  static y => Cursor._Methods.GetXY().y
  static clientX => Cursor._Methods.getCXY().x
  static clientY => Cursor._Methods.getCXY().y

  static MoveTo(x, y, speed?, relative?) {
    MouseMove(x, y, speed?, relative?)
    return this
  }

  static Click(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?) {
    MouseClick(WhichButton?, X?, Y?, ClickCount?, Speed?, DownOrUp?, Relative?)
    return this
  }

  static ClickDrag(WhichButton, X1, Y1, X2, Y2, Speed?, Relative?) {
    MouseClickDrag(WhichButton, X1, Y1, X2, Y2, Speed?, Relative?)
    return this
  }

  static SetCursorIcon(type) {
    static init := 0, table := Map(), ID := Map("NORMALL", 32512, 'IBEAM', 32513, 'WAIT', 32514
      , 'CROSS', 32515, "SIZENWSE", 32642, "SIZENESW", 32643
      , "SIZEWE", 32644, "SIZENS", 32645, "SIZEALL", 32646
      , 'NO', 32648, 'HAND', 32649
    )
    if !init {
      init := 1
      OnExit((*) => Cursor.SetCursorIcon(A_Cursor))
      For k, v in ID {
        table[k] := DllCall("CopyImage", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", v)
          , "int", 2, "int", 0, "int", 0, "int", 0)
      }
    }
    if table.Has(type)
      DllCall("SetSystemCursor", "ptr", DllCall("CopyImage", "ptr", table[type]
        , "int", 2, "int", 0, "int", 0, "int", 0, "ptr"), "int", 32512)
    else DllCall("SystemParametersInfo", "int", 0x57, "int", 0, "ptr", 0, "int", 0)
  }

  class CursorType {
    static no := 'NO'
    static wait := 'WAIT'
    static hand := 'HAND'
    static ibeam := 'IBEAM'
    static cross := 'CROSS'
    static arrow := 'NORMALL'
    static sizeWE := 'SIZEWE'
    static sizeNS := 'SIZENS'
    static sizeAll := 'SIZEALL'
    static sizeNWSE := 'SIZENWSE'
    static sizeNESW := 'SIZENESW'
  }

  class _Methods {
    static GetXY() {
      before := CoordMode('Mouse', 'Screen')
      MouseGetPos(&x, &y)
      CoordMode('Mouse', before)
      return { x: x, y: y }
    }

    static GetCXY() {
      before := CoordMode('Mouse', 'Client')
      MouseGetPos(&x, &y)
      CoordMode('Mouse', before)
      return { x: x, y: y }
    }
  }

}