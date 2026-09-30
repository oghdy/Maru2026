#!/usr/bin/env bash
# 개발용 JWT 발급: 지정 DB에 dev_tester 유저를 만들고(없으면), 루트 .env 의 JWT_SECRET 으로 서명한 토큰을 출력.
# 사용: TOKEN=$(scripts/dev_token.sh maru_lesson)            # FE: dev_tester
#       TOKEN=$(scripts/dev_token.sh maru_lesson dev_tester_be)  # BE 는 curl 테스트용 별도 유저 (FE 데이터 오염 방지)
#       flutter run --dart-define=API_PORT=8081 --dart-define=DEV_JWT=$TOKEN
set -euo pipefail
DB="${1:?usage: dev_token.sh <db_name> [user_id]}"
export DEV_USER="${2:-dev_tester}"
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
# worktree 에서 실행해도 main 체크아웃의 .env 를 읽는다 (.env 는 심볼릭 링크)
set -a; source "$ROOT/.env"; set +a

psql -d "$DB" -q -v ON_ERROR_STOP=1 -v u="$DEV_USER" <<'SQL' >/dev/null
INSERT INTO users (oauth_id, oauth_provider, nickname, username, is_active, created_at)
SELECT :'u', 'dev', 'Tester', :'u', true, now()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE oauth_id = :'u');
SQL

python3 - <<'PY'
import base64, hashlib, hmac, json, os, time
def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()
key = base64.b64decode(os.environ["JWT_SECRET"])
now = int(time.time())
header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
payload = b64(json.dumps({"sub": os.environ["DEV_USER"], "role": "ROLE_USER", "iat": now, "exp": now + 30 * 86400}).encode())
sig = b64(hmac.new(key, f"{header}.{payload}".encode(), hashlib.sha256).digest())
print(f"{header}.{payload}.{sig}")
PY
