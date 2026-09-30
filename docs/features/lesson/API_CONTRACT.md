# LSN — Korean Lesson — API CONTRACT (BE ↔ FE 약속)

> **BE 가 먼저 갱신**하고 FE 에 알린다 (LOG + STATUS 메모). 기존 필드 삭제·이름변경 대신 **필드 추가** 우선.
> 공통 응답: `ApiResponse<T>` = `{ "success": bool, "data": T, "message": string }` · 인증: `Authorization: Bearer <JWT>`
> 로컬: `http://localhost:8081`

## 1. 현재 엔드포인트 (Step 1.1 에서 BE 가 실제 응답 보고 작성)
<!-- 엔드포인트마다: 메서드 경로 / 요청 예시 / 응답 예시(data 부분) / 오류 시 상태코드 -->

## 2. 데이터 구조 (DB JSON·엔티티 중 FE 가 의존하는 것)

## 3. 변경 이력
| 시각 | 변경 | 태스크 | 호환성 (FE 수정 필요?) |
|---|---|---|---|
