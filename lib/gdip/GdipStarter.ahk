#Include .\gdip4ahk2.ahk

if !pToken := Gdip_Startup() {
  MsgBox 'gidplus failed to start. Please ensure you have gdiplus on your system.'
  ExitApp
}
OnExit((*) => Gdip_Shutdown(pToken))