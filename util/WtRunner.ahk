#Requires AutoHotkey v2.0

#Include ..\Extend.ahk

/**@example
 * WtRunner.Builder()
 *   .Window(-1)
 *   .NewTab('Test', , '#97d1f3', A_ScriptDir, 'echo Hello_WtRunner')
 *   .SplitPane('sp1', WtRunner.Profiles.GitBash, , , '#c68bc6')
 *   .SplitPane('sp2', WtRunner.Profiles.GitBash, '-H', , '#9fcac8', , 'echo SplitPane2!')
 *   .Build()
 *   .RunCmd()
 */
class WtRunner {

  static Profiles := {
    Default: 'Command Prompt',
    GitBash: 'Git Bash',
    PowerShell7: 'PowerShell7',
    Cmd: 'Command Prompt'
  }

  cmd := 'wt'

  __New(_builder) { ; do conact
    if IsTrue(w := _builder.globalParam.Window)
      this.cmd .= ' -w ' w
    if IsTrue(size := _builder.globalParam.size)
      this.cmd .= ' --size ' size[1] ',' size[2]
    if IsTrue(pos := _builder.globalParam.pos)
      this.cmd .= ' --pos ' pos[1] ',' pos[2]
    if IsTrue(_builder.globalParam.focus)
      this.cmd .= ' --focus '
    this.cmd .= ' ' _builder.tabs.Join(';')
  }
  ; Min Max Hide
  RunCmd(flag?) => Run(this.cmd, , flag?)

  class Builder {

    globalParam := { window: '', size: '', pos: '', focus: false }, tabs := []

    Chain(exp) => this
    Window(idOrName) => this.Chain(this.globalParam.window := idOrName)
    Size(r, c) => this.Chain(this.globalParam.size := [r, c])
    Pos(x, y) => this.Chain(this.globalParam.pos := [x, y])
    Focus(v) => this.Chain(this.globalParam.focus := v)
    NewTab(title, profile?, tabColor?, startDirectory?, command?, preCmd := ' pwsh -NoExit -c ') {
      _cmd := 'nt --title "' title '"'
      if IsSet(profile)
        _cmd .= ' --profile "' profile '"'
      if IsSet(tabColor)
        _cmd .= ' --tabColor ' tabColor ''
      if IsSet(startDirectory)
        _cmd .= ' -d "' startDirectory '"'
      if IsSet(command)
        _cmd .= preCmd command
      this.tabs.Push(_cmd)
      return this
    }
    ; The param with 'f' prefix specify that it is a flag, means that without value
    SplitPane(title, profile?, fDirection := '-V', size := 0.5, tabColor?, startDirectory?, command?, preCmd := ' pwsh -NoExit -c ') {
      _cmd := 'sp --title "' title '"'
      if IsSet(profile)
        _cmd .= ' --profile "' profile '"'
      if IsSet(tabColor)
        _cmd .= ' --tabColor ' tabColor ''
      if IsSet(startDirectory)
        _cmd .= ' -d "' startDirectory '"'
      _cmd .= ' ' fDirection ' --size ' size
      if IsSet(command)
        _cmd .= preCmd command
      this.tabs.Push(_cmd)
      return this
    }

    Build() => WtRunner(this)
  }
}