package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LessonResponseDto {
    private String lessonId;
    private Integer unitId;
    private String unitTitle;
    private Integer orderNum;
    private String title;
    private String description;
    private Integer difficultyLevel;
    private Integer estimatedMinutes;
    private LessonContentDto content; // Direct mapping to our JSONB structure!
    private Boolean isPublished;
}
