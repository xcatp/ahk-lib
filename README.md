extends for ahk2, make code easier.

# 脚本介绍

- extend 目录

此目录下的脚本是对 ahk 各种内置对象的扩展，包括方法、属性及静态方法。  
在这些扩展下，可以像编写`JS`一样编写 ahk。  
详细介绍见目录下`Readme`。

- lib 目录

此目录下包括使用频率不高，但对于某些场景特别有用的外部功能封装。  
如：windows组件、GdiPlus.

- util 目录

此目录下是常用的实用工具脚本，让编写 ahk 更效率。  
详细介绍见脚本头部注释。

- 根目录

包含最常用的一些脚本，其中：
- `Extend.ahk`是extend目录下脚本的集合，通常在每个脚本中引入此脚本即可。
- `Debug.ahk`是方便调试的。一般用`MsgBox`输出内容，而它十分不方便；使用此脚本可以方便许多。
- `Path.ahk`类似于`NodeJs`下的Path模块，用于操作文件路径。
- `RunCMD.ahk`来自官方仓库的脚本，用于无窗口运行`cmd`命令。
- `ShellRun.ahk`同样用于运行`cmd`命令，具有更高的自定义性。
- `Theme.ahk`用于一行代码设置`ui`控件颜色，十分实用。
- `Tip.ahk`是对内置函数`Tooltip`的封装，可完全替代内置的`Tooltip`。


# 如何使用？

此仓库内的脚本通常被其他脚本`Include`，做为工具库存在。

只需要拉取此仓库，然后在自己的脚本中引入需要的即可。

# 与其他仓库一起使用

> 在我的其他仓库中，都使用了此仓库。

因为 ahk 的`#Include`指令内部只能使用一些特定的变量，我们只能将路径写死；所以拉取我其他仓库的脚本是无法直接使用的。

**需要修改#Include的路径。**

我为此写了脚本一键的修改路径，详细见仓库`ahk-scripts/scripts/IncludeResolveGui.ahk`