#Requires AutoHotkey v2.0

; 系统取色器对话框
ColorExtractor(initColor := unset, ownerId := 0, palettes := []) {
  palettes := palettes.Length
    ? palettes
    : [0x1C7399, 0xEEEEEC, 0x014E8B, 0x444444, 0x009FE8, 0xDEF9FA, 0xF8B62D, 0x90FC0F, 0x0078D7, 0x0D1B0A, 0xB9D497, 0x00ADEF, 0x1778BF, 0xFDF6E3, 0x002B36, 0xDEDEDE]
  for k, v in palettes
    NumPut('uint', v, ccs := Buffer(64, 0), 4 * (A_Index - 1))
  c := initColor ?? 0xABCABC, c := ((c & 0xFF) << 16) + (c & 0xFF00) + ((c >> 16) & 0xFF), _s := Buffer(size := 72, 0)
    , NumPut('uint', size, _s)
    , NumPut('ptr', ownerId, _s, 8)
    , NumPut('uint', c, _s, 24)
    , NumPut('ptr', ccs.Ptr, _s, 32)
    , NumPut('uint', 0x00000103, _s, 40)
  rc := DllCall('comdlg32\ChooseColor', 'ptr', _s.Ptr)
  if !rc
    return
  c := NumGet(_s, 24, 'uint'), _c := ((c & 0xFF) << 16) + (c & 0xFF00) + ((c >> 16) & 0xFF)
    , r := ((_c & 0xff0000) >> 16), g := ((_c & 0x00ff00) >> 8), b := (_c & 0xff)
  return {
    RGB: Format("0x{:06X}", _c),
    BGR: Format("0x{1:02X}{2:02X}{3:02X}", b, g, r),
    RRGGBB: r "," g "," b
  }
}