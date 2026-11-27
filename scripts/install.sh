#!/usr/bin/env bash
# 將本 repo 中的所有 skill 以 symlink 方式安裝到 Claude Code 的 skills 目錄
# 用法: scripts/install.sh [目標目錄]   (預設: ~/.claude/skills)
# 會掃描 skills/ 與 external/ 下所有含 SKILL.md 的資料夾，
# 並清除目標目錄中指向本 repo、但已不再是 skill 的無效連結（不會動到其他來源的 skill）
# 目標目錄中已存在的同名項目若不是指向本 repo（實體資料夾或其他 repo 的連結），會略過不覆蓋
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
root="$(pwd)"
target="${1:-$HOME/.claude/skills}"
mkdir -p "$target"

git submodule update --init --recursive

current=""
count=0
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  link="$target/$name"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "略過 $name：$link 已存在且不是 symlink"
    continue
  fi
  if [[ -L "$link" ]]; then
    existing="$(readlink "$link")"
    if [[ "$existing" != "$root/"* ]]; then
      echo "略過 $name：$link 已連結到其他來源（$existing）"
      continue
    fi
  fi
  ln -sfn "$root/$dir" "$link"
  current+="$root/$dir"$'\n'
  echo "已連結 $name -> $dir"
  count=$((count + 1))
done < <(find skills external -name SKILL.md -not -path '*/.git/*' | sort)

# 清除無效連結：指向本 repo 但目標已不存在或不再是 skill
removed=0
while IFS= read -r link; do
  dest="$(readlink "$link")"
  [[ "$dest" == "$root/"* ]] || continue
  if ! grep -Fxq -- "$dest" <<<"$current"; then
    rm -f "$link"
    echo "已移除無效連結 $(basename "$link") -> ${dest#$root/}"
    removed=$((removed + 1))
  fi
done < <(find "$target" -mindepth 1 -maxdepth 1 -type l)

echo "完成，共安裝 $count 個 skill 到 $target（移除 $removed 個無效連結）"
