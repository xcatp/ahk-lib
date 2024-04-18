#Requires AutoHotkey v2.0

#Include ..\Extend.ahk


; Get folder size with unit byte, to get other unit, use [AutoByteFormat()]
FolderGetSize(_path) {
  try bytes := ComObject("Scripting.FileSystemObject").GetFolder(_path).Size
  catch {
    bytes := 0
    Loop Files, _path "\*.*", "R"
      bytes += A_LoopFileSize
  }
  return bytes
}

AutoByteFormat(size, decimalPlaces := 2) {
  static sizes := ["KB", "MB", "GB", "TB"]
  sizeIndex := 0
  while (size >= 1024) {
    sizeIndex++
    size /= 1024.0
    if (sizeIndex = sizes.Length)
      break
  }
  return (sizeIndex = 0) ? size " B" : round(size, decimalPlaces) . " " . sizes[sizeIndex]
}