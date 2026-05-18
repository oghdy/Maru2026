package com.hdy.maru.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ReviewRequestDto {
    private Long wordId;
    private int rating; // 1: AGAIN, 2: HARD, 3: GOOD, 4: EASY
    private String reviewMode; // "LESSON" or "DAILY_REVIEW"
}
