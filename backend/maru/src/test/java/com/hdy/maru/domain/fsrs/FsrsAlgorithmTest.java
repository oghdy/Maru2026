package com.hdy.maru.domain.fsrs;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class FsrsAlgorithmTest {

    private final FsrsAlgorithm fsrs = new FsrsAlgorithm();

    @Test
    @DisplayName("신규 카드에 GOOD 평가 시 올바른 초기값이 세팅되는지 검증")
    void calculateNewCardWithGoodRating() {
        // given
        FsrsCard card = FsrsCard.createNewCard();
        LocalDateTime now = LocalDateTime.of(2026, 4, 14, 10, 0);

        // when
        FsrsCard reviewedCard = fsrs.calculateNextState(card, ReviewRating.GOOD, now);

        // then
        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.REVIEW);
        assertThat(reviewedCard.getStability()).isEqualTo(4.0);
        assertThat(reviewedCard.getDifficulty()).isEqualTo(5.0);
        assertThat(reviewedCard.getReps()).isEqualTo(1);
        assertThat(reviewedCard.getLapses()).isEqualTo(0);
        
        // GOOD일 때 stability가 4.0이므로 다음 리뷰일은 약 4일 후가 되어야 함
        assertThat(reviewedCard.getNextReviewDate()).isEqualTo(now.plusDays(4));
    }

    @Test
    @DisplayName("리뷰 카드에 AGAIN 평가 시 lapses가 증가하고 Relearning으로 변경되는지 검증")
    void calculateReviewCardWithAgainRating() {
        // given
        FsrsCard card = new FsrsCard(FsrsState.REVIEW, 5.0, 5.0, 3, 0, LocalDateTime.now());
        LocalDateTime now = LocalDateTime.of(2026, 4, 14, 10, 0);

        // when
        FsrsCard reviewedCard = fsrs.calculateNextState(card, ReviewRating.AGAIN, now);

        // then
        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.RELEARNING);
        assertThat(reviewedCard.getLapses()).isEqualTo(1); // lapses 증가
        assertThat(reviewedCard.getReps()).isEqualTo(4); // reps 증가
        // AGAIN 평가는 stability를 크게 감소시켜야 함 (초기 수준 혹은 그 이하)
        assertThat(reviewedCard.getStability()).isLessThan(5.0);
        assertThat(reviewedCard.getDifficulty()).isGreaterThan(5.0); // 어려워지므로 difficulty 증가
    }
    
    @Test
    @DisplayName("EASY 평가 시 가장 큰 폭으로 안정기가 증가하는지 검증")
    void calculateNewCardWithEasyRating() {
        // given
        FsrsCard card = FsrsCard.createNewCard();
        LocalDateTime now = LocalDateTime.of(2026, 4, 14, 10, 0);

        // when
        FsrsCard reviewedCard = fsrs.calculateNextState(card, ReviewRating.EASY, now);

        // then
        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.REVIEW);
        assertThat(reviewedCard.getStability()).isGreaterThan(4.0); // GOOD(4.0)보다 안정기가 높아야 함
        assertThat(reviewedCard.getDifficulty()).isLessThan(5.0); // EASY는 더 쉬움
        assertThat(reviewedCard.getNextReviewDate().isAfter(now.plusDays(4))).isTrue();
    }
    
    @Test
    @DisplayName("HARD 평가 시 안정기가 적게 증가하는지 검증")
    void calculateNewCardWithHardRating() {
        // given
        FsrsCard card = FsrsCard.createNewCard();
        LocalDateTime now = LocalDateTime.of(2026, 4, 14, 10, 0);

        // when
        FsrsCard reviewedCard = fsrs.calculateNextState(card, ReviewRating.HARD, now);

        // then
        assertThat(reviewedCard.getState()).isEqualTo(FsrsState.REVIEW);
        assertThat(reviewedCard.getStability()).isLessThan(4.0); // GOOD(4.0)보다 안정기가 적게 증가
        assertThat(reviewedCard.getStability()).isGreaterThan(0.0);
        assertThat(reviewedCard.getDifficulty()).isGreaterThan(5.0); // HARD는 어려우므로
    }
}
