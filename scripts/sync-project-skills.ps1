<#
.SYNOPSIS
  在 .claude/skills/ 建立指向所有 skill 的連結，讓在此 repo 開啟的 Claude Code 自動載入整個 skill set。
.DESCRIPTION
  新增/移除 skill 或更新 submodule 後請重新執行（add/remove/update 腳本會自動呼叫）。
  - git core.symlinks=true（建議，需開啟 Windows 開發人員模式）：建立真正的 symlink，與 Linux/macOS 完全相同。
  - 否則：本機改用 junction，並直接更新 git index 中的 symlink 項目（標記 skip-worktree），
    讓 commit 內容仍是跨平台正確的相對 symlink。
#>
. (Join-Path $PSScriptRoot '_common.ps1')
$root = Enter-RepoRoot
$dest = Join-Path $root '.claude\skills'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$gitSymlinks = (Get-GitOutput config --bool core.symlinks) -eq 'true'

# 清除舊連結（symlink / junction / git 產生的文字檔），不動實體資料夾
Get-ChildItem -LiteralPath $dest -Force | ForEach-Object {
    if ((Test-ReparsePoint $_.FullName) -or -not $_.PSIsContainer) { Remove-Link $_.FullName }
}

$names = @{}
$count = 0
$mode = $null
foreach ($rel in (Get-SkillDirs $root | Sort-Object)) {
    $name = Split-Path $rel -Leaf
    if ($names.ContainsKey($name)) { Write-Host "略過重複名稱: $name ($rel)"; continue }
    $names[$name] = "../../$rel"
    $mode = New-DirLink -Link (Join-Path $dest $name) -Target (Join-Path $root $rel) -RelativeTarget "../../$rel"
    $count++
}

if (-not $gitSymlinks) {
    # 直接把 symlink 寫入 git index，確保 commit 出去的是正確的相對 symlink
    $indexed = @(Get-GitOutput ls-files -- .claude/skills)
    foreach ($p in $indexed) {
        if (-not $p) { continue }
        $n = $p.Substring('.claude/skills/'.Length)
        if (-not $names.ContainsKey($n)) { Invoke-Git update-index --force-remove -- $p }
    }
    foreach ($n in $names.Keys) {
        $p = ".claude/skills/$n"
        $tmp = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($tmp, $names[$n])   # symlink 內容 = 目標路徑（無換行）
        $sha = (Get-GitOutput hash-object -w --no-filters -- $tmp)
        Remove-Item $tmp
        Invoke-Git update-index --add --cacheinfo "120000,$sha,$p"
        Invoke-Git update-index --skip-worktree -- $p
    }
    Write-Host "（core.symlinks 未開啟：本機使用 $mode，git index 已同步為 symlink）"
}

Write-Host "已在 .claude/skills 連結 $count 個 skill"
