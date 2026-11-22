<#
.SYNOPSIS
  將本 repo 中的所有 skill 以連結方式安裝到 Claude Code 的 skills 目錄（全域使用）。
.DESCRIPTION
  掃描 skills\ 與 external\ 下所有含 SKILL.md 的資料夾，
  並清除目標目錄中指向本 repo、但已不再是 skill 的無效連結（不會動到其他來源的 skill）。
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

$current = @{}
$count = 0
foreach ($rel in (Get-SkillDirs $root | Sort-Object)) {
    $name = Split-Path $rel -Leaf
    $link = Join-Path $Target $name
    if (Test-Path -LiteralPath $link) {
        if (-not (Test-ReparsePoint $link)) { Write-Host "略過 ${name}：$link 已存在且不是連結"; continue }
        Remove-Link $link
    }
    $full = Join-Path $root $rel
    $kind = New-DirLink -Link $link -Target $full
    $current[$full.Replace('/', '\').TrimEnd('\').ToLowerInvariant()] = $true
    Write-Host "已連結 $name -> $rel ($kind)"
    $count++
}
# 清除無效連結：指向本 repo 但目標已不存在或不再是 skill
$removed = 0
$rootKey = $root.Replace('/', '\').TrimEnd('\').ToLowerInvariant() + '\'
Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint } | ForEach-Object {
    $dest = @($_.Target)[0]
    if (-not $dest) { return }
    $key = $dest.Replace('/', '\').TrimEnd('\')
    if ($key.StartsWith('\\?\')) { $key = $key.Substring(4) }
    $key = $key.ToLowerInvariant()
    if (-not $key.StartsWith($rootKey)) { return }
    if (-not $current.ContainsKey($key)) {
        Remove-Link $_.FullName
        Write-Host "已移除無效連結 $($_.Name) -> $($dest.Substring([Math]::Min($dest.Length, $rootKey.Length)))"
        $removed++
    }
}

Write-Host "完成，共安裝 $count 個 skill 到 $Target（移除 $removed 個無效連結）"
