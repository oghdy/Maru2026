package com.hdy.maru.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class UserStatsResponseDto {
    private Integer totalLessonsCompleted;
    private Integer totalStudyMinutes;
    private Integer currentStreakDays;
    private Integer longestStreakDays;
    private Integer totalStarsEarned;
    private LocalDate lastStudyDate;
}
