# frontend/maru — FE 세션 규칙 (루트 CLAUDE.md 가 우선)

Flutter (`~/flutter/bin/flutter`), Riverpod 3, Dio, flutter_tts. 기능 코드는 `lib/features/<feature>/{models,providers,repositories,screens,widgets}`.

## 실행 (기능별 시뮬레이터 고정 — 루트 CLAUDE.md §3 표)
```
cd frontend/maru && flutter pub get            # worktree 최초 1회
TOKEN=$(../../scripts/dev_token.sh maru_<feature>)
flutter run -d <내 시뮬레이터 UDID> --dart-define=API_PORT=<내 포트> --dart-define=DEV_JWT=$TOKEN
```
- `flutter run` 은 Bash `run_in_background` 로 띄우고, 화면 확인은 iOS Simulator 도구(screenshot/tap)로 직접 한다. 다른 기능의 시뮬레이터를 쓰지 말 것.
- 서버는 짝 BE 세션이 띄운 것을 쓴다. 안 떠 있으면 `scripts/run_backend.sh <feature>` 로 직접 띄워도 된다(포트 중복 확인).
- DEV_JWT 는 debug 빌드에서만 동작하며 `dev_tester`(닉네임 Tester) 계정으로 로그인된다.

## 규칙
- `flutter analyze lib/features/<내 폴더>` 로 확인. `pubspec.yaml` 수정·패키지 추가 금지.
- 🔒 `lib/core/**`, `lib/screens/**`, `lib/main.dart` 는 수정 금지. 필요한 공용 위젯/유틸은 자기 feature 폴더 안에 만든다.
- 하드코딩된 가짜 값(고정 점수, "Question n/5", "30 words" 등)은 실제 데이터 기반으로 바꾼다.
- 오류 UI: 예외 원문 대신 영어 안내문 + Retry 버튼. 로딩 상태를 빈칸(SizedBox.shrink)으로 숨기지 말 것.
- 작은 화면에서 넘치지 않게(스크롤 가능하게). 색상은 `Theme.of(context).colorScheme` 사용.
- `withOpacity` 경고는 새로 추가하지 말고(`withValues(alpha: ...)` 사용), 기존 것은 건드린 파일만 정리.
