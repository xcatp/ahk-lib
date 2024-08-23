/*
  测试读取
*/
#Include ../CustomFS.ahk

cfs := CustomFS.Of('./_.txt')

MToString cfs.data