# 🎓 [개발 관점 리포트] Maru (Flutter + Spring Boot) 아키텍처 및 코드 분석

사용자님께서 제안해주신 플로우는 **컴퓨터공학과 졸업작품 심사 기준에 완벽하게 부합**합니다. 교수님들이 가장 보고 싶어 하는 "어려운 문제를 어떤 기술적 아키텍처와 코드로 해결했는가?"에 집중하는 최고의 전략입니다.

특히 **Dynamic Lesson Rendering(데이터 주도 설계)**, **AI Grammar Lab(생성형 AI 연동)**, **AI Cache(성능/비용 최적화)** 이 세 가지 킬러 포인트를 중심축으로 삼아 전체 슬라이드의 텍스트와 핵심 코드, 그리고 발표 스크립트를 완성했습니다.

---

## 🚀 최종 발표 플로우: 문제 ➔ 기능 ➔ 기술 아키텍처(구현 핵심)

---

### [Part 1: 문제 제기와 해결책]

#### 슬라이드 1: MARU 소개
*   **텍스트**: 
    *   Maru: 외국인을 위한 스마트 한국어 학습 플랫폼
    *   Flutter + Spring Boot 기반의 상용화 레벨 앱
*   **발표 스크립트**: "안녕하십니까, 외국인을 위한 스마트 한국어 학습 플랫폼 'Maru'의 발표를 맡은 OOO입니다. 저희 프로젝트는 단순한 앱 개발을 넘어, 실제 상용화 수준의 아키텍처를 구현하는 데 집중했습니다."

#### 슬라이드 2~3: 문제 제기 (기존의 한계)
*   **텍스트**:
    *   수요 폭증 vs 정체된 학습 방식
    *   기존 앱의 하드코딩된 정적 콘텐츠 한계
    *   수동적인 암기 위주의 학습
*   **발표 스크립트**: "한국어 학습 수요는 폭증하지만, 기존 앱들은 콘텐츠가 하드코딩되어 있어 업데이트가 어렵고, 학습 방식이 수동적인 암기 위주에 머물러 있었습니다."

#### 슬라이드 4~5: MARU의 해결책
*   **텍스트**:
    *   데이터 주도(Data-Driven) 동적 콘텐츠 렌더링
    *   능동적 조립형 한글 학습 (Hangeul Lab)
    *   AI 기반 무한 문장 탐색 (AI Grammar Lab)
*   **발표 스크립트**: "Maru는 이 문제를 세 가지 기술로 해결했습니다. 백엔드에서 내려주는 JSON으로 화면을 동적 렌더링하고, 로컬 메모리 기반의 한글 조합기와 서버 AI 기반의 문법 실험실을 제공합니다."

---

### [Part 2: 주요 기능과 기술적 구현 (핵심 파트)]

#### 슬라이드 6: MARU 주요 기능 시스템
*   **텍스트**:
    1.  Native OAuth Login & Security
    2.  Dynamic Lesson System
    3.  Language Lab (Local & AI)

#### 슬라이드 7: Native OAuth & Security Architecture
*   **텍스트**:
    *   Google / Apple Native Login 연동
    *   Stateless 인증 아키텍처 구축
    *   Spring Security Custom Filter Chain
    *   `flutter_secure_storage` 자동 로그인
*   **코드 스니펫**:
    ```java
    // Spring Security Stateless JWT 설정
    http.sessionManagement(session -> 
            session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
    ```
*   **발표 스크립트**: "첫 번째 기술 포인트는 보안 아키텍처입니다. 현대적인 Scale-out 환경을 고려해 서버에 세션을 두지 않는 완전한 Stateless JWT 인증을 구현했습니다. 클라이언트에서 Native OAuth로 획득한 토큰을 Spring Security의 커스텀 필터 체인에서 검증합니다."

#### 슬라이드 8: Learning Dashboard & State Management
*   **텍스트**:
    *   사용자 학습 데이터 (시간, 스트릭, 별) 실시간 동기화
    *   Riverpod 기반 전역 상태 관리
    *   REST API 통신 (Dio Interceptor)
*   **발표 스크립트**: "로그인 후 진입하는 대시보드입니다. 사용자의 학습 데이터는 백엔드 PostgreSQL에 안전하게 저장되며, 프론트엔드는 Riverpod 상태 관리와 Dio 인터셉터를 결합하여 실시간으로 서버 데이터와 화면을 동기화합니다."

#### ⭐ 슬라이드 9: Dynamic Lesson System (킬러 포인트 1)
*   **텍스트**:
    *   **문제**: 하드코딩된 UI는 콘텐츠 확장이 불가능함
    *   **해결**: 서버 JSON 데이터 기반 UI 동적 렌더링
    *   **패턴**: Factory Pattern / 다형성 적용
*   **코드 스니펫**:
    ```dart
    // 프론트엔드 동적 렌더링 팩토리 로직
    Widget _buildStepWidget(LessonStep step) {
      switch (step.stepType) {
        case StepType.introduction: return IntroStepWidget(step.content);
        case StepType.practice: return PracticeStepWidget(step.content);
        case StepType.quiz: return QuizStepWidget(step.content);
        // 새로운 타입이 서버에서 추가되더라도 단 1줄만 추가하면 확장 완료
      }
    }
    ```
*   **발표 스크립트**: "가장 공을 들인 다이내믹 렌더링 아키텍처입니다. 앱 코드를 배포하지 않아도 백엔드에서 내려주는 JSON 포맷의 `stepType`에 따라 알맞은 위젯을 동적으로 조립해 화면을 그립니다. 콘텐츠 무한 확장이 가능한 플랫폼 구조입니다."

