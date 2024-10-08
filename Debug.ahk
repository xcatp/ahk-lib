#Include Extend.ahk
#Include Theme.ahk

IsSet(nd) || Debug.Show()

class Debug extends Gui {
  static ins := Debug()

  __New() {
    super.__New('+AlwaysOnTop -Caption +Border', 'Debug Window')
    this.SetFont('s13', 'consolas')
    this.AddButton('Section', 'clear').OnEvent('Click', (*) => this.content.Value := '')
    this.AddButton('yp', 'reload').OnEvent('Click', (*) => Reload())
    this.AddButton('yp', 'close').OnEvent('Click', (*) => this.Destroy())
    this.AddButton('yp', 'exit').OnEvent('Click', (*) => ExitApp())
    this.content := this.AddEdit('w600 h800 xs ReadOnly')
    OnMessage(0x0201, (*) => PostMessage(0xA1, 2)), Theme.Dark(this)
  }

  static Show() => (Debug.ins.Show('x' A_ScreenWidth - 650), WinSetTransparent(240, Debug.ins))
  static Log(msg) => Debug.ins.content.Value .= JoinStr('', '>', msg, '`n')
}

D(msg, topic := unset) => (IsSet(nd) || Debug.Log(JoinStr(' ', '[', topic?, ']', msg)))