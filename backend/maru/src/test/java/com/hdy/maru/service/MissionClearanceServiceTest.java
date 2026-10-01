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
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
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
        assertThat(res.getResultReason()).isEqualTo("You ended the conversation before reaching the mission goal.");
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

    // --- MSN-1.7.1: only the learner's own sentences may be quoted ---

    @Test
    void isQuotedFromUser_normalizesSpacesAndPunctuation() {
        List<String> mine = List.of("아이스 아메리카노 한 잔 주세요!", "Thank you.");
        assertThat(MissionClearanceService.isQuotedFromUser("아이스아메리카노 한 잔 주세요", mine)).isTrue();
        assertThat(MissionClearanceService.isQuotedFromUser("한 잔 주세요.", mine)).isTrue();   // part of a message
        assertThat(MissionClearanceService.isQuotedFromUser("THANK YOU", mine)).isTrue();
        assertThat(MissionClearanceService.isQuotedFromUser("라떼 한 잔 주세요", mine)).isFalse();
        assertThat(MissionClearanceService.isQuotedFromUser("  ?! ", mine)).isFalse();         // empty after normalize
    }

    @Test
    void issue_dropsExpressionsTheUserNeverSent() {
        List<Map<String, String>> h = List.of(
                Map.of("role", "assistant", "content", "어서 오세요. 뭐 드릴까요?"),
                Map.of("role", "user", "content", "커피 주세요"),
                Map.of("role", "assistant", "content", "따뜻한 걸로 드릴까요?"),
                Map.of("role", "user", "content", "아이스 아메리카노 하나 줘."));
        String json = "{\"certificate\":{\"result\":\"cleared\",\"result_reason\":\"r\","
                + "\"good_expressions\":["
                + "{\"expression\":\"커피 주세요.\",\"reason\":\"ok\"},"
                + "{\"expression\":\"아이스 아메리카노 한 잔 주시겠어요?\",\"reason\":\"suggestion, not sent\"},"
                + "{\"expression\":\"어서 오세요\",\"reason\":\"persona line\"}],"
                + "\"incorrect_expressions\":["
                + "{\"wrong\":\"하나 줘\",\"correct\":\"하나 주세요\",\"explanation\":\"polite\"},"
                + "{\"wrong\":\"라떼 줘\",\"correct\":\"라떼 주세요\",\"explanation\":\"invented\"}],"
                + "\"turtle_comment\":\"c\",\"next_practice\":\"n\"}}";
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(json);

        MissionClearanceResponseDto res = service.issueClearance("u1", setup(2), h, "cleared");

        assertThat(res.getGoodExpressions()).extracting(m -> m.get("expression")).containsExactly("커피 주세요.");
        assertThat(res.getIncorrectExpressions()).extracting(m -> m.get("wrong")).containsExactly("하나 줘");
    }

    @Test
    void issue_promptListsOnlyUserSentencesAsCandidates() {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(cert("cleared"));
        List<Map<String, String>> h = List.of(
                Map.of("role", "assistant", "content", "뭐 드릴까요?"),
                Map.of("role", "user", "content", " 커피 주세요 "),
                Map.of("role", "user", "content", "  "),
                Map.of("role", "user", "content", "감사합니다"));
        service.issueClearance("u1", setup(2), h, null);

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(openAiService).askWithHistory(prompt.capture(), eq(h));
        assertThat(prompt.getValue())
                .contains("\n1. 커피 주세요\n2. 감사합니다\n\n")
                .doesNotContain("{{student_messages}}");
    }
}
