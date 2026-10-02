package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.MissionSetupRequestDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MissionSetupServiceTest {

    private OpenAiService openAiService;
    private MissionSetupService service;

    @BeforeEach
    void setUp() {
        openAiService = mock(OpenAiService.class);
        service = new MissionSetupService(openAiService, new PromptLoader(), new ObjectMapper());
    }

    private static String ai(int minTurns) {
        return "{\"persona\":{\"role\":\"카페 직원\",\"personality\":\"친절한\",\"speech_style\":\"존댓말\","
                + "\"honorific_level\":\"존댓말\",\"first_message\":\"어서 오세요!\",\"first_message_en\":\"Welcome!\"},"
                + "\"mission\":{\"title\":\"Order a drink\",\"description\":\"Order coffee\","
                + "\"clear_condition\":{\"goal_condition\":\"Order one drink\",\"language_condition\":\"Use -요\"},"
                + "\"min_turns\":" + minTurns + "},\"adjustment_notice\":null}";
    }

    private static MissionSetupRequestDto req(String difficulty) {
        return MissionSetupRequestDto.builder().hierarchy("윗사람").intimacy("초면").role("카페 직원")
                .difficulty(difficulty).build();
    }

    @Test
    void noDifficulty_defaultsToEasy_echoed_andMinTurnsClamped() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(ai(8));
        MissionSetupResponseDto res = service.generateMission(req(null));
        assertThat(res.getDifficulty()).isEqualTo("easy");
        assertThat(res.getMission().getMinTurns()).isEqualTo(4);
        verify(openAiService).askWithHistory(contains("Difficulty: easy"), any());
    }

    @Test
    void hard_isEchoed_andKeepsLongerMission() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(ai(8));
        MissionSetupResponseDto res = service.generateMission(req("hard"));
        assertThat(res.getDifficulty()).isEqualTo("hard");
        assertThat(res.getMission().getMinTurns()).isEqualTo(8);
    }

    @Test
    void normal_missingMinTurns_usesLowerBound() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(ai(0));
        MissionSetupResponseDto res = service.generateMission(req("normal"));
        assertThat(res.getMission().getMinTurns()).isEqualTo(4);
    }
}
