#Requires AutoHotkey v2.0

#Include ..\Extend.ahk
#Include ..\Path.ahk

class Explorer {

  __New(hwnd) {
    window := this._GetWindow(hwnd)
    if !window {
      throw Error('invalid window')
    }
    this.hwnd := hwnd
    this.isDesktop := window = 'desktop'
    this.window := window
  }

  static IsValidHwnd(hwnd) => WinGetProcessName('ahk_id' hwnd) = 'explorer.exe'
  static IsWinExist(hwnd) => WinExist('ahk_id' hwnd)

  _GetWindow(hwnd) {
    if !Explorer.IsValidHwnd(hwnd) {
      return
    }
    className := WinGetClass('ahk_id ' hwnd)
    if className ~= '(Cabinet|Explore)WClass' {
      for win in ComObject('Shell.Application').Windows
        if win.Hwnd = hwnd {
          return win
        }
    } else if className ~= 'Progman|WorkerW' {
      return 'desktop'
    }
  }

  _GetListViewContent(selection, options) {
    if !Explorer.IsWinExist(this.hwnd)
      return
    arr := []
    if this.isDesktop {
      List := ListViewGetContent(options, "SysListView321", 'ahk_class WorkerW')
      Loop Parse, List, "`n" {
        loop parse A_LoopField, A_Tab
          arr.Push(Path.Join(A_Desktop, A_LoopField))
      }
    } else {
      if selection
        collection := this.window.document.Selecteditems
      else
        collection := this.window.document.Folder.Items
      for item in collection {
        arr.push(item.path)
      }
    }
    return arr
  }

  GetListViewSelected() => this._GetListViewContent(true, "Selected Col1")
  GetListViewAll() => this._GetListViewContent(false, 'Col1')
  GetLocationURL() => (Explorer.IsWinExist(this.hwnd) && !this.isDesktop) ? this.window.LocationURL : ''
  GetURL() => SubStr(this.GetLocationURL(), 9)

  Shutdown() {
  }
}