package com.hdy.maru.domain.fsrs;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class FsrsAlgorithmTest {

    private final FsrsAlgorithm fsrs = new FsrsAlgorithm();
    private final LocalDateTime now = LocalDateTime.of(2026, 4, 14, 10, 0);

    @Test
    @DisplayName("신규 카드 GOOD: S0 = w2, D0 = w4, 다음 복습 = round(S) 일 후")
    void calculateNewCardWithGoodRating() {
        FsrsCard reviewedCard = fsrs.calculateNextState(FsrsCard.createNewCard(), ReviewRating.GOOD, now);

        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.REVIEW);
        assertThat(reviewedCard.getStability()).isCloseTo(3.7145, within(1e-9));
        assertThat(reviewedCard.getDifficulty()).isCloseTo(5.1618, within(1e-9));
        assertThat(reviewedCard.getReps()).isEqualTo(1);
        assertThat(reviewedCard.getLapses()).isEqualTo(0);
        assertThat(reviewedCard.getNextReviewDate()).isEqualTo(now.plusDays(4));
    }

    @Test
    @DisplayName("신규 카드 평가별 초기값: AGAIN 5분 재시도 / HARD 1일 / EASY 14일, 쉬울수록 난이도 낮음")
    void calculateNewCardAllRatings() {
        Map<ReviewRating, FsrsCard> p = fsrs.preview(FsrsCard.createNewCard(), now);

        FsrsCard again = p.get(ReviewRating.AGAIN);
        assertThat(again.getState()).isEqualTo(FsrsState.LEARNING);
        assertThat(again.getStability()).isCloseTo(0.4872, within(1e-9));
        assertThat(again.getDifficulty()).isCloseTo(5.1618 + 2 * 1.2298, within(1e-9));
        assertThat(again.getLapses()).isEqualTo(0); // 신규 카드 실패는 lapse 아님
        assertThat(again.getNextReviewDate()).isEqualTo(now.plusMinutes(5));

        assertThat(p.get(ReviewRating.HARD).getNextReviewDate()).isEqualTo(now.plusDays(1));
        assertThat(p.get(ReviewRating.EASY).getStability()).isCloseTo(13.8206, within(1e-9));
        assertThat(p.get(ReviewRating.EASY).getNextReviewDate()).isEqualTo(now.plusDays(14));
        assertThat(p.get(ReviewRating.EASY).getDifficulty()).isLessThan(p.get(ReviewRating.GOOD).getDifficulty());
        assertThat(p.get(ReviewRating.HARD).getDifficulty()).isGreaterThan(p.get(ReviewRating.GOOD).getDifficulty());
    }

    @Test
    @DisplayName("기억률 R(t,S): 경과일 = S 일 때 정확히 0.9, 간격 = 목표 기억률 0.9 까지의 일수 = S")
    void retrievabilityAndIntervalMatchTargetRetention() {
        assertThat(fsrs.retrievability(0, 5.0)).isEqualTo(1.0);
        assertThat(fsrs.retrievability(5, 5.0)).isCloseTo(0.9, within(1e-9));
        assertThat(fsrs.retrievability(20, 5.0)).isLessThan(fsrs.retrievability(10, 5.0));
        assertThat(fsrs.interval(5.0)).isEqualTo(5);
        assertThat(fsrs.interval(0.2)).isEqualTo(1);       // 최소 1일
        assertThat(fsrs.interval(1e9)).isEqualTo(36500);   // 최대 100년
    }

    @Test
    @DisplayName("리뷰 카드 AGAIN: lapses 증가, Relearning, 안정성 하락, 난이도 상승, 5분 뒤 재시도")
    void calculateReviewCardWithAgainRating() {
        FsrsCard card = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, now.minusDays(5));

        FsrsCard reviewedCard = fsrs.calculateNextState(card, ReviewRating.AGAIN, now);

        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.RELEARNING);
        assertThat(reviewedCard.getLapses()).isEqualTo(1);
        assertThat(reviewedCard.getReps()).isEqualTo(4);
        assertThat(reviewedCard.getStability()).isLessThan(5.0);
        assertThat(reviewedCard.getDifficulty()).isGreaterThan(5.0);
        assertThat(reviewedCard.getNextReviewDate()).isEqualTo(now.plusMinutes(5));
    }

    @Test
    @DisplayName("리뷰 카드 기한에 복습: 안정성 증가, 간격 HARD < GOOD < EASY")
    void calculateReviewCardOnDueDate() {
        FsrsCard card = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, now.minusDays(5)); // R = 0.9

        Map<ReviewRating, FsrsCard> p = fsrs.preview(card, now);

        assertThat(p.get(ReviewRating.GOOD).getState()).isEqualTo(FsrsState.REVIEW);
        assertThat(p.get(ReviewRating.GOOD).getStability()).isGreaterThan(5.0);
        assertThat(p.get(ReviewRating.EASY).getStability()).isGreaterThan(p.get(ReviewRating.GOOD).getStability());
        assertThat(p.get(ReviewRating.HARD).getStability()).isLessThan(p.get(ReviewRating.GOOD).getStability());
        assertThat(p.get(ReviewRating.HARD).getNextReviewDate()).isBefore(p.get(ReviewRating.GOOD).getNextReviewDate());
        assertThat(p.get(ReviewRating.GOOD).getNextReviewDate()).isBefore(p.get(ReviewRating.EASY).getNextReviewDate());
        assertThat(p.get(ReviewRating.GOOD).getLapses()).isEqualTo(0);
    }

    @Test
    @DisplayName("간격 효과: 더 오래 지나서(기억률이 낮을 때) 성공할수록 안정성이 더 크게 오른다. 같은 날 재복습은 거의 그대로")
    void longerElapsedTimeGivesBiggerStabilityGain() {
        FsrsCard sameDay = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, now.minusHours(2));
        FsrsCard onTime = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, now.minusDays(5));
        FsrsCard late = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, now.minusDays(20));

        double sSameDay = fsrs.calculateNextState(sameDay, ReviewRating.GOOD, now).getStability();
        double sOnTime = fsrs.calculateNextState(onTime, ReviewRating.GOOD, now).getStability();
        double sLate = fsrs.calculateNextState(late, ReviewRating.GOOD, now).getStability();

        assertThat(sSameDay).isCloseTo(5.0, within(1e-9));
        assertThat(sOnTime).isGreaterThan(sSameDay);
        assertThat(sLate).isGreaterThan(sOnTime);
    }

    @Test
    @DisplayName("난이도는 1~10 범위를 벗어나지 않는다")
    void difficultyStaysInRange() {
        FsrsCard card = new FsrsCard(FsrsState.REVIEW, 5.0, 10.0, 3, 0, now.minusDays(5));
        assertThat(fsrs.calculateNextState(card, ReviewRating.AGAIN, now).getDifficulty()).isLessThanOrEqualTo(10.0);

        FsrsCard easyCard = new FsrsCard(FsrsState.REVIEW, 5.0, 1.0, 3, 0, now.minusDays(5));
        assertThat(fsrs.calculateNextState(easyCard, ReviewRating.EASY, now).getDifficulty()).isGreaterThanOrEqualTo(1.0);
    }
}
