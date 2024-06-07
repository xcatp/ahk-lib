#Include Extend.ahk

/** @example
 * g := Gui('')
 * g.SetFont('s15', 'consolas')
 * text := g.AddText(, 'Test')
 * g.AddEdit('+Background000')
 * ; Use [builder()]
 * Theme.Builder()
 *  .UseTheme('Dark')               ; set theme
 *  .TextFontColor('#abc')          ; set all text font color
 *  .BackColor('White')             ; set window background color
 *  .Build()                        ; build
 *  .SetCtrlOpts(text, '+cblack')   ; set single control's options
 *  .Apply(g)                       ; finally apply theme
 * ; Use Factory methods
 * Theme.Dark(g)
 * ; Or use custom theme
 * class MyTheme extends Theme.Themes {
 *  __New() {
 *    super.__New()
 *    this.default_Fc := 'green'
 *  }
 * }
 * ; Then call Theme.Custom()
 * Theme.Custom(g, MyTheme())
 * g.Show()
 */
class Theme {

  __New(_builder) {
    this.t := _builder.applyTheme
  }

  Custom := Map()

  SetCtrlOpts(ctrl, opts) {
    this.Custom.Set(ctrl.Hwnd, opts)
    return this
  }

  Apply(target) {
    if not target is Gui
      throw Error('target is no a gui')
    for k, v in this.t.OwnProps()
      this.t.%k% := LTrim(v, '#')
    target.BackColor := this.t.window_Bgc
    ctrls := WinGetControlsHwnd(target)
    for ctrl in ctrls {
      c := GuiCtrlFromHwnd(ctrl)
      if this.Custom.Has(ctrl) {
        c.Opt(this.Custom.Get(ctrl))
        continue
      }
      switch {
        case c is Gui.Edit: c.Opt('+Background' this.t.edit_Bgc ' +c' this.t.edit_Fc)
        case c is Gui.Text: c.Opt('+c' this.t.default_Fc)
        case c is Gui.ListView: c.Opt('+Background' this.t.lv_Bgc ' +c' this.t.lv_Fc)
        case c is Gui.StatusBar: c.Opt('-Theme +Background' this.t.statusBar_Bgc ' +c' this.t.statusBar_Fc)
        default:
      }
    }
    return this.t
  }

  static Dark(target) => Theme.Builder().UseTheme('Dark').Build().Apply(target)
  static Light(target) => Theme.Builder().UseTheme('Light').Build().Apply(target)
  static Custom(target, _theme) => Theme.Builder().UseTheme(_theme).Build().Apply(target)

  class Builder {

    __New() {
      this.applyTheme := Theme.Themes()
    }

    UseTheme(_theme := 'Light') {
      switch _theme {
        case 'Dark': this.applyTheme := Theme.Themes.Dark()
        case 'Light': this.applyTheme := Theme.Themes.Light()
        default:
          {
            if _theme is Theme.Themes {
              this.applyTheme := _theme
            } else Throw Error('invalid theme type: ' Type(_theme))
          }
      }
      return this
    }

    Chain(exp) => this
    BackColor(color) => this.Chain(this.applyTheme.window_Bgc := color)
    LvFontColor(color) => this.Chain(this.applyTheme.lv_Fc := this.color)
    LvBgc(color) => this.Chain(this.applyTheme.lv_Bgc := this.color)
    TextColor(color) => this.Chain(this.applyTheme.default_Fc := this.color)
    EditFontColor(color) => this.Chain(this.applyTheme.edit_Fc := this.color)
    EditBgc(color) => this.Chain(this.applyTheme.edit_Bgc := this.color)
    StatusBarFc(color) => this.Chain(this.applyTheme.statusBar_Fc := this.color)
    StatusBarBgc(color) => this.Chain(this.applyTheme.statusBar_Bgc := this.color)

    Build() => Theme(this)

  }

  class Themes {
    __New() {
      this.window_Bgc := 'white'
      this.default_Fc := 'Black'
      this.default_Bgc := this.window_Bgc
      this.edit_Fc := this.default_Fc
      this.edit_Bgc := this.default_Bgc
      this.lv_Fc := this.default_Fc
      this.lv_Bgc := this.default_Bgc
      this.statusBar_Fc := this.default_Fc
      this.statusBar_Bgc := 'grey'
    }

    class Dark extends Theme.Themes {
      __New() {
        super.__New()
        this.window_Bgc := '#1D2021'
        this.default_Fc := '#FABD2F'
        this.edit_Fc := '#61CEDB'
        this.edit_Bgc := '#292929'
        this.lv_Fc := '#B9CAE4'
        this.lv_Bgc := '#434957'
        this.statusBar_Fc := '#FABD2F'
        this.statusBar_Bgc := '#94A3BF'
      }
    }

    class Light extends Theme.Themes {
      __New() {
        super.__New()
        this.window_Bgc := '#f6eeda'
        this.default_Fc := '#682d00'
        this.edit_Fc := '#4b0c37'
        this.edit_Bgc := '#fffaf4'
        this.lv_Fc := '#00667d'
        this.lv_Bgc := '#fffaed'
        this.statusBar_Fc := '#682d00'
        this.statusBar_Bgc := '#e8e1cd'
      }
    }
  }

}