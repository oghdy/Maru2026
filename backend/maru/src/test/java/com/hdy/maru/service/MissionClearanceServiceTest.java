package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.MissionClearanceResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.entity.MissionClearance;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.MissionClearanceRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.util.PromptLoader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MissionClearanceServiceTest {

    private OpenAiService openAiService;
    private MissionClearanceRepository repository;
    private UserRepository userRepository;
    private MissionClearanceService service;

    @BeforeEach
    void setUp() {
        openAiService = mock(OpenAiService.class);
        repository = mock(MissionClearanceRepository.class);
        userRepository = mock(UserRepository.class);
        service = new MissionClearanceService(openAiService, new PromptLoader(), new ObjectMapper(), repository, userRepository);
        when(userRepository.findByOauthId("u1")).thenReturn(Optional.of(new User()));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private static MissionSetupResponseDto setup(int minTurns) {
        return MissionSetupResponseDto.builder()
                .persona(MissionSetupResponseDto.PersonaDto.builder().role("카페 직원").build())
                .mission(MissionSetupResponseDto.MissionDto.builder()
                        .title("Order a drink").description("Order coffee")
                        .clearCondition(MissionSetupResponseDto.MissionDto.ClearConditionDto.builder()
                                .goalCondition("Order one drink").languageCondition("Use 존댓말").build())
                        .minTurns(minTurns).build())
                .build();
    }

    private static List<Map<String, String>> history(int userTurns) {
        List<Map<String, String>> h = new ArrayList<>();
        for (int i = 0; i < userTurns; i++) {
            h.add(Map.of("role", "assistant", "content", "네."));
            h.add(Map.of("role", "user", "content", "커피 주세요."));
        }
        return h;
    }

    private static String cert(String result) {
        return "{\"certificate\":{\"result\":\"" + result + "\",\"result_reason\":\"AI reason\","
                + "\"good_expressions\":[{\"expression\":\"커피 주세요.\",\"reason\":\"Polite\"}],"
                + "\"incorrect_expressions\":[],\"turtle_comment\":\"Nice\",\"next_practice\":\"Next\"}}";
    }

    @Test
    void decideCleared_rules() {
        assertThat(MissionClearanceService.decideCleared("cleared", 3, 4)).isTrue();
        assertThat(MissionClearanceService.decideCleared("cleared", 2, 4)).isFalse();
        assertThat(MissionClearanceService.decideCleared("not_cleared", 6, 4)).isFalse();
    }

    @Test
    void issue_cleared_savesResultAndGoal() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(cert("cleared"));
        MissionClearanceResponseDto res = service.issueClearance("u1", setup(4), history(4), "cleared");
        assertThat(res.getCleared()).isTrue();
        assertThat(res.getResultReason()).isEqualTo("AI reason");
        assertThat(res.getGoalCondition()).isEqualTo("Order one drink");
        assertThat(res.getIncorrectExpressions()).isEmpty();
        assertThat(res.getTotalTurns()).isEqualTo(4);
    }

    @Test
    void issue_notCleared_stillHasFeedback() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(cert("not_cleared"));
        MissionClearanceResponseDto res = service.issueClearance("u1", setup(4), history(7), "failed");
        assertThat(res.getCleared()).isFalse();
        assertThat(res.getGoodExpressions()).hasSize(1);
        assertThat(res.getNextPractice()).isEqualTo("Next");
    }

    @Test
    void issue_aiClearsTooShortConversation_isOverridden() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(cert("cleared"));
        MissionClearanceResponseDto res = service.issueClearance("u1", setup(6), history(2), null);
        assertThat(res.getCleared()).isFalse();
        assertThat(res.getResultReason()).isEqualTo("The conversation ended before the goal could be reached.");
    }

    @Test
    void issue_missingResult_is502_andNotSaved() {
        when(openAiService.askWithHistory(anyString(), any()))
                .thenReturn("{\"certificate\":{\"turtle_comment\":\"Nice\"}}");
        assertThatThrownBy(() -> service.issueClearance("u1", setup(4), history(4), null))
                .isInstanceOf(MissionChatException.class)
                .satisfies(e -> assertThat(((MissionChatException) e).getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY));
        verify(repository, never()).save(any(MissionClearance.class));
    }

    @Test
    void issue_unknownUser_is404_beforeAiCall() {
        assertThatThrownBy(() -> service.issueClearance("ghost", setup(4), history(4), null))
                .isInstanceOf(MissionChatException.class)
                .satisfies(e -> assertThat(((MissionChatException) e).getStatus()).isEqualTo(HttpStatus.NOT_FOUND));
        verify(openAiService, never()).askWithHistory(anyString(), any());
    }
}
