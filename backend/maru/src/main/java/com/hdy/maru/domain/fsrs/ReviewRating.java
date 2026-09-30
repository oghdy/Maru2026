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

    /** 1~4 를 등급으로 변환. 범위 밖이면 IllegalArgumentException (→ 400) */
    public static ReviewRating fromValue(int value) {
        for (ReviewRating r : values()) {
            if (r.value == value) return r;
        }
        throw new IllegalArgumentException("rating must be 1 (Again) to 4 (Easy).");
    }
}
