<#
.SYNOPSIS
  將所有外部 skill submodule 更新到最新版本。
.DESCRIPTION
  - .gitmodules 中設定 track = tag 的 submodule：更新到最新正式版 tag（略過 -rc/-beta 等預發布版）
  - 其他 submodule：更新到追蹤分支（branch）的最新 commit
.EXAMPLE
  scripts\update-external.ps1           # 更新並顯示變更
.EXAMPLE
  scripts\update-external.ps1 -Commit   # 更新並自動 commit
#>
param([switch]$Commit)
. (Join-Path $PSScriptRoot '_common.ps1')
$root = Enter-RepoRoot

Invoke-Git submodule sync --recursive
Invoke-Git submodule update --init --recursive

$entries = @(Get-GitOutput config -f .gitmodules --get-regexp '^submodule\..*\.path$')
foreach ($e in $entries) {
    if (-not $e) { continue }
    $key, $path = $e -split ' ', 2
    $name = $key -replace '^submodule\.', '' -replace '\.path$', ''
    $track = Get-GitOutput config -f .gitmodules --get "submodule.$name.track"
    if ($track -eq 'tag') {
        Invoke-Git -C $path fetch --tags --force --quiet origin
        $latest = Get-LatestTag $path
        if (-not $latest) { Write-Warning "$path 沒有可用的 tag，維持不變"; continue }
        Invoke-Git -C $path -c advice.detachedHead=false checkout --quiet $latest
        Write-Host "$path -> tag $latest"
    } else {
        Invoke-Git submodule update --remote --recursive -- $path
        $branch = Get-GitOutput config -f .gitmodules --get "submodule.$name.branch"
        if (-not $branch) { $branch = 'HEAD' }
        Write-Host "$path -> branch $branch ($(Get-GitOutput -C $path rev-parse --short HEAD))"
    }
}

& (Join-Path $PSScriptRoot 'sync-project-skills.ps1')

& git diff --quiet -- external
if ($LASTEXITCODE -eq 0) { Write-Host '所有外部 skill 都已是最新版本。'; exit 0 }

Write-Host '以下 submodule 有更新:'
Invoke-Git submodule summary -- external

if ($Commit) {
    Invoke-Git add external
    if ((Get-GitOutput config --bool core.symlinks) -eq 'true') { Invoke-Git add -A -- .claude/skills }
    Invoke-Git commit -m 'Update external skills to latest'
    Write-Host '已 commit，請執行 git push。'
} else {
    Write-Host '確認無誤後執行: scripts\update-external.ps1 -Commit，或 git add external 後自行 commit'
}
