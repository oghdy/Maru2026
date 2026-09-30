package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatTurnService {

    private static final Set<String> MISSION_STATUSES = Set.of("in_progress", "cleared", "failed");
    private static final Set<String> SEVERITIES = Set.of("none", "side", "immediate");
    static final int DEFAULT_MIN_TURNS = 5;
    static final int EXTRA_TURNS_BEFORE_STOP = 3; // maxTurns = minTurns + 3

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;

    /**
     * Processes a single chat turn.
     * Sends the full conversation history to OpenAI (Stateless on the server side).
     * Calls LLM Call #2.
     */
    public ChatTurnResponseDto processTurn(ChatTurnRequestDto request, MissionSetupResponseDto setup) {
        validate(request, setup);
        MissionSetupResponseDto.PersonaDto persona = setup.getPersona();
        MissionSetupResponseDto.MissionDto mission = setup.getMission();
        List<Map<String, String>> history = request.getConversationHistory() != null
                ? request.getConversationHistory() : List.of();

        // Build history: existing history + the new user message.
        // The app may already include the new message as the last history entry — don't send it twice.
        List<Map<String, String>> fullHistory = new ArrayList<>(history);
        if (!endsWithUserMessage(history, request.getUserMessage())) {
            fullHistory.add(Map.of("role", "user", "content", request.getUserMessage()));
        }

        // Current user turn count INCLUDING this turn (used for 3-zone judgment)
        int currentUserTurns = countUserTurns(fullHistory);

        Map<String, String> rabbitVars = new HashMap<>();
        rabbitVars.put("persona_role", persona.getRole());
        rabbitVars.put("persona_personality", persona.getPersonality());
        rabbitVars.put("persona_speech_style", persona.getSpeechStyle());
        rabbitVars.put("persona_honorific_level", persona.getHonorificLevel());
        rabbitVars.put("mission_title", mission.getTitle());
        rabbitVars.put("mission_description", mission.getDescription());
        rabbitVars.put("mission_goal_condition", mission.getClearCondition().getGoalCondition());
        rabbitVars.put("mission_language_condition", mission.getClearCondition().getLanguageCondition());
        int minTurns = effectiveMinTurns(mission);
        rabbitVars.put("mission_min_turns", String.valueOf(minTurns));
        rabbitVars.put("mission_max_turns", String.valueOf(minTurns + EXTRA_TURNS_BEFORE_STOP));
        rabbitVars.put("current_turn_count", String.valueOf(currentUserTurns));
        String rabbitSystemPrompt = promptLoader.load("rabbit_reply_system.txt", rabbitVars);

        Map<String, String> turtleVars = new HashMap<>();
        turtleVars.put("persona_role", persona.getRole());
        turtleVars.put("persona_speech_style", persona.getSpeechStyle());
        turtleVars.put("persona_honorific_level", persona.getHonorificLevel());
        String turtleSystemPrompt = promptLoader.load("turtle_eval_system.txt", turtleVars);

        // Run both calls in parallel (elapsed ms recorded per call for the timing log)
        long startNs = System.nanoTime();
        long[] rabbitMs = {-1};
        long[] turtleMs = {-1};
        CompletableFuture<String> rabbitFuture = CompletableFuture.supplyAsync(() -> {
            long t0 = System.nanoTime();
            String json = openAiService.askWithHistory(rabbitSystemPrompt, fullHistory);
            rabbitMs[0] = (System.nanoTime() - t0) / 1_000_000;
            return json;
        });

        CompletableFuture<String> turtleFuture = CompletableFuture.supplyAsync(() -> {
            long t0 = System.nanoTime();
            String json = openAiService.askWithHistory(turtleSystemPrompt, fullHistory);
            turtleMs[0] = (System.nanoTime() - t0) / 1_000_000;
            return json;
        });

        // Wait for both to complete
        try {
            CompletableFuture.allOf(rabbitFuture, turtleFuture).join();
        } catch (CompletionException e) {
            if (e.getCause() instanceof MissionChatException mce) {
                throw mce;
            }
            log.error("Failed to execute parallel LLM calls", e);
            throw new MissionChatException(HttpStatus.BAD_GATEWAY, MissionChatException.MSG_AI_FAILED, e);
        }
        long totalMs = (System.nanoTime() - startNs) / 1_000_000;
        // Timing only (no content/keys): parallel total vs. each call, for the "parallel ~1.5s" claim
        log.info("Chat turn timing: total={}ms rabbit={}ms turtle={}ms (sequential would be ~{}ms) turn={}",
                totalMs, rabbitMs[0], turtleMs[0], rabbitMs[0] + turtleMs[0], currentUserTurns);
        ChatTurnResponseDto response = parseResponses(rabbitFuture.join(), turtleFuture.join());
        applyZoneRules(response, minTurns, currentUserTurns);
        return response;
    }

    static int effectiveMinTurns(MissionSetupResponseDto.MissionDto mission) {
        return mission.getMinTurns() > 0 ? mission.getMinTurns() : DEFAULT_MIN_TURNS;
    }

    /**
     * Enforces the 3-zone rule on top of the LLM's mission_status so the rule holds regardless of the model:
     * A (t < min-1): in_progress only · B (min-1..min+1): cleared or in_progress ·
     * C (t >= min+2): cleared or failed, and at maxTurns an unfinished mission becomes failed.
     */
    static void applyZoneRules(ChatTurnResponseDto response, int minTurns, int userTurn) {
        int maxTurns = minTurns + EXTRA_TURNS_BEFORE_STOP;
        String aiStatus = response.getMissionStatus();
        String zone;
        String status;
        if (userTurn < minTurns - 1) {
            zone = "A";
            status = "in_progress";
        } else if (userTurn <= minTurns + 1) {
            zone = "B";
            status = "cleared".equals(aiStatus) ? "cleared" : "in_progress";
        } else {
            zone = "C";
            status = aiStatus;
            if ("in_progress".equals(status) && userTurn >= maxTurns) {
                status = "failed";
            }
        }
        if (!status.equals(aiStatus)) {
            log.info("Mission status overridden by zone rule: zone={} turn={}/{} ai={} -> {}",
                    zone, userTurn, minTurns, aiStatus, status);
        }
        response.setMissionStatus(status);
        response.setUserTurn(userTurn);
        response.setMinTurns(minTurns);
        response.setMaxTurns(maxTurns);
        response.setZone(zone);
    }

    static boolean endsWithUserMessage(List<Map<String, String>> history, String userMessage) {
        if (history.isEmpty()) return false;
        Map<String, String> last = history.get(history.size() - 1);
        return "user".equals(last.get("role")) && userMessage.equals(last.get("content"));
    }

    static int countUserTurns(List<Map<String, String>> history) {
        return (int) history.stream().filter(m -> "user".equals(m.get("role"))).count();
    }

    private void validate(ChatTurnRequestDto request, MissionSetupResponseDto setup) {
        if (request.getUserMessage() == null || request.getUserMessage().isBlank()
                || setup == null || setup.getPersona() == null || setup.getMission() == null
                || setup.getMission().getClearCondition() == null) {
            throw MissionChatException.badRequest();
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

            String rabbitReply = nullableText(rabbitRoot, "rabbit_reply");
            if (rabbitReply == null || rabbitReply.isBlank() || !SEVERITIES.contains(correction.getSeverity())) {
                throw new IllegalStateException("Missing rabbit_reply or unknown severity");
            }
            String missionStatus = rabbitRoot.path("mission_status").asText("in_progress");
            if (!MISSION_STATUSES.contains(missionStatus)) {
                log.warn("Unknown mission_status from AI: {} -> in_progress", missionStatus);
                missionStatus = "in_progress";
            }

            return ChatTurnResponseDto.builder()
                    .rabbitReply(rabbitReply)
                    .rabbitReplyEn(nullableText(rabbitRoot, "rabbit_reply_en"))
                    .correction(correction)
                    .missionStatus(missionStatus)
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse ChatTurn responses. Rabbit: {}, Turtle: {}", rabbitJson, turtleJson);
            throw MissionChatException.badAiAnswer(e);
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
