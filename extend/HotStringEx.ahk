#Requires AutoHotkey v2.0
#SingleInstance Force

#Include g:\AHK\git-ahk-lib\Extend.ahk


/**
 * @example
 * ; register actions by constructor
 * _ih := HotStringEx('~;', 1, ['foo', (*) => SendText('bar')])
 * ; or via [_ih.register()] method
 * actions := [
 *   ['btw', (*) => SendText('by the way')],
 *   ['jq', (*) => SendText('jquery')]
 * ]
 * _ih.Register(actions*)
 * ; cancel actions
 * _ih.Cancel('btw') ; O(n) operation
 * ; set timeout function or max-limit function
 * _ih.TimeOutFunc := (*) => MsgBox('timeout')
 * 
 */
class HotStringEx {

  actions := Map()
  matchList := ''
  TimeOutFunc := Noop
  MaxFunc := Noop

  ; ['jq', (*)=>'jquery'], ...
  __New(hk, hkLen, listAndActions*) {
    this.hk := hk
    this.hkLen := hkLen
    if (listAndActions.Length) {
      this._Update(listAndActions)
      Hotkey this.hk, (*) => this._Start(this.matchList), 'On'
    }
  }

  _Update(_param) {
    for v in _param
      this.actions.Set(v[1], v[2])
    for k in this.actions
      _matchList .= k ','
    this.matchList := RTrim(_matchList, ',')
  }

  _Start(matchList) {
    ih := InputHook('V T5 L8 C', '{space};', matchList)
    ih.Start()
    ih.Wait()
    switch ih.EndReason {
      case "Max": this.MaxFunc()
      case "Timeout": this.TimeOutFunc()
      case "EndKey":
      default:
        Send JoinStr('', '{BS ', this.hkLen + ih.input.Length, '}')
        this.actions.Get(ih.Input)()
    }
  }

  _Reload() => Hotkey(this.hk, (*) => this._Start(this.matchList), 'On')

  Register(listAndActions*) {
    this._Update(listAndActions)
    this._Reload()
  }

  Cancel(list*) {
    for key in list
      this.actions.Delete(key)
    this._Update('')
  }
}