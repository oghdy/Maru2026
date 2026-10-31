#!/usr/bin/env bash
# 웹 체험판 Flutter 앱을 /app/ 경로용으로 빌드해 deploy/web-demo/site/app/ 로 복사한다.
# 사용: scripts/build_web_demo.sh <API_BASE_URL>   예) scripts/build_web_demo.sh https://체험판서버주소
# 비밀값을 받지 않는다. API_BASE_URL 은 앱에 그대로 들어가 공개되는 값이다.
set -euo pipefail

usage() {
  echo "usage: scripts/build_web_demo.sh <API_BASE_URL>" >&2
  echo "  example: scripts/build_web_demo.sh http://localhost:8085" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
API_BASE_URL="${1%/}"
case "$API_BASE_URL" in
  http://*|https://*) ;;
  *) usage ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/frontend/maru/build/web"
DEST="$ROOT/deploy/web-demo/site/app"

cd "$ROOT/frontend/maru"
flutter build web --release \
  --dart-define=DEMO_MODE=true \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --pwa-strategy=none \
  --base-href /app/

# canvaskit/ 는 복사하지 않는다. 이 빌드는 gstatic CDN 에서 엔진을 받으므로 쓰이지 않는 약 20MB 다.
rm -rf "$DEST"
mkdir -p "$DEST"
rsync -a --exclude 'canvaskit/' --exclude '.last_build_id' "$SRC/" "$DEST/"

echo "copied to $DEST ($(du -sh "$DEST" | cut -f1))"
