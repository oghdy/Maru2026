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
}
