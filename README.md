# zzSkill

我的 AI Skill 集合，包含：

- **自己建立的 skill** — 放在 `skills/`
- **他人在 GitHub 上分享的 skill** — 以 git submodule 方式放在 `external/`，可隨時更新到最新版

## 目錄結構

```
zzSkill/
├── skills/                 # 自己的 skill（每個資料夾一個 skill，內含 SKILL.md）
│   └── my-example-skill/
│       └── SKILL.md
├── external/               # 他人的 skill（git submodule）
│   └── anthropics-skills/  # → https://github.com/anthropics/skills
├── scripts/                # 每個腳本都有 .sh（Linux/macOS）與 .ps1（Windows）版本
│   ├── add-external.sh     # 新增外部 skill submodule
│   ├── update-external.sh  # 更新所有外部 skill 到最新
│   ├── remove-external.sh  # 移除外部 skill submodule
│   └── install.sh          # 安裝（symlink）所有 skill 到 ~/.claude/skills
└── .github/workflows/
    └── update-external-skills.yml  # 每週自動更新 submodule
```

### 方式三：在所有雲端 Claude Code session 使用（claude.ai/code）

在雲端環境的 **Setup script** 加入以下內容（session 標題列的環境選單 → Edit → Setup script）。
每次建立新的雲端 container 時，會自動下載本 repo 並安裝到 `~/.claude/skills`，不論在哪個 repo 開 session 都能使用：

```bash
# 安裝 zzSkill（個人 AI skill set）到 ~/.claude/skills，讓所有 session 都能使用
Z="$HOME/zzSkill"
if [ -d "$Z/.git" ]; then git -C "$Z" pull -q --ff-only || true
else git clone -q --depth 1 https://github.com/zzgodgundam/zzSkill.git "$Z" || true; fi
if [ -d "$Z/.git" ]; then (cd "$Z" && scripts/install.sh "$HOME/.claude/skills" | tail -1) || echo "zzSkill install failed (ignored)"; fi
```

- 下載失敗不會讓 session 無法啟動（錯誤會被忽略）
- 本 repo 須維持 public；若改為 private，setup script 無法 clone

## Windows 使用說明

所有腳本都有 PowerShell 版本（`.ps1`），參數與 `.sh` 版相同，支援 Windows PowerShell 5.1 與 PowerShell 7：

| Linux / macOS | Windows |
|---|---|
| `scripts/add-external.sh <url> [名稱] [分支]` | `scripts\add-external.ps1 <url> [名稱] [分支]` |
| `scripts/add-external.sh --tag <url> [名稱]` | `scripts\add-external.ps1 -Tag <url> [名稱]` |
| `scripts/update-external.sh --commit` | `scripts\update-external.ps1 -Commit` |
| `scripts/remove-external.sh <名稱>` | `scripts\remove-external.ps1 <名稱>` |
| `scripts/install.sh [目錄]` | `scripts\install.ps1 [目錄]` |
| `scripts/sync-project-skills.sh` | `scripts\sync-project-skills.ps1` |

若出現「無法載入，因為這個系統上已停用指令碼執行」，先執行一次：

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**建議設定（讓 `.claude/skills` 的 symlink 正常運作）：**

1. 開啟 Windows「開發人員模式」（設定 → 系統 → 開發人員專用）
2. Clone 時啟用 symlink：

   ```powershell
   git clone -c core.symlinks=true --recurse-submodules https://github.com/zzgodgundam/zzSkill.git
   ```

未開啟時腳本仍可運作：本機會改用 junction（不需權限），並直接更新 git index，commit 出去的仍是跨平台正確的 symlink。

> `.gitattributes` 已設定 `.sh` 固定使用 LF 換行，避免在 Windows clone 後於 Git Bash / WSL 無法執行。

## 分支保護

`main` 受 GitHub ruleset 保護：

- 禁止刪除、禁止 force push
- 需透過 PR 合併（approvals 0）
- 僅 repository admin（擁有者）可略過以上規則直接 push

每週自動更新的 workflow 會以 PR 方式合併，不受影響。

## Clone

因為包含 submodule，clone 時請加上 `--recurse-submodules`：

```bash
git clone --recurse-submodules https://github.com/zzgodgundam/zzSkill.git
```

若已 clone 但 `external/` 是空的：

```bash
git submodule update --init --recursive
```

