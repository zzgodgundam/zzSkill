#!/usr/bin/env bash
# 新增他人的 skill repository 為 submodule
# 用法: scripts/add-external.sh <git-url> [名稱] [分支]
# 例如: scripts/add-external.sh https://github.com/anthropics/skills anthropics-skills main
set -euo pipefail

url="${1:?用法: $0 <git-url> [名稱] [分支]}"
name="${2:-$(basename "${url%.git}")}"
cd "$(git rev-parse --show-toplevel)"

if [[ -n "${3:-}" ]]; then
  branch="$3"
else
  # 自動偵測遠端預設分支
  branch="$(git ls-remote --symref "$url" HEAD | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')"
fi

git submodule add -b "$branch" "$url" "external/$name"
scripts/sync-project-skills.sh
echo "已新增 external/$name (追蹤分支: $branch)"
echo "請記得 commit: git commit -m \"Add external skill: $name\""
