#!/bin/bash
set -Eeuo pipefail
REPO_URL="${1:-https://github.com/mingyueqianli/hax-bot-7.7.git}"
BRANCH="${BRANCH:-main}"

if [ ! -d .git ]; then
  git init
fi

git add .
git commit -m "HAX BOT 7.8 full package" || true
git branch -M "$BRANCH"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REPO_URL"
else
  git remote add origin "$REPO_URL"
fi

git push -u origin "$BRANCH"
