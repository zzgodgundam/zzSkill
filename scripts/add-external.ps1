<#
.SYNOPSIS
  新增他人的 skill repository 為 submodule。
.EXAMPLE
  scripts\add-external.ps1 https://github.com/anthropics/skills anthropics-skills        # 追蹤遠端預設分支
.EXAMPLE
  scripts\add-external.ps1 https://github.com/owner/repo my-name dev                   # 追蹤指定分支
.EXAMPLE
  scripts\add-external.ps1 -Tag https://github.com/mattpocock/skills mattpocock-skills  # 追蹤最新正式版 tag
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Url,
    [Parameter(Position = 1)][string]$Name,
    [Parameter(Position = 2)][string]$Branch,
    [switch]$Tag
)
. (Join-Path $PSScriptRoot '_common.ps1')
$root = Enter-RepoRoot

if (-not $Name) { $Name = ($Url.TrimEnd('/') -split '/')[-1] -replace '\.git$', '' }
$path = "external/$Name"

if ($Tag) {
    Invoke-Git submodule add $Url $path
    Invoke-Git config -f .gitmodules "submodule.$path.track" tag
    $latest = Get-LatestTag $path
    if (-not $latest) { throw "$Url 沒有正式版 tag，請改用分支追蹤" }
    Invoke-Git -C $path -c advice.detachedHead=false checkout --quiet $latest
    $desc = "tag $latest"
} else {
    if (-not $Branch) {
        $line = Get-GitOutput ls-remote --symref $Url HEAD | Where-Object { $_ -like 'ref:*' } | Select-Object -First 1
        if ($line -match 'refs/heads/(\S+)') { $Branch = $Matches[1] } else { throw '無法偵測遠端預設分支，請指定分支' }
    }
    Invoke-Git submodule add -b $Branch $Url $path
    $desc = "分支 $Branch"
}

Invoke-Git add .gitmodules $path
& (Join-Path $PSScriptRoot 'sync-project-skills.ps1')
if ((Get-GitOutput config --bool core.symlinks) -eq 'true') { Invoke-Git add -A -- .claude/skills }

Write-Host "已新增 $path (追蹤: $desc)，變更已加入暫存區"
Write-Host "請執行: git commit -m `"Add external skill: $Name`""
