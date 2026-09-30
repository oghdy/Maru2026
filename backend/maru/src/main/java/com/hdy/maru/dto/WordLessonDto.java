package com.hdy.maru.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WordLessonDto {
    private int lessonNumber;
    private int totalWords;
    private int studiedWords;   // 이 레슨에서 사용자가 한 번 이상 평가한 단어 수
    private boolean isCompleted; // Lombok 게터 때문에 JSON 키는 "completed" (하위 호환으로 유지)

    // FE(word_lesson.dart)는 "isCompleted" 키를 읽으므로 같은 값을 이 키로도 내보낸다
    @JsonProperty("isCompleted")
    public boolean isCompletedForClient() {
        return isCompleted;
    }
}
