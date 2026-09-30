package com.hdy.maru.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserProgressResponseDto {
    private String lessonId;
    private String status;
    private Integer currentStep;
    private Integer score;
    private Integer starsEarned;
    private Integer attempts;
    private Integer timeSpentSeconds; // 이 레슨 누적 학습 시간(초)
}
