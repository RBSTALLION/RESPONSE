#!/usr/bin/env bash
# RESPONSE: one-paste deploy to Vercel.
# Downloads the latest site/ folder from GitHub and deploys it to Vercel as a
# static site: /app (officer phone app) and /portal (control room).
#
# Needs: Node.js 18+ (https://nodejs.org) and a Vercel login.
# Optional env vars:
#   VERCEL_SCOPE   Vercel team slug to deploy under (default: your default team)
#   VERCEL_TOKEN   use a token instead of the browser login
#   PROJECT        Vercel project name (default: response)
#   TARGET         "prod" (default) or "preview"
set -euo pipefail

REPO="RBSTALLION/RESPONSE"
PROJECT="${PROJECT:-response}"
TARGET="${TARGET:-prod}"
WORK="$HOME/response-deploy"

command -v node >/dev/null 2>&1 || { echo "Node.js is not installed. Get it from https://nodejs.org (LTS), then paste this again."; exit 1; }

echo "==> Downloading the latest RESPONSE site from GitHub"
rm -rf "$WORK"; mkdir -p "$WORK"
fetch() { curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$1" | tar -xz -C "$WORK"; }
fetch main
SRC="$(find "$WORK" -maxdepth 2 -type d -name site | head -n1)"
if [ -z "$SRC" ]; then
  # site/ not merged to main yet: use the branch it was added on.
  rm -rf "$WORK"/*; fetch deploy-app-portal
  SRC="$(find "$WORK" -maxdepth 2 -type d -name site | head -n1)"
fi
[ -n "$SRC" ] || { echo "Could not find site/ in $REPO."; exit 1; }
mv "$SRC" "$WORK/$PROJECT"

cd "$WORK/$PROJECT"
VC=(npx --yes vercel@latest)
ARGS=(--yes)
[ -n "${VERCEL_SCOPE:-}" ] && ARGS+=(--scope "$VERCEL_SCOPE")
[ -n "${VERCEL_TOKEN:-}" ] && ARGS+=(--token "$VERCEL_TOKEN")

if [ -z "${VERCEL_TOKEN:-}" ] && ! "${VC[@]}" whoami >/dev/null 2>&1; then
  echo "==> Log in to Vercel (a browser window will open)"
  "${VC[@]}" login
fi

echo "==> Deploying to Vercel ($TARGET)"
[ "$TARGET" = "prod" ] && ARGS+=(--prod)
LOG="$WORK/deploy.log"
"${VC[@]}" deploy "${ARGS[@]}" 2>&1 | tee "$LOG"
# Prefer the production domain (public) over the per-deployment URL.
URL="$(grep -Eo 'Aliased:? +https://[^ ]+' "$LOG" | grep -Eo 'https://[^ ]+' | tail -n1 || true)"
[ -n "$URL" ] || URL="$(grep -Eo 'https://[a-zA-Z0-9.-]+\.vercel\.app' "$LOG" | tail -n1)"

echo
echo "Deployed: $URL"
echo "  Phone app:  $URL/app"
echo "  Web portal: $URL/portal"
echo "  Overview:   $URL/"
echo
echo "The deployed folder is $WORK/$PROJECT (you can also drag it into vercel.com/new)."
