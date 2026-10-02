package com.hdy.maru.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class MissionDifficultyTest {

    @Test
    void from_defaultsToEasy() {
        assertThat(MissionDifficulty.from(null)).isEqualTo(MissionDifficulty.EASY);
        assertThat(MissionDifficulty.from("")).isEqualTo(MissionDifficulty.EASY);
        assertThat(MissionDifficulty.from("expert")).isEqualTo(MissionDifficulty.EASY);
        assertThat(MissionDifficulty.from(" Normal ")).isEqualTo(MissionDifficulty.NORMAL);
        assertThat(MissionDifficulty.from("HARD")).isEqualTo(MissionDifficulty.HARD);
        assertThat(MissionDifficulty.NORMAL.apiValue()).isEqualTo("normal");
    }

    @Test
    void clampMinTurns_keepsLevelRange() {
        assertThat(MissionDifficulty.EASY.clampMinTurns(8)).isEqualTo(4);
        assertThat(MissionDifficulty.EASY.clampMinTurns(0)).isEqualTo(3);
        assertThat(MissionDifficulty.EASY.clampMinTurns(3)).isEqualTo(3);
        assertThat(MissionDifficulty.NORMAL.clampMinTurns(2)).isEqualTo(4);
        assertThat(MissionDifficulty.NORMAL.clampMinTurns(5)).isEqualTo(5);
        assertThat(MissionDifficulty.HARD.clampMinTurns(12)).isEqualTo(10);
    }

    @Test
    void rabbitReplyTooLong_ignoresSpaces_with40PercentSlack() {
        // easy limit 25 → retry above 35 non-space chars
        assertThat(MissionDifficulty.EASY.isRabbitReplyTooLong("어떤 음료 드릴까요?")).isFalse();
        assertThat(MissionDifficulty.EASY.isRabbitReplyTooLong("가".repeat(35) + "   ")).isFalse();
        assertThat(MissionDifficulty.EASY.isRabbitReplyTooLong("가".repeat(36))).isTrue();
        assertThat(MissionDifficulty.HARD.isRabbitReplyTooLong("가".repeat(100))).isFalse();
        assertThat(MissionDifficulty.EASY.isRabbitReplyTooLong(null)).isFalse();
    }
}
