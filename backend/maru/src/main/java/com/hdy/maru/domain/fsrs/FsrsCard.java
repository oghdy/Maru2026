package com.hdy.maru.domain.fsrs;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class FsrsCard {
    private FsrsState state;
    private double stability;
    private double difficulty;
    private int reps;
    private int lapses;
    private LocalDateTime lastReviewDate;
    private LocalDateTime nextReviewDate;

    // 테스트용 추가 보조 생성자
    public FsrsCard(FsrsState state, double stability, double difficulty, int reps, int lapses, LocalDateTime lastReviewDate) {
        this(state, stability, difficulty, reps, lapses, lastReviewDate, lastReviewDate);
    }

    public static FsrsCard createNewCard() {
        return new FsrsCard(FsrsState.NEW, 0.0, 0.0, 0, 0, null, null);
    }
}
