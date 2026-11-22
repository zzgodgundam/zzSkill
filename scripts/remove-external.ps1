<#
.SYNOPSIS
  移除外部 skill submodule。
.EXAMPLE
  scripts\remove-external.ps1 anthropics-skills
#>
param([Parameter(Mandatory = $true, Position = 0)][string]$Name)
. (Join-Path $PSScriptRoot '_common.ps1')
$root = Enter-RepoRoot
$path = "external/$Name"

Invoke-Git submodule deinit -f -- $path
Invoke-Git rm -f -- $path
$moduleDir = Join-Path $root ".git\modules\$path"
if (Test-Path $moduleDir) { Remove-Item -Recurse -Force $moduleDir }

& (Join-Path $PSScriptRoot 'sync-project-skills.ps1')
if ((Get-GitOutput config --bool core.symlinks) -eq 'true') { Invoke-Git add -A -- .claude/skills }
Write-Host "已移除 $path，變更已加入暫存區。請執行: git commit -m `"Remove external skill: $Name`""
