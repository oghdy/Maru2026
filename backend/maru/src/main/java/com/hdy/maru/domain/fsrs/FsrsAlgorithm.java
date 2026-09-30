package com.hdy.maru.domain.fsrs;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.Map;

/**
 * FSRS-4.5 스케줄러 (Strategy 용도)
 * 수학적 연산과 비즈니스 룰만을 포함하며, DB나 JPA에 의존하지 않는 순수 자바 객체입니다.
 *
 * 공식·기본 파라미터 출처: open-spaced-repetition FSRS-4.5 (py-fsrs 3.x / FSRS4Anki 4.5 기본값).
 *  - 기억률(retrievability)      R(t,S) = (1 + FACTOR·t/S)^DECAY,  DECAY = -0.5, FACTOR = 19/81
 *  - 다음 간격                   I(S)   = S/FACTOR · (r^(1/DECAY) − 1)   (목표 기억률 r = 0.9 → I = S)
 *  - 초기 안정성                 S0(G)  = w[G−1]
 *  - 초기 난이도                 D0(G)  = w4 − (G−3)·w5
 *  - 난이도 갱신                 D'     = w7·D0(3) + (1−w7)·(D − w6·(G−3))        (평균 회귀, 1~10)
 *  - 기억 성공 시 안정성         S'r    = S·(1 + e^w8·(11−D)·S^−w9·(e^(w10·(1−R)) − 1)·hardPenalty·easyBonus)
 *  - 망각(AGAIN) 시 안정성       S'f    = w11·D^−w12·((S+1)^w13 − 1)·e^(w14·(1−R))
 *  G = 평가(1 AGAIN · 2 HARD · 3 GOOD · 4 EASY), t = 마지막 복습 후 경과 일수.
 *
 * 앱 규칙 (표준 FSRS 위에 얹은 것):
 *  - 분 단위 학습 단계는 두지 않고, AGAIN 만 5분 뒤 재시도(오늘의 복습에 다시 등장). 그 외 평가는 일 단위 간격.
 *  - HARD ≤ GOOD < EASY 간격 순서를 보장 (py-fsrs 와 동일한 보정).
 */
@Component
public class FsrsAlgorithm {

    /** FSRS-4.5 기본 파라미터 w0 ~ w16 */
    static final double[] W = {
            0.4872, 1.4003, 3.7145, 13.8206, 5.1618, 1.2298, 0.8975, 0.031,
            1.6474, 0.1367, 1.0461, 2.1072, 0.0793, 0.3246, 1.587, 0.2272, 2.8755
    };

    static final double DECAY = -0.5;
    static final double FACTOR = Math.pow(0.9, 1 / DECAY) - 1; // = 19/81
    static final double REQUEST_RETENTION = 0.9;
    static final int MAX_INTERVAL_DAYS = 36500;
    static final int AGAIN_RETRY_MINUTES = 5;

    /**
     * 카드의 평가 후 최신 상태(State, Stability, Difficulty, NextReview)를 계산하여 반환
     */
    public FsrsCard calculateNextState(FsrsCard card, ReviewRating rating, LocalDateTime now) {
        return preview(card, now).get(rating);
    }

