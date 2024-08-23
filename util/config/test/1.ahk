/*
  测试 EX 的修改和写入
*/
#Include ../CustomFsEx.ahk

cfs := CustomFSEx.Empty('./out.txt')

; --- test zip array
cfs.Add('zipArr', [1, 2, 3], 'zip array')
cfs.Append('zipArr', 5)
cfs.Del('zipArr', 2)
cfs.Set('zipArr', '4', 2)

; zipArr : [ 1, 4, 5 ]  # zip array

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

; --- test string
cfs.Add('str', 'hello', 'cc')
cfs.Set('str', 'world', , 'ccc')

; str : world # ccc

; 对于修饰符、函数等功能并没有提供api，因为这些通常不需要是动态的。

cfs.Sync()