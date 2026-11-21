#!/usr/bin/env bash
# 移除外部 skill submodule
# 用法: scripts/remove-external.sh <名稱>
set -euo pipefail
name="${1:?用法: $0 <名稱>}"
cd "$(git rev-parse --show-toplevel)"
path="external/$name"

git submodule deinit -f "$path"
git rm -f "$path"
rm -rf ".git/modules/$path"
echo "已移除 $path，請記得 commit。"
