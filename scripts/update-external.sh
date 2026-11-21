#!/usr/bin/env bash
# 將所有外部 skill submodule 更新到各自追蹤分支的最新版本
# 用法: scripts/update-external.sh [--commit]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git submodule sync --recursive
git submodule update --init --remote --recursive

if git diff --quiet -- external; then
  echo "所有外部 skill 都已是最新版本。"
  exit 0
fi

echo "以下 submodule 有更新:"
git submodule summary -- external

if [[ "${1:-}" == "--commit" ]]; then
  git add external
  git commit -m "Update external skills to latest"
  echo "已 commit，請執行 git push。"
else
  echo "確認無誤後執行: git add external && git commit -m \"Update external skills\""
fi
