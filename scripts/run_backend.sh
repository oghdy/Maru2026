#!/usr/bin/env bash
# 기능별 로컬 백엔드 실행. 포트·DB 가 기능마다 분리되어 병렬 작업이 서로 간섭하지 않는다.
# 사용: scripts/run_backend.sh lesson   (worktree 루트에서)
set -euo pipefail
FEATURE="${1:?usage: run_backend.sh <lesson|vocab|mission|lab|main>}"
case "$FEATURE" in
  lesson)  PORT=8081; DB=maru_lesson ;;
  vocab)   PORT=8082; DB=maru_vocab ;;
  mission) PORT=8083; DB=maru_mission ;;
  lab)     PORT=8084; DB=maru_lab ;;
  main)    PORT=8080; DB=maru ;;
  *) echo "unknown feature: $FEATURE" >&2; exit 1 ;;
esac
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
set -a; source "$ROOT/.env"; set +a
cd "$ROOT/backend/maru"
exec ./gradlew bootRun --args="--server.port=$PORT --spring.datasource.url=jdbc:postgresql://localhost:5432/$DB"
