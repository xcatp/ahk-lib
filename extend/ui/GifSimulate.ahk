#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\..\Extend.ahk
#Include ..\..\Tip.ahk
#Include ..\..\Path.ahk

#Include ImageGdipBased.ahk

; gif := GifSimu(picDir, 'idle', '001', '.png')
class GifSimu {

  data := {
    start: 1,
    end: 1,
    delay: 30
  }

  __New(picDir, name, initValue, suffix) {
    this.img := Image.Of(Path.Join(picDir, JoinStr('', name, initValue, suffix)))
    this.data.baseDir := picDir
    this.data.name := name
    this.data.width := initValue.Length
    this.data.suf := suffix
  }

  SetRange(start, end) {
    this.data.start := start, this.data.end := end
    return this
  }

  SetDelay(time) {
    this.data.delay := time
    return this
  }

  Show(x, y) {
    this.img.Show(x, y)
    return this
  }

  Chain() => this
  GetContainer() => this.img

  Start(doOnChange) {
    container := this.img
    idx := this.data.end, i := this.data.start, flag := true
    baseDir := this.data.baseDir, name := this.data.name, suf := this.data.suf
    width := this.data.width, delay := this.data.delay

    _cycle() {
      if flag {
        fileIdx := _preZero(width, Mod(i, idx) + 1), i++
        next := Path.Join(baseDir, JoinStr('', name, fileIdx, suf))
        container.SetSource(next), Sleep(delay), doOnChange(container, next)
      }
    }

    _startTimer()
    return [_abort, _restart]

    _startTimer() => SetTimer(_cycle, this.data.delay)

    _abort(doOnAbort := Noop) {
      if flag
        flag := false, SetTimer(_cycle, 0), doOnAbort(container.GetX(), container.GetY())
    }

    _restart(doOnRestart := Noop) {
      if !flag
        flag := true, _startTimer(), doOnRestart(container.GetX(), container.GetY())
    }

    _preZero(_width, input) {
      w := (input . '').Length
      return (_width <= w) ? input : '0'.repeat(_width - w) input
    }
  }

}