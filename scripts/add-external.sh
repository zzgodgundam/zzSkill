#!/usr/bin/env bash
# 新增他人的 skill repository 為 submodule
# 用法:
#   scripts/add-external.sh <git-url> [名稱] [分支]   # 追蹤分支（預設為遠端預設分支）
#   scripts/add-external.sh --tag <git-url> [名稱]     # 追蹤最新的正式版 tag
set -euo pipefail

mode=branch
if [[ "${1:-}" == "--tag" ]]; then mode=tag; shift; fi

url="${1:?用法: $0 [--tag] <git-url> [名稱] [分支]}"
name="${2:-$(basename "${url%.git}")}"
path="external/$name"
cd "$(git rev-parse --show-toplevel)"

if [[ "$mode" == "tag" ]]; then
  git submodule add "$url" "$path"
  git config -f .gitmodules "submodule.$path.track" tag
  tag="$(git -C "$path" tag -l | grep -Ev -- '-' | sort -V | tail -1)"
  [[ -n "$tag" ]] || { echo "錯誤: $url 沒有正式版 tag，請改用分支追蹤"; exit 1; }
  git -C "$path" -c advice.detachedHead=false checkout --quiet "$tag"
  git add .gitmodules "$path"
  desc="tag $tag"
else
  if [[ -n "${3:-}" ]]; then
    branch="$3"
  else
    branch="$(git ls-remote --symref "$url" HEAD | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')"
  fi
  git submodule add -b "$branch" "$url" "$path"
  desc="分支 $branch"
fi

scripts/sync-project-skills.sh
echo "已新增 $path (追蹤: $desc)"
echo "請記得 commit: git add -A && git commit -m \"Add external skill: $name\""
