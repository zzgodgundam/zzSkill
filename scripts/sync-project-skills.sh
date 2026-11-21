#!/usr/bin/env bash
# 在 .claude/skills/ 建立指向所有 skill 的相對 symlink，
# 讓在此 repo 中開啟的 Claude Code（本機或雲端）自動載入整個 skill set。
# 新增/移除 skill 或更新 submodule 後請重新執行。
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
dest=".claude/skills"
mkdir -p "$dest"
# 清除舊的 symlink（只刪 symlink，不動實體資料夾）
find "$dest" -maxdepth 1 -type l -delete

count=0
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  if [[ -e "$dest/$name" ]]; then
    echo "略過重複名稱: $name ($dir)"
    continue
  fi
  ln -s "../../$dir" "$dest/$name"
  count=$((count + 1))
done < <(find skills external -name SKILL.md -not -path '*/.git/*' | sort)
echo "已在 $dest 連結 $count 個 skill"
