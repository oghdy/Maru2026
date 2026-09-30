package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.startsWith;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ChatTurnServiceTest {

    private static final String RABBIT_OK = "{\"rabbit_reply\":\"네, 있어요.\",\"rabbit_reply_en\":\"Yes.\",\"mission_status\":\"in_progress\"}";
    private static final String TURTLE_OK = "{\"severity\":\"none\",\"issue_type\":\"none\"}";

    private OpenAiService openAiService;
    private ChatTurnService service;

    @BeforeEach
    void setUp() {
        openAiService = mock(OpenAiService.class);
        service = new ChatTurnService(openAiService, new PromptLoader(), new ObjectMapper());
    }

    private static MissionSetupResponseDto setup() {
        return MissionSetupResponseDto.builder()
                .persona(MissionSetupResponseDto.PersonaDto.builder()
                        .role("카페 직원").personality("친절한").speechStyle("존댓말").honorificLevel("존댓말")
                        .firstMessage("어서 오세요!").build())
                .mission(MissionSetupResponseDto.MissionDto.builder()
                        .title("Order a drink").description("Order coffee")
                        .clearCondition(MissionSetupResponseDto.MissionDto.ClearConditionDto.builder()
                                .goalCondition("Order one drink").languageCondition("Use 존댓말").build())
                        .minTurns(4).build())
                .build();
    }

    private static ChatTurnRequestDto request(String msg) {
        List<Map<String, String>> history = new ArrayList<>();
        history.add(Map.of("role", "assistant", "content", "어서 오세요!"));
        return ChatTurnRequestDto.builder().userMessage(msg).conversationHistory(history).setup(setup()).build();
    }

    private void stubAi(String rabbit, String turtle) {
        // Rabbit prompt starts with "You are playing the role", turtle with "You are a Korean language tutor"
        when(openAiService.askWithHistory(startsWith("You are playing"), any())).thenReturn(rabbit);
        when(openAiService.askWithHistory(startsWith("You are a Korean"), any())).thenReturn(turtle);
    }

    @Test
    void processTurn_ok() {
        stubAi(RABBIT_OK, TURTLE_OK);
        ChatTurnResponseDto res = service.processTurn(request("커피 주세요."), setup());
        assertThat(res.getRabbitReply()).isEqualTo("네, 있어요.");
        assertThat(res.getMissionStatus()).isEqualTo("in_progress");
        assertThat(res.getCorrection().getSeverity()).isEqualTo("none");
    }

    @Test
    void processTurn_unknownStatus_fallsBackToInProgress() {
        stubAi("{\"rabbit_reply\":\"네.\",\"mission_status\":\"done\"}", TURTLE_OK);
        assertThat(service.processTurn(request("커피 주세요."), setup()).getMissionStatus()).isEqualTo("in_progress");
    }

    @Test
    void processTurn_brokenJson_is502() {
        stubAi("not json", TURTLE_OK);
        assertThatThrownBy(() -> service.processTurn(request("커피 주세요."), setup()))
                .isInstanceOf(MissionChatException.class)
                .satisfies(e -> assertThat(((MissionChatException) e).getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY))
                .hasMessage(MissionChatException.MSG_AI_BAD_ANSWER);
    }

    @Test
    void processTurn_aiTimeout_inParallelCall_isUnwrapped() {
        when(openAiService.askWithHistory(startsWith("You are playing"), any())).thenReturn(RABBIT_OK);
        when(openAiService.askWithHistory(startsWith("You are a Korean"), any()))
                .thenThrow(new MissionChatException(HttpStatus.GATEWAY_TIMEOUT, MissionChatException.MSG_AI_TIMEOUT));
        assertThatThrownBy(() -> service.processTurn(request("커피 주세요."), setup()))
                .isInstanceOf(MissionChatException.class)
                .hasMessage(MissionChatException.MSG_AI_TIMEOUT);
    }

    @Test
    void processTurn_missingSetup_is400() {
        ChatTurnRequestDto req = request("커피 주세요.");
        assertThatThrownBy(() -> service.processTurn(req, null))
                .isInstanceOf(MissionChatException.class)
                .satisfies(e -> assertThat(((MissionChatException) e).getStatus()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    @SuppressWarnings("unchecked")
    void processTurn_historyAlreadyHasUserMessage_notDuplicated() {
        stubAi(RABBIT_OK, TURTLE_OK);
        ChatTurnRequestDto req = request("커피 주세요.");
        req.getConversationHistory().add(Map.of("role", "user", "content", "커피 주세요."));

        service.processTurn(req, setup());

        ArgumentCaptor<List<Map<String, String>>> captor = ArgumentCaptor.forClass(List.class);
        verify(openAiService).askWithHistory(startsWith("You are playing"), captor.capture());
        List<Map<String, String>> sent = captor.getValue();
        assertThat(sent).hasSize(2);
        assertThat(sent.get(1)).containsEntry("content", "커피 주세요.");
    }

    @Test
    @SuppressWarnings("unchecked")
    void processTurn_historyWithoutUserMessage_appendsIt_andCountsThisTurn() {
        stubAi(RABBIT_OK, TURTLE_OK);

        service.processTurn(request("커피 주세요."), setup());

        ArgumentCaptor<List<Map<String, String>>> captor = ArgumentCaptor.forClass(List.class);
        verify(openAiService).askWithHistory(startsWith("You are playing"), captor.capture());
        // rabbit prompt sees this turn as turn 1
        verify(openAiService).askWithHistory(
                org.mockito.ArgumentMatchers.contains("latest message): 1"), any());
        assertThat(captor.getValue()).hasSize(2);
    }

    private static ChatTurnResponseDto aiSays(String status) {
        return ChatTurnResponseDto.builder().rabbitReply("네.").missionStatus(status).build();
    }

    @Test
    void zoneRules_minTurns4() {
        // min=4 → A: t<=2, B: 3..5, C: 6.., max=7
        ChatTurnResponseDto r = aiSays("cleared");
        ChatTurnService.applyZoneRules(r, 4, 2);
        assertThat(r.getZone()).isEqualTo("A");
        assertThat(r.getMissionStatus()).isEqualTo("in_progress");
        assertThat(r.getMaxTurns()).isEqualTo(7);

        r = aiSays("cleared");
        ChatTurnService.applyZoneRules(r, 4, 3);
        assertThat(r.getZone()).isEqualTo("B");
        assertThat(r.getMissionStatus()).isEqualTo("cleared");

        r = aiSays("failed");
        ChatTurnService.applyZoneRules(r, 4, 5);
        assertThat(r.getMissionStatus()).isEqualTo("in_progress");

        r = aiSays("in_progress");
        ChatTurnService.applyZoneRules(r, 4, 6);
        assertThat(r.getZone()).isEqualTo("C");
        assertThat(r.getMissionStatus()).isEqualTo("in_progress");

        r = aiSays("in_progress");
        ChatTurnService.applyZoneRules(r, 4, 7);
        assertThat(r.getMissionStatus()).isEqualTo("failed");
        assertThat(r.getUserTurn()).isEqualTo(7);

        r = aiSays("failed");
        ChatTurnService.applyZoneRules(r, 4, 6);
        assertThat(r.getMissionStatus()).isEqualTo("failed");
    }

    @Test
    void processTurn_clearedTooEarly_isInProgress() {
        stubAi("{\"rabbit_reply\":\"감사합니다!\",\"mission_status\":\"cleared\"}", TURTLE_OK);
        ChatTurnResponseDto res = service.processTurn(request("커피 주세요."), setup());
        assertThat(res.getMissionStatus()).isEqualTo("in_progress");
        assertThat(res.getUserTurn()).isEqualTo(1);
        assertThat(res.getZone()).isEqualTo("A");
    }

    @Test
    void processTurn_stringNull_normalizedToNull() {
        stubAi("{\"rabbit_reply\":\"네.\",\"rabbit_reply_en\":\"null\",\"mission_status\":\"in_progress\"}",
                "{\"severity\":\"side\",\"issue_type\":\"grammar_error\",\"user_input_problematic\":\"커피 줘요\","
                        + "\"correct_expression\":\"커피 주세요\",\"turtle_feedback\":\"'주세요'가 더 자연스러워요.\",\"turtle_feedback_en\":\"null\"}");
        ChatTurnResponseDto res = service.processTurn(request("커피 줘요."), setup());
        assertThat(res.getRabbitReplyEn()).isNull();
        assertThat(res.getCorrection().getTurtleFeedbackEn()).isNull();
        assertThat(res.getCorrection().getCorrectExpression()).isEqualTo("커피 주세요");
        assertThat(res.getCorrection().getSeverity()).isEqualTo("side");
    }

    @Test
    void processTurn_immediateWithAllNullStrings_becomesNone() {
        stubAi(RABBIT_OK, "{\"severity\":\"immediate\",\"issue_type\":\"honorific_mismatch\",\"user_input_problematic\":\"null\","
                + "\"correct_expression\":\"null\",\"turtle_feedback\":\"null\",\"turtle_feedback_en\":\"null\"}");
        ChatTurnResponseDto res = service.processTurn(request("커피 주세요."), setup());
        assertThat(res.getCorrection().getSeverity()).isEqualTo("none");
        assertThat(res.getCorrection().getIssueType()).isEqualTo("none");
        assertThat(res.getCorrection().getUserInputProblematic()).isNull();
        assertThat(res.getCorrection().getTurtleFeedback()).isNull();
    }
}
