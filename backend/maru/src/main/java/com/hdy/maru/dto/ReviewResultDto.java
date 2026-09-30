package com.hdy.maru.dto;

import java.time.LocalDateTime;

/**
 * 단어 평가 제출 결과.
 * applied=false 면 Spacing Integrity Guard 로 스케줄이 바뀌지 않은 것 (Word Study 에서 아직 복습일이 안 된 단어).
 */
public record ReviewResultDto(boolean applied, int state, LocalDateTime nextReviewDate) {
}
