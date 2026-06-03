# Inline replacement for the ilammy/msvc-dev-cmd action.
# Locates Visual Studio, runs vcvars64.bat, and exports the resulting
# environment changes to subsequent workflow steps via GITHUB_ENV / GITHUB_PATH.
$ErrorActionPreference = 'Stop'

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) { throw "Visual Studio with VC tools not found" }
$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'

# Snapshot the environment, then capture it again after running vcvars64.bat.
$before = @{}
Get-ChildItem Env: | ForEach-Object { $before[$_.Name] = $_.Value }
$after = @{}
cmd /c "`"$vcvars`" >nul && set" | ForEach-Object {
  if ($_ -match '^([^=]+)=(.*)$') { $after[$matches[1]] = $matches[2] }
}

# Export only changed variables; merge new PATH entries into GITHUB_PATH.
foreach ($name in $after.Keys) {
  $value = $after[$name]
  if ($before[$name] -eq $value) { continue }
  if ($name -ieq 'Path') {
    $old = if ($before.ContainsKey('Path')) { $before['Path'] -split ';' } else { @() }
    ($value -split ';') | Where-Object { $_ -and ($old -notcontains $_) } | ForEach-Object {
      Add-Content -Path $env:GITHUB_PATH -Value $_
    }
  } else {
    Add-Content -Path $env:GITHUB_ENV -Value "$name=$value"
  }
}
