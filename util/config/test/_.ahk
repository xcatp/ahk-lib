#Include ../MeowConf.ahk
#Include ../MeowConfEx.ahk

TestAddFunc()

TestRead() {
  ; 测试读取
  cfs := MeowConfEx.Of('./_.txt')
  MToString cfs.data
}

TestData() {
  ; 测试 Data 静态方法
  cfs := MeowConfEx.Data(['a : b', 'c : $a$'])
  MToString cfs.data
}

TestAddFunc() {
  ; 测试注册方法
  cfs := MeowConf
    .AddFunc('me', () => 'xcatp')
    .AddFunc('me', (_) => _ ' xcatp')
    .Data(['meow : $me()$--$me(hello)$'])

  MsgBox cfs.Get('meow')
}

TestEx() {
  ; 测试 EX 的修改和写入
  cfs := MeowConfEx.Empty('./out.txt')
  specialChs := "'@#$[],`` "

  ; --- test zip array
  cfs.Add('zipArr', [1, 2, 3], 'zip array')
  cfs.Append('zipArr', 5)
  cfs.Del('zipArr', 2)
  cfs.Set('zipArr', '4', 2)

  ; zipArr : [ 1, 4, 5 ]  # zip array

  cfs.Append('zipArr', specialChs)
  cfs.Set('zipArr', specialChs, 2)

  ; --- test array
  cfs.Add(
    'arr',
    ['a', 'b', 'c'],
    'cc',
    []
  )

  cfs.Set('arr', 'B', 2, 'B')
  cfs.Append('arr', 'D', , 'D')
  cfs.Del('arr', 3)

  /*
  arr : # cc
  - a
  - B # B
  - D # D
  */

  cfs.Append('arr', specialChs)
  cfs.Set('arr', specialChs, 2)

  ; --- test object
  cfs.Add(
    'obj', {
      a: 'a',
      b: 'b'
    },
    'obj', {
      a: 'A'
    }
  )

  cfs.Append('obj', 'C', 'C', 'C')
  cfs.Del('obj', 'b')
  cfs.Set('obj', 'A', 'a', 'AA')

  /*
  obj : # obj
  + a : A # AA
  + C : C # C
  */

  cfs.Append('obj', specialChs, 'd')
  cfs.Set('obj', specialChs, 'a')

  ; --- test string
  cfs.Add('str', 'hello', 'cc')
  cfs.Set('str', 'world', , 'ccc')

  ; str : world # ccc

  cfs.Set('str', specialChs)

  ; 对于修饰符、函数等功能并没有提供api，因为这些通常不需要是动态的。

  cfs.Sync()
}