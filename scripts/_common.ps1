# zzSkill PowerShell 腳本共用函式（由其他 .ps1 以 dot-source 載入）
# 相容 Windows PowerShell 5.1 與 PowerShell 7+

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# 執行 git，失敗時中止
function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') 失敗 (exit $LASTEXITCODE)" }
}

# 執行 git 並回傳輸出（失敗時回傳 $null，不中止）
function Get-GitOutput {
    $out = & git @args 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $out
}

function Enter-RepoRoot {
    $root = Get-GitOutput rev-parse --show-toplevel
    if (-not $root) { throw '請在 zzSkill repository 內執行此腳本' }
    Set-Location $root
    return (Get-Location).Path
}

# 取得最新的正式版 tag（依版本號排序，略過含 '-' 的預發布版）
function Get-LatestTag([string]$Path) {
    $tags = @(Get-GitOutput -C $Path tag -l) | Where-Object { $_ -and $_ -notmatch '-' }
    if (-not $tags) { return $null }
    $sorted = $tags | Sort-Object { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(10, '0') }) }
    return @($sorted)[-1]
}

# 找出所有 skill 資料夾（含 SKILL.md），回傳相對路徑（以 / 分隔）
function Get-SkillDirs([string]$Root) {
    foreach ($base in 'skills', 'external') {
        $dir = Join-Path $Root $base
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Recurse -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
            ForEach-Object { $_.Directory.FullName.Substring($Root.Length + 1).Replace('\', '/') }
    }
}

# 判斷是否為 symlink / junction
function Test-ReparsePoint([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))
}

# 安全移除連結：只刪除連結本身，不會刪到目標資料夾內容
function Remove-Link([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($item.PSIsContainer) { [IO.Directory]::Delete($item.FullName) } else { [IO.File]::Delete($item.FullName) }
    } elseif (-not $item.PSIsContainer) {
        # core.symlinks=false 時，git 會把 symlink checkout 成內含目標路徑的小文字檔
        Remove-Item -LiteralPath $Path -Force
    } else {
        throw "$Path 是實體資料夾，不會刪除"
    }
}

# 建立資料夾連結：優先使用 symlink（需開發人員模式或系統管理員），失敗時改用 junction（不需權限）
# 回傳 'symlink' 或 'junction'
function New-DirLink([string]$Link, [string]$Target, [string]$RelativeTarget) {
    $t = if ($RelativeTarget) { $RelativeTarget } else { $Target }
    $null = & cmd /c mklink /D "$Link" "$($t.Replace('/', '\'))" 2>&1
    if ($LASTEXITCODE -eq 0) { return 'symlink' }
    $null = New-Item -ItemType Junction -Path $Link -Target $Target
    return 'junction'
}
