package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserProgressRequestDto {
    private String status; // 'in_progress', 'completed'
    private Integer currentStep;
    private Integer score;
    private Integer timeSpentSeconds;
}