    /**
     * 네 가지 평가 각각을 눌렀을 때의 다음 상태를 한 번에 계산합니다 (간격 순서 보정 포함).
     */
    public Map<ReviewRating, FsrsCard> preview(FsrsCard card, LocalDateTime now) {
        boolean isNew = card.getState() == FsrsState.NEW;
        double elapsedDays = elapsedDays(card, now);
        double r = isNew ? 1.0 : retrievability(elapsedDays, card.getStability());

        Map<ReviewRating, Double> stability = new EnumMap<>(ReviewRating.class);
        Map<ReviewRating, Double> difficulty = new EnumMap<>(ReviewRating.class);
        for (ReviewRating g : ReviewRating.values()) {
            if (isNew) {
                stability.put(g, initStability(g));
                difficulty.put(g, initDifficulty(g));
            } else {
                double d = card.getDifficulty();
                double s = card.getStability();
                stability.put(g, g == ReviewRating.AGAIN
                        ? nextForgetStability(d, s, r)
                        : nextRecallStability(d, s, r, g));
                difficulty.put(g, nextDifficulty(d, g));
            }
        }

        // 일 단위 간격 + HARD <= GOOD < EASY 순서 보정
        int hardIvl = interval(stability.get(ReviewRating.HARD));
        int goodIvl = interval(stability.get(ReviewRating.GOOD));
        int easyIvl = interval(stability.get(ReviewRating.EASY));
        hardIvl = Math.min(hardIvl, goodIvl);
        goodIvl = Math.max(goodIvl, hardIvl + 1);
        easyIvl = Math.max(easyIvl, goodIvl + 1);

        Map<ReviewRating, FsrsCard> result = new EnumMap<>(ReviewRating.class);
        int reps = card.getReps() + 1;

        FsrsState againState = (isNew || card.getState() == FsrsState.LEARNING)
                ? FsrsState.LEARNING : FsrsState.RELEARNING;
        // 복습 단계(REVIEW/RELEARNING)에서 잊은 경우만 lapse 로 셈
        int againLapses = (isNew || card.getState() == FsrsState.LEARNING)
                ? card.getLapses() : card.getLapses() + 1;
        result.put(ReviewRating.AGAIN, new FsrsCard(againState,
                stability.get(ReviewRating.AGAIN), difficulty.get(ReviewRating.AGAIN),
                reps, againLapses, now, now.plusMinutes(AGAIN_RETRY_MINUTES)));

        result.put(ReviewRating.HARD, reviewCard(stability, difficulty, ReviewRating.HARD, reps, card, now, hardIvl));
        result.put(ReviewRating.GOOD, reviewCard(stability, difficulty, ReviewRating.GOOD, reps, card, now, goodIvl));
        result.put(ReviewRating.EASY, reviewCard(stability, difficulty, ReviewRating.EASY, reps, card, now, easyIvl));
        return result;
    }

    private FsrsCard reviewCard(Map<ReviewRating, Double> stability, Map<ReviewRating, Double> difficulty,
                                ReviewRating g, int reps, FsrsCard card, LocalDateTime now, int intervalDays) {
        return new FsrsCard(FsrsState.REVIEW, stability.get(g), difficulty.get(g),
                reps, card.getLapses(), now, now.plusDays(intervalDays));
    }

    /** 마지막 복습 이후 경과 일수 (FSRS 표준처럼 정수 일, 음수 방지) */
    double elapsedDays(FsrsCard card, LocalDateTime now) {
        if (card.getLastReviewDate() == null) return 0;
        return Math.max(0, Duration.between(card.getLastReviewDate(), now).toDays());
    }

    /** 경과 t일 후 기억하고 있을 확률 R(t,S) */
    double retrievability(double elapsedDays, double stability) {
        if (stability <= 0) return 0;
        return Math.pow(1 + FACTOR * elapsedDays / stability, DECAY);
    }

    /** 목표 기억률(0.9)까지 떨어지는 데 걸리는 일수 */
    int interval(double stability) {
        double ivl = stability / FACTOR * (Math.pow(REQUEST_RETENTION, 1 / DECAY) - 1);
        return (int) Math.min(MAX_INTERVAL_DAYS, Math.max(1, Math.round(ivl)));
    }

    double initStability(ReviewRating g) {
        return Math.max(W[g.getValue() - 1], 0.1);
    }

    double initDifficulty(ReviewRating g) {
        return clampDifficulty(W[4] - (g.getValue() - 3) * W[5]);
    }

    double nextDifficulty(double d, ReviewRating g) {
        double nextD = d - W[6] * (g.getValue() - 3);
        // 평균 회귀: GOOD 초기 난이도 쪽으로 조금씩 당김
        return clampDifficulty(W[7] * initDifficulty(ReviewRating.GOOD) + (1 - W[7]) * nextD);
    }

    double nextRecallStability(double d, double s, double r, ReviewRating g) {
        double hardPenalty = g == ReviewRating.HARD ? W[15] : 1;
        double easyBonus = g == ReviewRating.EASY ? W[16] : 1;
        return s * (1 + Math.exp(W[8]) * (11 - d) * Math.pow(s, -W[9])
                * (Math.exp((1 - r) * W[10]) - 1) * hardPenalty * easyBonus);
    }

    double nextForgetStability(double d, double s, double r) {
        return W[11] * Math.pow(d, -W[12]) * (Math.pow(s + 1, W[13]) - 1) * Math.exp((1 - r) * W[14]);
    }

    private double clampDifficulty(double d) {
        return Math.min(10, Math.max(1, d));
    }
}
