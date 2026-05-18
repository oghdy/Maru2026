package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatTurnService {

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;

    /**
     * Processes a single chat turn.
     * Sends the full conversation history to OpenAI (Stateless on the server side).
     * Calls LLM Call #2.
     */
    public ChatTurnResponseDto processTurn(ChatTurnRequestDto request, MissionSetupResponseDto setup) {
        MissionSetupResponseDto.PersonaDto persona = setup.getPersona();
        MissionSetupResponseDto.MissionDto mission = setup.getMission();

        // Build system prompt with full persona & mission context
        // Calculate current user turn count (before this turn, for zone judgment)
        int currentUserTurns = (int) request.getConversationHistory().stream()
                .filter(m -> "user".equals(m.get("role")))
                .count();

        String rabbitSystemPrompt = promptLoader.load("rabbit_reply_system.txt", Map.of(
                "persona_role", persona.getRole(),
                "persona_personality", persona.getPersonality(),
                "persona_speech_style", persona.getSpeechStyle(),
                "persona_honorific_level", persona.getHonorificLevel(),
                "mission_title", mission.getTitle(),
                "mission_description", mission.getDescription(),
                "mission_goal_condition", mission.getClearCondition().getGoalCondition(),
                "mission_language_condition", mission.getClearCondition().getLanguageCondition(),
                "mission_min_turns", String.valueOf(mission.getMinTurns()),
                "current_turn_count", String.valueOf(currentUserTurns)
        ));

        String turtleSystemPrompt = promptLoader.load("turtle_eval_system.txt", Map.of(
                "persona_role", persona.getRole(),
                "persona_speech_style", persona.getSpeechStyle(),
                "persona_honorific_level", persona.getHonorificLevel()
        ));

        // Build history: existing history + the new user message
        List<Map<String, String>> fullHistory = new ArrayList<>();
        if (request.getConversationHistory() != null) {
            fullHistory.addAll(request.getConversationHistory());
        }
        fullHistory.add(Map.of("role", "user", "content", request.getUserMessage()));

        // Run both calls in parallel
        CompletableFuture<String> rabbitFuture = CompletableFuture.supplyAsync(() ->
                openAiService.askWithHistory(rabbitSystemPrompt, fullHistory)
        );

        CompletableFuture<String> turtleFuture = CompletableFuture.supplyAsync(() ->
                openAiService.askWithHistory(turtleSystemPrompt, fullHistory)
        );

        // Wait for both to complete
        CompletableFuture.allOf(rabbitFuture, turtleFuture).join();

        try {
            String rabbitJson = rabbitFuture.get();
            String turtleJson = turtleFuture.get();
            return parseResponses(rabbitJson, turtleJson);
        } catch (Exception e) {
            log.error("Failed to execute parallel LLM calls", e);
            throw new RuntimeException("Failed to process chat turn in parallel", e);
        }
    }

    private ChatTurnResponseDto parseResponses(String rabbitJson, String turtleJson) {
        try {
            JsonNode rabbitRoot = objectMapper.readTree(rabbitJson);
            JsonNode turtleRoot = objectMapper.readTree(turtleJson);

            ChatTurnResponseDto.CorrectionDto correction = ChatTurnResponseDto.CorrectionDto.builder()
                    .severity(turtleRoot.path("severity").asText("none"))
                    .issueType(turtleRoot.path("issue_type").asText("none"))
                    .userInputProblematic(nullableText(turtleRoot, "user_input_problematic"))
                    .correctExpression(nullableText(turtleRoot, "correct_expression"))
                    .turtleFeedback(nullableText(turtleRoot, "turtle_feedback"))
                    .turtleFeedbackEn(nullableText(turtleRoot, "turtle_feedback_en"))
                    .build();

            return ChatTurnResponseDto.builder()
                    .rabbitReply(nullableText(rabbitRoot, "rabbit_reply"))
                    .rabbitReplyEn(nullableText(rabbitRoot, "rabbit_reply_en"))
                    .correction(correction)
                    .missionStatus(rabbitRoot.path("mission_status").asText("in_progress"))
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse ChatTurn responses. Rabbit: {}, Turtle: {}", rabbitJson, turtleJson);
            throw new RuntimeException("Failed to parse chat turn response from AI: " + e.getMessage(), e);
        }
    }

    private String nullableText(JsonNode node, String fieldName) {
        JsonNode field = node.path(fieldName);
        if (field.isNull() || field.isMissingNode()) {
            return null;
        }
        return field.asText();
    }
}