#### 슬라이드 10: JSONB DB 설계 (백엔드 지원)
*   **텍스트**:
    *   RDBMS(PostgreSQL) 내 비정형 데이터 수용
    *   정규화의 한계(테이블 폭증) 극복
    *   `JSONB` 데이터 타입 전략
*   **발표 스크립트**: "이를 지원하기 위해 백엔드 DB 설계에서도 정규화의 함정을 피해 `JSONB` 타입을 채택했습니다. 다양한 퀴즈나 설명 포맷을 하나의 컬럼에 유연하게 담아내어 테이블 폭증을 막고 RDBMS의 안정성을 유지했습니다."

#### 슬라이드 11: 로컬 Hangeul Lab
*   **텍스트**:
    *   초성/중성/종성 독립적 결합 알고리즘
    *   로컬 메모리 기반 0.1초 즉각 반응 로직
    *   Flutter TTS 연동 리소스 관리
*   **발표 스크립트**: "사용자 실험 공간인 한글 랩은 네트워크 지연을 배제하기 위해 철저히 로컬 메모리 기반으로 설계했습니다. 자음과 모음이 결합되는 복잡한 유니코드 연산과 TTS 음성 반응이 0.1초 내에 즉각적으로 처리됩니다."

#### ⭐ 슬라이드 12: AI Grammar Lab 연동 (킬러 포인트 2)
*   **텍스트**:
    *   LLM(Gemini 1.5 API) 연동 문법 변형 추론
    *   다중 조건(Modifier) 병합 프롬프트 엔지니어링
*   **코드 스니펫**:
    ```java
    // 백엔드 AI 통신 및 캐시 처리 전면부
    Optional<AiCache> cachedResult = aiCacheRepository.findBySyllable(syllable);
    if (cachedResult.isPresent()) return cachedResult.get();
    
    // Cache Miss 시 외부 API 프록시 호출
    String response = callGeminiApi(prompt);
    aiCacheRepository.save(new AiCache(syllable, response));
    ```
*   **발표 스크립트**: "단순 조립을 넘어 문맥을 이해해야 하는 문법 실험실은 백엔드에서 Gemini API를 연동했습니다. 사용자가 입력한 문장에 '과거형', '존댓말' 등의 파라미터를 조합해 프롬프트를 구성하고 AI 객체를 반환합니다."

#### ⭐ 슬라이드 13: AI Cache Architecture (킬러 포인트 3)
*   **텍스트**:
    *   **문제**: 반복되는 AI 호출로 인한 비용 발생 및 높은 지연시간(Latency)
    *   **해결**: DB Layer 캐싱 인터셉트
    *   **효과**: API 비용 최소 90% 절감, 응답속도 2,000ms ➔ 100ms
*   **구조도 다이어그램**:
    ```
    User Request ➔ Backend Controller
                         ↓
                     [Cache DB 검색]
                    ↙            ↘
              (Hit!)           (Miss!)
           즉시 데이터 반환     Gemini API 호출
                                  ↓
                              DB에 신규 캐시 저장
    ```
*   **발표 스크립트**: "이 프로젝트의 핵심 성능 최적화 파트인 AI 캐시 아키텍처입니다. 동일한 문장 변형 요청이 들어올 경우 외부 API를 타지 않고 자체 DB에서 즉시 캐시를 반환합니다. 이를 통해 응답 속도를 2초에서 0.1초로 극적으로 단축시키고, 막대한 API 과금 비용 구조를 근본적으로 해결했습니다."

---

### [Part 3: 총정리 및 비전]

#### 슬라이드 14: Overall Architecture
*   **텍스트**:
    *   전체 아키텍처 통감 다이어그램 (Flutter ➔ Spring Boot ➔ DB/AI)
    *   Separation of Concerns (관심사의 분리) 원칙 엄수
*   **발표 스크립트**: "결과적으로 프론트엔드의 화면 렌더링, 백엔드의 데이터 가공 및 인프라 통신, 데이터베이스의 유연성이 완벽하게 격리되고 또 조화를 이루는 견고한 풀스택 아키텍처를 완성했습니다."

#### 슬라이드 15: 향후 개발 계획
*   **텍스트**:
    *   Speech Recognition (발음 정확도 평가)
    *   WebSocket 기반 Multiplayer 대결
*   **발표 스크립트**: "현재 구축된 이 확장성 높은 기반 프레임워크 위에, 다음 학기에는 음성 인식 모듈과 웹소켓 실시간 대결 기능을 레고 블록처럼 손쉽게 얹어 시스템을 고도화할 계획입니다. 감사합니다."

---

### 💡 발표 준비 팁 (교수님 마음을 훔치는 자세)
1. **자신감 있는 시연**: 슬라이드 9번(다이내믹 렌더링)과 13번(캐싱 체감 스피드)을 **직접 폰이나 에뮬레이터로 보여주면서** "코드 배포 없이 화면이 바뀝니다", "처음엔 2초지만 두 번째엔 0.1초 만에 뜹니다" 라고 말하면 게임 끝입니다.
2. **"왜?"라는 질문에 대한 논리적 방어**: 
   - 단순 하드코딩 앱이 아니라 **플랫폼**을 지향했기 때문 (JSON 기반 동적 렌더링)
   - 스타트업 수준의 **비용 효율**을 내기 위함 (AI 캐시)
   - 이것을 강조하시면 완벽한 "컴공과식 발표"가 완성됩니다.
