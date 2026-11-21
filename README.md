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
├── scripts/
│   ├── add-external.sh     # 新增外部 skill submodule
│   ├── update-external.sh  # 更新所有外部 skill 到最新
│   ├── remove-external.sh  # 移除外部 skill submodule
│   └── install.sh          # 安裝（symlink）所有 skill 到 ~/.claude/skills
└── .github/workflows/
    └── update-external-skills.yml  # 每週自動更新 submodule
```

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

未指定分支時會自動偵測遠端預設分支，並寫入 `.gitmodules` 的 `branch` 欄位，讓之後的更新會追蹤該分支。

## 更新他人的 skill 到最新

```bash
scripts/update-external.sh            # 更新並顯示變更
scripts/update-external.sh --commit   # 更新並自動 commit
git push
```

等同於 `git submodule update --init --remote --recursive`。

另外 GitHub Actions（`.github/workflows/update-external-skills.yml`）會在**每週一**自動更新並 commit，也可以在 GitHub 的 Actions 頁面手動執行（workflow_dispatch）。

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

## 外部 Skill 清單

| 名稱 | 來源 | 說明 |
|------|------|------|
| anthropics-skills | [anthropics/skills](https://github.com/anthropics/skills) | Anthropic 官方 skill 範例集（docx、pdf、pptx、xlsx、skill-creator 等） |
