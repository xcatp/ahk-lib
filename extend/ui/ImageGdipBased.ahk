#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\..\Extend.ahk
#Include ..\..\lib\gdip\GdipStarter.ahk


class Image extends Gui {

  data := {}, _flipH := false, _flipV := false, state := 0

  __New(filePath, angle := 0, OnContex := Noop, OnLbtnDown := Noop) {
    super.__New('-Caption +E0x80000 +AlwaysOnTop +ToolWindow +OwnDialogs')
    this.angle := angle
    this
      .SetSource(filePath)
      .SetInterpolationMode(7)
      .RegisterEventOnContex(OnContex)
      .RegisterEventOnLbtnDown(OnLbtnDown)
  }

  static Of(filePath) => Image(filePath)

  Show(x, y, opts := '') {
    this.state := 1
    super.Show('NA' opts)
    this.data.xy := { x: x, y: y }
    this._DoUpdate()
    return this
  }

  Hide() {
    this.state := 0
    super.Hide()
    return this
  }

  Move(x, y, w?, h?) {
    this.data.xy := { x: x, y: y }
    this._DoUpdate()
    return this
  }

  Scale(ratio) {
    rw := this.data.wh.w, rh := this.data.wh.h
    this.data.swh := { w: rw * ratio, h: rh * ratio }
    this._DoUpdate()
    return this
  }

  Translate(tx, ty) {
    rx := this.data.xy.x, ry := this.data.xy.y
    this.Move(rx + tx, ry + ty)
    return this
  }

  ; return the centre x y
  GetPos(&x, &y, &w?, &h?) {
    x := this.data.xy.x, y := this.data.xy.y
    super.GetPos(, , &w?, &h?)
  }
  GetRealPos(&x, &y, &w?, &h?) => super.GetPos(&x, &y, &w?, &h?)
  GetX() => this.data.xy.x
  GetY() => this.data.xy.y
  Dispose() => Gdip_DisposeImage(this.pBitmap)
  __Delete() => this.Dispose()

