<#
.SYNOPSIS
  將本 repo 中的所有 skill 以連結方式安裝到 Claude Code 的 skills 目錄（全域使用）。
.DESCRIPTION
  掃描 skills\ 與 external\ 下所有含 SKILL.md 的資料夾。
  優先建立 symlink（需開發人員模式或系統管理員），否則改用 junction（不需權限）。
.EXAMPLE
  scripts\install.ps1                         # 預設安裝到 %USERPROFILE%\.claude\skills
.EXAMPLE
  scripts\install.ps1 D:\proj\.claude\skills  # 安裝到指定目錄
#>
param([Parameter(Position = 0)][string]$Target = (Join-Path $HOME '.claude\skills'))
. (Join-Path $PSScriptRoot '_common.ps1')
$root = Enter-RepoRoot
New-Item -ItemType Directory -Force -Path $Target | Out-Null
Invoke-Git submodule update --init --recursive

$count = 0
foreach ($rel in (Get-SkillDirs $root | Sort-Object)) {
    $name = Split-Path $rel -Leaf
    $link = Join-Path $Target $name
    if (Test-Path -LiteralPath $link) {
        if (-not (Test-ReparsePoint $link)) { Write-Host "略過 ${name}：$link 已存在且不是連結"; continue }
        Remove-Link $link
    }
    $kind = New-DirLink -Link $link -Target (Join-Path $root $rel)
    Write-Host "已連結 $name -> $rel ($kind)"
    $count++
}
Write-Host "完成，共安裝 $count 個 skill 到 $Target"