## 新增自己的 skill

1. 複製範例：`cp -r skills/my-example-skill skills/<新 skill 名稱>`
2. 編輯 `SKILL.md`，修改最上方 frontmatter 的 `name` 與 `description`（description 決定 AI 何時使用此 skill）
3. Commit & push

## 新增他人的 skill（submodule）

```bash
scripts/add-external.sh <git-url> [名稱] [分支]

# 例如
scripts/add-external.sh https://github.com/anthropics/skills anthropics-skills
git commit -m "Add external skill: anthropics-skills"
```

### 追蹤方式

| 方式 | 指令 | 更新時的行為 |
|------|------|------|
| 追蹤分支 | `scripts/add-external.sh <url> [名稱] [分支]` | 更新到分支最新 commit（未指定分支時自動偵測遠端預設分支） |
| 追蹤最新 release tag | `scripts/add-external.sh --tag <url> [名稱]` | 更新到最新正式版 tag（依版本號排序，略過含 `-` 的預發布版如 `v2.0.0-rc1`） |

設定記錄在 `.gitmodules`：分支追蹤使用 `branch = main`；tag 追蹤使用自訂欄位 `track = tag`。
要切換既有 submodule 為 tag 追蹤：

```bash
git config -f .gitmodules --unset submodule.external/<名稱>.branch
git config -f .gitmodules submodule.external/<名稱>.track tag
scripts/update-external.sh
```

> Git 原生的 `git submodule update --remote` 只支援分支，因此 tag 追蹤必須透過 `scripts/update-external.sh` 更新。

## 更新他人的 skill 到最新

```bash
scripts/update-external.sh            # 更新並顯示變更
scripts/update-external.sh --commit   # 更新並自動 commit
git push
```

另外 GitHub Actions（`.github/workflows/update-external-skills.yml`）會在**每週一**自動更新：推到 `auto/update-external-skills` 分支 → 開 PR → 自動合併到 `main`（相容 `main` 的分支保護）。也可以在 GitHub 的 Actions 頁面手動執行（workflow_dispatch）。

> 需在 repo 的 **Settings → Actions → General → Workflow permissions** 勾選 **Allow GitHub Actions to create and approve pull requests**，workflow 才能開 PR。

## 移除他人的 skill

```bash
scripts/remove-external.sh <名稱>
git commit -m "Remove external skill: <名稱>"
```

## 在 Claude Code 中使用

### 方式一：在本 repo 中開啟 Claude Code（本機或 claude.ai/code 雲端）

`.claude/skills/` 內有指向所有 skill 的 symlink，Claude Code 開啟本 repo 時會自動載入。
`.claude/settings.json` 的 SessionStart hook 會自動執行 `git submodule update --init`，確保外部 skill 內容存在。

> Skill 在 session 啟動時載入，新增 skill 後需開新的 session 才會生效。

新增/移除 skill 後執行 `scripts/sync-project-skills.sh` 更新 symlink（`add-external.sh`、`remove-external.sh`、`update-external.sh` 已會自動執行）。

### 方式二：安裝到全域，在任何專案都能使用

```bash
scripts/install.sh                    # 預設安裝到 ~/.claude/skills
scripts/install.sh <其他目錄>          # 例如專案內的 .claude/skills
```

會掃描 `skills/` 與 `external/` 下所有含 `SKILL.md` 的資料夾，以 symlink 連結到目標目錄。因為是 symlink，之後 `git pull` 或更新 submodule 後內容會自動同步。

目標目錄中若已有同名項目（實體資料夾，或指向其他 repo 的連結），install 會略過並顯示「略過 …」，不會覆蓋；只會新增、更新、清除指向本 repo 的連結，因此可以和其他 skill repo 安裝到同一個目錄。

## 外部 Skill 清單

| 名稱 | 來源 | 說明 |
|------|------|------|
| anthropics-skills | [anthropics/skills](https://github.com/anthropics/skills)（追蹤 `main`，此 repo 無 tag） | Anthropic 官方 skill 範例集（docx、pdf、pptx、xlsx、skill-creator 等） |
| mattpocock-skills | [mattpocock/skills](https://github.com/mattpocock/skills)（追蹤最新 release tag） | Matt Pocock 的工程與生產力 skill（tdd、diagnosing-bugs、to-spec、grill-me、handoff 等） |
