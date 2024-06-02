CustomFs.ahk，由ahk编写的自定义配置文件解析工具。

# 注释
注释以`#`开头，支持尾随注释，不支持多行注释。
注释也可以`---`开头，且必须以`---`开头。
```text
# comment
key:val # comment

---
```

# 支持的数据类型
- 基本（一对一）
- 数组（一对多，子项为基本类型）
- 对象（一对多，子项为键值类型）

---

1. 基本

使用`:`分隔，`:`左右的空格会被忽略。
```text
foo : bar   # key:foo, value:bar
```

2. 数组

数组声明以`:`结尾，子项以`-`开头，子项必须连续。
```text
# key:arr, value:[item1, item2]
arr:
- item1
- item2
```

3. 对象

对象声明以`:`结尾，子项以`+`开头，子项必须连续。
```text
# key:obj, value:{k1:v1, k2:v2}
obj:
+ k1 : v1
+ k2 : v2
```

# 导入文件
导入语法分全局与局部，文件不可重复导入。
导入以`@`符开头，且全局导入必须在文档开头（数据之前）。
```text
# 导入前可以写注释
@./cfg.txt       # 全局导入

foo: @./bar.txt  # 局部导入
@./cfg1.txt      # 错误
```

# 修饰符
## 重要符*
可以在键前添加`*`符标记该数据为不可覆盖，可以避免被其他文件导入时被覆盖。
```text
*foo : bar
```
## 原义符~
可以在键前添加`~`符设置值为原义串，避免转义；此时`:`右边的空格会被当作值的一部分而不是忽略。
```text
# : $#
~raw :: $#
```

# 引用
使用`$`包裹的内容会被当作引用字段。可以在所有值中引用，而键不可以。  
脚本提供一组预设的引用值，可以在脚本中引用，可用预设值包括但不限于：
```A_MyDocuments, A_UserName,A_Startup, A_Now, A_Desktop, A_ScriptDir, A_ScriptFullPath```
```text
foo : bar
baz : $foo$-baz  # bar-baz
arr :
- arr-$baz$      # arr-bar-baz
```
## 复杂类型上的引用
如果引用的对象是复杂类型（对象或数组），将直接返回对象的引用。  
对于复杂类型的子项，可以使用`[]`引用。
```text
arr:
-a
obj:
+a : 1

ref  : $arr[1]$_$obj[a]$ # a_1
refA : aa$arr$    # 忽略aa前缀，并抛出警告
refO : $obj$oo    # 忽略oo后缀，并抛出警告
```

# 转义
使用`\``转义。
键中只有会造成混淆的关键字符需转义，值中出现的关键符大部分都需要转义。
最好的办法是在可能需要转义的地方都进行转义，因为转义普通字符不会造成任何错误。
```text
$foo  : `$bar    # $foo : $bar
`-foo : `@bar    # -foo : @bar
`#foo : ``b`ar   # #foo : `bar
```

# 值中的空格
解析中使用空格作为停止解析的标志，所以在使用到空格的地方需要特别处理。
使用`'`包围使用空格的值，以下两种方式结果相同。
```text
foo : bar' 'baz  # bar baz
foo : 'bar baz'  # bar baz
```

# 自定义
可以修改转义符、引用符、注释符、导入符、不可覆盖符、原义符及引号符为任意字符，这些符号在脚本中设置为变量。

# 示例
```text
# save directory
*base : $A_Desktop$\

group:
- $base$default
- $base$project
```

```text
@./saveDirs.txt  # import

meow : $base$meow.txt

hotkeys :
+ cancel : !``
+ submit : !s

edit : 'notepad $meow$'
~raw :use `$` to ref
```