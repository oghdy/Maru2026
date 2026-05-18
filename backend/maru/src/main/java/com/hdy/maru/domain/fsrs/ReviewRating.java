package com.hdy.maru.domain.fsrs;

/**
 * FSRS(망각곡선) 모델의 4가지 평가 등급
 */
public enum ReviewRating {
    AGAIN(1),
    HARD(2),
    GOOD(3),
    EASY(4);

    private final int value;

    ReviewRating(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }
}