  Update() {
    oriW := this.data.wh.w, oriH := this.data.wh.h, angle := this.angle, pBitmap := this.pBitmap
    iterpolationMode := this.data.mode
    GetAdjustWH(oriW, oriH, &w, &h)
    Gdip_GetRotatedDimensions(w, h, angle, &rw, &rh)
    x := this.data.xy.x, y := this.data.xy.y
    Gdip_GetRotatedTranslation(w, h, angle, &xt, &yt)
    hbm := CreateDIBSection(rw, rh), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
    G := Gdip_GraphicsFromHDC(hdc), Gdip_SetInterpolationMode(G, iterpolationMode)
    Gdip_TranslateWorldTransform(G, xt, yt)
    Gdip_RotateWorldTransform(G, angle)
    if this._flipH
      Gdip_ScaleWorldTransform(G, -1, 1), Gdip_TranslateWorldTransform(G, -w, 0)
    if this._flipV
      Gdip_ScaleWorldTransform(G, 1, -1), Gdip_TranslateWorldTransform(G, 0, -h)
    Gdip_DrawImage(G, pBitmap, 0, 0, w, h, 0, 0, oriW, oriH)
    Gdip_ResetWorldTransform(G)
    UpdateLayeredWindow(this.Hwnd, hdc, x - rw // 2, y - rh // 2, rw, rh)
    SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
    Gdip_DeleteGraphics(G)

    GetAdjustWH(ow, oh, &nw, &nh) {
      ratio := ow / oh, nw := ow, nh := oh
      _adapter() ; If the screen can't display, adjust it
      if this.data.HasProp('swh') {
        nw := this.data.swh.w, nh := this.data.swh.h
      }

      _adapter() {
        if ow > A_ScreenWidth || oh > A_ScreenHeight {
          if ow >= oh
            nw := A_ScreenWidth, nh := nw * (1 / ratio)
          else nh := A_ScreenHeight, nw := nh * ratio
        }
      }
    }
  }

  _DoUpdate() {
    if this.state
      this.Update()
    return this
  }

  _Chain(exp) => this
  ; .Log(next, (msg) => Tip.ShowTip(msg)) or .Log(next, MsgBox) and such on
  Log(msg, fn) => this._Chain(fn(msg))
  Wait(time) => this._Chain(Sleep(time))
  Rotate(angle) => this._Chain(this.angle := Mod(angle, 360))._DoUpdate()
  FlipH() => this._Chain(this._flipH := !this._flipH)._DoUpdate()
  FlipV() => this._Chain(this._flipV := !this._flipV)._DoUpdate()

  ; Default = 0 LowQuality = 1 HighQuality = 2 Bilinear = 3 Bicubic = 4 NearestNeighbor = 5 HighQualityBilinear = 6 HighQualityBicubic = 7
  SetInterpolationMode(mode) => this._Chain(this.data.mode := mode)

  SetSource(filePath) {
    if this.HasProp('pBitmap')
      this.Dispose()             ; don't forget it
    this.pBitmap := Gdip_CreateBitmapFromFile(filePath)
    if !this.pBitmap
      throw Error('can not create bitmap from file :' filePath)
    this.data.wh := _GetWH(this.pBitmap)
    this._DoUpdate()
    return this

    _GetWH(pBitmap) {
      oriW := Gdip_GetImageWidth(pBitmap), oriH := Gdip_GetImageHeight(pBitmap)
      return { w: oriW, h: oriH }
    }
  }

  RegisterEventOnContex(_OnContex) {
    if not _OnContex = Noop
      this.OnEvent('ContextMenu', (o, co, item, isRClk, x, y, *) => _OnContex(o, co, item, isRClk, x, y))
    return this
  }

  RegisterEventOnLbtnDown(_OnLbtnDown) {
    if not _OnLbtnDown = Noop
      OnMessage(0x0201, (wParam, lParam, msg, hwnd) => _OnLbtnDown(this, wParam, lParam, msg, hwnd))
    return this
  }

}

if A_ScriptFullPath = A_LineFile {

  #Include ..\..\Path.ahk
  #Include ..\..\Tip.ahk

  picDir := A_Desktop '\tmp\Run'
  p1 := 'G:\AHK\gitee_ahk2\screen_paste\history\MeowPaste_20240322_123858.bmp'
  p2 := Path.Join(picDir, 'run001.png')

  ; TestEvent()
  TestSetSource()

  TestScale() {
    img := Image.Of(p2)
    img
      .Scale(5)
      .SetInterpolationMode(5)
      .Show(500, 500)
  }

  TestMove() {
    img := Image.Of(p1)
    img
      .Show(200, 200).Wait(200)
      .Move(300, 200).Wait(200)
      .Move(400, 200).Wait(200)
  }

  TestRotateFlip() {
    img := Image.Of(p1)
    img
      .Show(200, 200)
    loop 36 {
      img.GetPos(&x, &y)
      img
        .Rotate(A_Index * 10).Wait(100)
        .FlipH()
        .Move(x + 10, y + 10).Wait(100)
        .FlipV()
    }
  }

  TestSetSource() {
    img := Image.Of(p2)
    img.Show(100, 1060)

    idx := 17, dir := 1
    loop {
      fileIdx := _preZero(3, Mod(A_Index, idx) + 1)
      p := Path.Join(picDir, JoinStr('', 'run', fileIdx, '.png'))
      img.SetSource(p).Translate(2 * dir, 0).Wait(40)
      if (img.GetX() >= 1800 || img.GetX() <= 100) {
        img.FlipH(), dir *= -1
      }
    }

    _preZero(width, input) {
      w := (input . '').Length
      return (width <= w) ? input : '0'.repeat(width - w) input
    }
  }

  TestEvent() {
    CoordMode 'Mouse', 'Screen'

    OnLbtnDown(container, *) {
      PostMessage(0xA1, 2)
      KeyWait 'LButton'
      MouseGetPos(&x, &y)
      container.Move(x, y)
    }

    Image.Of(p2)
      .RegisterEventOnLbtnDown(OnLbtnDown)
      .Show(500, 500)
  }

}