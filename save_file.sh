#!/usr/bin/env bash
# save_work.sh — Commit & push your current work safely.
# Usage:
#   ./save_work.sh                # timestamped message
#   ./save_work.sh -m "feat: add parser"
#   ./save_work.sh --no-pull      # skip pulling/rebase (e.g., offline)
#   ./save_work.sh -n             # dry-run (shows what it would do)

set -euo pipefail

MSG=""
DO_PULL=1
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message) MSG="$2"; shift 2 ;;
    --no-pull)    DO_PULL=0; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not inside a git repository."
  exit 1
fi

# Determine current branch (handles main/master/feature)
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "HEAD" ]]; then
  echo "⚠️  Detached HEAD. Create/switch to a branch first:"
  echo "    git switch -c my-branch"
  exit 1
fi

# Ensure remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "❌ No 'origin' remote configured. Add one, e.g.:"
  echo "   git remote add origin https://github.com/<user>/<repo>.git"
  exit 1
fi

# Show status summary
echo "📦 Repo: $(basename "$(git rev-parse --show-toplevel)")"
echo "🌿 Branch: $BRANCH"
echo "🔗 Remote: $(git remote get-url origin)"

# Stage changes (respect .gitignore)
if [[ $DRY_RUN -eq 0 ]]; then
  git add -A
else
  echo "→ DRY RUN: git add -A"
fi

# Anything to commit?
if [[ -z "$(git status --porcelain)" ]]; then
  echo "✅ Nothing to commit (working tree clean)."
else
  # Default message if not provided
  if [[ -z "$MSG" ]]; then
    # UTC timestamp for portability across machines
    MSG="chore: savepoint $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    git commit -m "$MSG"
  else
    echo "→ DRY RUN: git commit -m \"$MSG\""
  fi
fi

# Sync with remote (optional)
if [[ $DO_PULL -eq 1 ]]; then
  if [[ $DRY_RUN -eq 0 ]]; then
    git fetch origin
    # Rebase with autostash avoids conflict with local unpushed changes
    git pull --rebase --autostash origin "$BRANCH" || true
  else
    echo "→ DRY RUN: git fetch origin"
    echo "→ DRY RUN: git pull --rebase --autostash origin \"$BRANCH\""
  fi
else
  echo "⏭️  Skipping pull/rebase (--no-pull)."
fi

# Push
if [[ $DRY_RUN -eq 0 ]]; then
  git push -u origin "$BRANCH"
else
  echo "→ DRY RUN: git push -u origin \"$BRANCH\""
fi

echo "✅ Done."
