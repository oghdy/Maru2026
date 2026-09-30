# REQUESTS — 세션 → PM 요청함

> 잠금 파일 수정이 필요할 때, 다른 기능에 영향이 있을 때, 막혔을 때 **아래에 추가**한다 (위 항목 수정 금지).
> PM 이 `상태`와 `답변`을 채운다. 요청한 세션은 작업 재개 전 여기서 답변을 확인.

```markdown
### R-000 · <요청 세션> · <YYYY-MM-DD HH:MM>
- 종류: 잠금파일 수정 | 교차영향 | 막힘 | 결정필요
- 내용: 무엇이, 왜 필요한지 (파일:라인)
- 제안: 원하는 변경
- 상태: 대기 | 처리중 | 완료 | 반려
- 답변(PM):
```

---

### R-001 · lesson-be · 2026-09-30 16:45
- 종류: 교차영향
- 내용: `feat/lesson` 브랜치(= main 기준)에서 `./gradlew test --tests <아무거나>` 가 **테스트 컴파일 단계에서 실패**함. 원인 파일(타 기능 소유): `MissionChatDtoTest.java:20`·`MissionChatControllerTest.java:37` (`MissionSetupRequestDto.formality()` 없음), `VocabularyServiceTest.java` (컴파일 오류 10건). 이 때문에 모든 세션이 자기 테스트를 못 돌림.
- 우회(lesson-be): 저장소 밖 gradle init 스크립트로 세 파일을 test sourceSet 에서 제외하고 실행 (`./gradlew -I <scratch>/exclude-broken-tests.gradle test --tests ...`). 저장소 파일은 건드리지 않음.
- 제안: mission-be / vocab-be 가 각자 테스트를 현재 DTO/서비스에 맞게 고치도록 공지. 참고로 `GET /api/units/abc/lessons` 같은 타입 불일치가 GlobalExceptionHandler 에서 500 으로 처리됨(400 이 맞음) — lesson 은 컨트롤러 로컬에서 처리 예정, 공통 처리는 PM 판단.
- 상태: 처리중
- 답변(PM): 09-30 18:50 · 테스트 컴파일 오류는 VOC-1.1.3 / MSN-1.1.3 (각 세션 첫 태스크, P0)으로 배정. 두 태스크가 끝나 main 에 머지되기 전까지는 lesson-be 의 exclude init 스크립트 우회 방식을 계속 사용. 타입 불일치 400 공통 처리(GlobalExceptionHandler)는 PM-1.P.8 로 PM 이 처리.
