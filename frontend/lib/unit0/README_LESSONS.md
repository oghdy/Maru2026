# Unit 0 레슨 시스템 사용 가이드

## 📚 레슨 화면 사용 방법

### 기본 사용법

```dart
import 'package:maru/unit0/screens/lesson_screen.dart';

// 레슨 화면으로 이동
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LessonScreen(
      jsonPath: 'assets/unit0/data/lessons/unit0_lesson1.json',
    ),
  ),
);
```

### 사용 가능한 레슨들

1. **자음 배우기**
   ```dart
   LessonScreen(jsonPath: 'assets/unit0/data/lessons/unit0_lesson1.json')
   ```

2. **모음 배우기**
   ```dart
   LessonScreen(jsonPath: 'assets/unit0/data/lessons/unit0_lesson2.json')
   ```

3. **받침 배우기**
   ```dart
   LessonScreen(jsonPath: 'assets/unit0/data/lessons/unit0_lesson3.json')
   ```

4. **한글 조합 퀴즈**
   ```dart
   LessonScreen(jsonPath: 'assets/unit0/data/lessons/unit0_lesson4.json')
   ```

## 🎯 레슨 구조

각 레슨은 다음 Step 타입으로 구성됩니다:

1. **introduction** - 개념 소개
2. **practice** - 연습 (자음/모음 읽기)
3. **quiz** - 퀴즈 (문제 풀기)
4. **completion** - 완료 화면

## 🚀 새 레슨 추가하기

1. JSON 파일 생성: `assets/unit0/data/lessons/unit0_lesson5.json`
2. 레슨 화면에서 사용:
   ```dart
   LessonScreen(jsonPath: 'assets/unit0/data/lessons/unit0_lesson5.json')
   ```

끝! 코드 수정 없이 새 레슨 추가 완료!

## 📝 JSON 구조 예시

```json
{
  "lesson_id": "unit0_lesson1",
  "unit_id": 0,
  "order": 1,
  "title": "레슨 제목",
  "description": "레슨 설명",
  "steps": [
    {
      "step_type": "introduction",
      "content": {
        "title": "소제목",
        "description": "설명"
      }
    }
  ]
}
```

## 🔧 Step 타입별 Content 구조

### Introduction Step
```json
{
  "step_type": "introduction",
  "content": {
    "title": "제목",
    "description": "설명",
    "image": "assets/images/example.png",  // 선택사항
    "additional_info": "추가 정보"  // 선택사항
  }
}
```

### Practice Step
```json
{
  "step_type": "practice",
  "content": {
    "instruction": "지시사항",
    "subtitle": "부제목",  // 선택사항
    "items": ["ㄱ", "ㄴ", "ㄷ"]
  }
}
```

### Quiz Step
```json
{
  "step_type": "quiz",
  "content": {
    "questions": [
      {
        "question_type": "multiple_choice",
        "content": {
          "question": "문제",
          "choices": ["선택지1", "선택지2", "선택지3", "선택지4"]
        },
        "answer": {
          "correct": "정답",
          "explanation": "설명"
        }
      }
    ]
  }
}
```

### Completion Step
```json
{
  "step_type": "completion",
  "content": {
    "title": "완료 제목",
    "message": "완료 메시지",
    "achievement": "성취 내용"  // 선택사항
  }
}
```

## 💡 팁

- 모든 레슨은 동일한 `LessonScreen` 위젯을 사용합니다
- Step 타입만 추가하면 새로운 위젯을 만들 수 있습니다
- JSON만 수정하면 레슨 내용을 쉽게 변경할 수 있습니다

