#!/usr/bin/env bash
# 將所有外部 skill submodule 更新到最新版本
# - .gitmodules 中設定 track = tag 的 submodule：更新到最新的正式版 tag（略過 -rc/-beta 等預發布版）
# - 其他 submodule：更新到追蹤分支（branch）的最新 commit
# 用法: scripts/update-external.sh [--commit]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git submodule sync --recursive
git submodule update --init --recursive

latest_tag() {
  # 依版本號排序，排除含 '-' 的預發布 tag
  git -C "$1" tag -l | grep -Ev -- '-' | sort -V | tail -1
}

while read -r key path; do
  name="${key#submodule.}"; name="${name%.path}"
  track="$(git config -f .gitmodules --get "submodule.$name.track" || true)"
  if [[ "$track" == "tag" ]]; then
    git -C "$path" fetch --tags --force --quiet origin
    tag="$(latest_tag "$path")"
    if [[ -z "$tag" ]]; then
      echo "警告: $path 沒有可用的 tag，維持不變"
      continue
    fi
    git -C "$path" -c advice.detachedHead=false checkout --quiet "$tag"
    echo "$path -> tag $tag"
  else
    git submodule update --remote --recursive -- "$path"
    branch="$(git config -f .gitmodules --get "submodule.$name.branch" || echo HEAD)"
    echo "$path -> branch $branch ($(git -C "$path" rev-parse --short HEAD))"
  fi
done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$')

scripts/sync-project-skills.sh

if git diff --quiet -- external; then
  echo "所有外部 skill 都已是最新版本。"
  exit 0
fi

echo "以下 submodule 有更新:"
git submodule summary -- external

if [[ "${1:-}" == "--commit" ]]; then
  git add external .claude/skills
  git commit -m "Update external skills to latest"
  echo "已 commit，請執行 git push。"
else
  echo "確認無誤後執行: git add external .claude/skills && git commit -m \"Update external skills\""
fi
