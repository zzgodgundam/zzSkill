#!/usr/bin/env bash
# 將本 repo 中的所有 skill 以 symlink 方式安裝到 Claude Code 的 skills 目錄
# 用法: scripts/install.sh [目標目錄]   (預設: ~/.claude/skills)
# 會掃描 skills/ 與 external/ 下所有含 SKILL.md 的資料夾
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
root="$(pwd)"
target="${1:-$HOME/.claude/skills}"
mkdir -p "$target"

git submodule update --init --recursive

count=0
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  link="$target/$name"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "略過 $name：$link 已存在且不是 symlink"
    continue
  fi
  ln -sfn "$root/$dir" "$link"
  echo "已連結 $name -> $dir"
  count=$((count + 1))
done < <(find skills external -name SKILL.md -not -path '*/.git/*' | sort)

echo "完成，共安裝 $count 個 skill 到 $target"
