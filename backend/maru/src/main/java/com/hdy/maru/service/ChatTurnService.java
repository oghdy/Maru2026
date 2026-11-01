package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.demo.DemoAiGate;
import com.hdy.maru.demo.DemoLimitException;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
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
    private static final String PRAISE_ALLOWED = """
            Allowed on this turn, but only if severity is "none" AND the message has something specific worth praising \
            (a natural phrase, a well chosen polite form, a sentence longer than it had to be). Name that expression. \
            Plain short answers such as 네, 아니요 or a word plus 주세요 are NOT worth praise: use null. Most messages get null.""";
    private static final String PRAISE_NOT_THIS_TURN = "Not on this turn: \"praise\" and \"praise_en\" must be null.";

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;

    @Autowired(required = false)
    private DemoAiGate demoAiGate = DemoAiGate.passThrough();

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
        MissionDifficulty difficulty = MissionDifficulty.from(demoAiGate.enforceDifficulty(setup.getDifficulty()));
        rabbitVars.put("difficulty_rules", difficulty.rabbitRules());
        List<String> steps = setup.getSteps() != null ? setup.getSteps() : List.of();
        List<Integer> previousSteps = validSteps(request.getCompletedSteps(), steps.size());
        rabbitVars.put("mission_steps", numberedSteps(steps));
        rabbitVars.put("completed_steps", previousSteps.isEmpty() ? "none" : previousSteps.toString());
        rabbitVars.put("turn_guidance", turnGuidance(minTurns, currentUserTurns) + openingReminder(fullHistory));
        String rabbitSystemPrompt = promptLoader.load("rabbit_reply_system.txt", rabbitVars);

        Map<String, String> turtleVars = new HashMap<>();
        turtleVars.put("persona_role", persona.getRole());
        turtleVars.put("persona_speech_style", persona.getSpeechStyle());
        turtleVars.put("persona_honorific_level", persona.getHonorificLevel());
        turtleVars.put("learner_speech_level", setup.getLearnerSpeechLevel() != null ? setup.getLearnerSpeechLevel()
                : "not given: work it out from the relationship between the learner and the persona");
        turtleVars.put("mission_description", mission.getDescription());
        boolean praiseAllowed = praiseAllowedOnTurn(currentUserTurns);
        turtleVars.put("praise_rule", praiseAllowed ? PRAISE_ALLOWED : PRAISE_NOT_THIS_TURN);
        turtleVars.put("difficulty_rules", difficulty.turtleRules());
        String turtleSystemPrompt = promptLoader.load("turtle_eval_system.txt", turtleVars);

        // Run both calls in parallel (elapsed ms recorded per call for the timing log)
        long startNs = System.nanoTime();
        long[] rabbitMs = {-1};
        long[] turtleMs = {-1};
        CompletableFuture<String> rabbitFuture = demoAiGate.supplyAsync(() -> {
            long t0 = System.nanoTime();
            String json = openAiService.askWithHistory(rabbitSystemPrompt, fullHistory);
            rabbitMs[0] = (System.nanoTime() - t0) / 1_000_000;
            return json;
        });

        CompletableFuture<String> turtleFuture = demoAiGate.supplyAsync(() -> {
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
            if (e.getCause() instanceof DemoLimitException limit) {
                throw limit;
            }
            log.error("Failed to execute parallel LLM calls", e);
            throw new MissionChatException(HttpStatus.BAD_GATEWAY, MissionChatException.MSG_AI_FAILED, e);
        }
        long totalMs = (System.nanoTime() - startNs) / 1_000_000;
        // Timing only (no content/keys): parallel total vs. each call, for the "parallel ~1.5s" claim
        log.info("Chat turn timing: total={}ms rabbit={}ms turtle={}ms (sequential would be ~{}ms) turn={}",
                totalMs, rabbitMs[0], turtleMs[0], rabbitMs[0] + turtleMs[0], currentUserTurns);
        String rabbitJson = fixRabbitReplyIfNeeded(rabbitFuture.join(), rabbitSystemPrompt, fullHistory, difficulty,
                currentUserTurns < minTurns);
        ChatTurnResponseDto response = parseResponses(rabbitJson, turtleFuture.join());
        applyZoneRules(response, minTurns, currentUserTurns);
        response.setCompletedSteps(mergeCompletedSteps(previousSteps, rabbitJson, steps.size()));
        applyPraiseRules(response, praiseAllowed);
        return response;
    }

    /**
     * What the rabbit must do on this exact turn. The server works the stage out, because low-effort models miscount
     * when they are given the zone arithmetic. Mirrors applyZoneRules, which still has the final say.
     */
    static String turnGuidance(int minTurns, int userTurn) {
        int maxTurns = minTurns + EXTRA_TURNS_BEFORE_STOP;
        if (userTurn < minTurns - 1) {
            return "KEEP TALKING. mission_status must be \"in_progress\", even if the goal is already met. "
                    + "No goodbye. Move the conversation forward with your next easy question.";
        }
        if (userTurn == minTurns - 1) {
            return "NEARLY TIME. mission_status must be \"in_progress\", even if the goal is already met. "
                    + "No goodbye yet. Ask something that leads toward finishing, and if the goal is not met yet, "
                    + "give the learner a natural chance to do it.";
        }
        if (userTurn >= maxTurns) {
            return "LAST TURN. The conversation ends now. mission_status must be \"cleared\" if the goal is met, "
                    + "otherwise \"failed\". Say a natural in-character closing line with no question.";
        }
        if (userTurn >= minTurns + 2) {
            return "LAST CHANCE. If the goal is met: mission_status \"cleared\" and a natural closing line with no question. "
                    + "If not: \"in_progress\" and ask a direct, easy question that lets the learner do it now. "
                    + "Use \"failed\" only if the learner has clearly given up on the goal.";
        }
        return "TIME TO FINISH IF YOU CAN. If the goal is met: mission_status \"cleared\" and a natural closing line with no question. "
                + "If not: \"in_progress\" and give the learner a natural chance to do it. Never \"failed\" on this turn.";
    }

    /** The rule in the prompt alone was not enough: replies kept opening with the same exclamation. */
    static String openingReminder(List<Map<String, String>> history) {
        for (int i = history.size() - 1; i >= 0; i--) {
            if ("assistant".equals(history.get(i).get("role"))) {
                String content = history.get(i).get("content");
                String first = content != null ? content.strip().split("\\s+")[0].replaceAll("[\\p{P}\\p{S}]+", "") : "";
                return first.isEmpty() ? "" : " Your last reply began with \"" + first + "\": begin this one with a different word.";
            }
        }
        return "";
    }

    private static String numberedSteps(List<String> steps) {
        if (steps.isEmpty()) return "(none)";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < steps.size(); i++) {
            sb.append(i + 1).append(". ").append(steps.get(i)).append('\n');
        }
        return sb.toString().stripTrailing();
    }

    /** Numbers inside 1..stepCount, without duplicates, in order. */
    static List<Integer> validSteps(Iterable<Integer> numbers, int stepCount) {
        TreeSet<Integer> valid = new TreeSet<>();
        if (numbers != null) {
            for (Integer n : numbers) {
                if (n != null && n >= 1 && n <= stepCount) valid.add(n);
            }
        }
        return List.copyOf(valid);
    }

    /** Finished steps stay finished: what the client sent back plus what the rabbit reports now. */
    private List<Integer> mergeCompletedSteps(List<Integer> previous, String rabbitJson, int stepCount) {
        List<Integer> merged = new ArrayList<>(previous);
        try {
            for (JsonNode n : objectMapper.readTree(rabbitJson).path("completed_steps")) {
                merged.add(n.asInt(0));
            }
        } catch (Exception e) {
            log.warn("Could not read completed_steps: {}", e.getMessage());
        }
        return validSteps(merged, stepCount);
    }

    /**
     * Keeps praise rare although the stateless turtle cannot remember earlier turns: every other turn at most,
     * and never next to a correction.
     */
    static boolean praiseAllowedOnTurn(int userTurn) {
        return userTurn % 2 == 0;
    }

    private static void applyPraiseRules(ChatTurnResponseDto response, boolean praiseAllowed) {
        if (!praiseAllowed || !"none".equals(response.getCorrection().getSeverity()) || response.getPraise() == null) {
            response.setPraise(null);
            response.setPraiseEn(null);
        }
    }

    /**
     * Asks the rabbit once more (at most one extra call per turn) when the reply is clearly over the length limit
     * or says goodbye before the minimum turns; the server would keep the mission open and the learner would be left
     * with a farewell. Never truncates: a cut sentence is worse.
     */
    private String fixRabbitReplyIfNeeded(String rabbitJson, String systemPrompt, List<Map<String, String>> history,
                                          MissionDifficulty difficulty, boolean beforeMinTurns) {
        String reply;
        boolean endedEarly;
        try {
            JsonNode root = objectMapper.readTree(rabbitJson);
            reply = nullableText(root, "rabbit_reply");
            String status = nullableText(root, "mission_status");
            endedEarly = beforeMinTurns && status != null && !"in_progress".equals(status);
        } catch (Exception e) {
            return rabbitJson; // parseResponses reports the broken JSON
        }
        boolean tooLong = difficulty.isRabbitReplyTooLong(reply);
        if (!tooLong && !endedEarly) {
            return rabbitJson;
        }
        int length = reply != null ? MissionDifficulty.countChars(reply) : 0;
        StringBuilder retryPrompt = new StringBuilder(systemPrompt);
        if (endedEarly) {
            retryPrompt.append("\n\n=== EARLY ENDING FIX (IMPORTANT) ===\nYou ended the conversation too early. ")
                    .append("Rewrite your reply so it continues the conversation with a question and no goodbye. ")
                    .append("mission_status must be \"in_progress\".");
        }
        if (tooLong) {
            retryPrompt.append("\n\n=== LENGTH FIX (IMPORTANT) ===\nYour reply was too long (").append(length)
                    .append(" characters). Rewrite it as a much shorter reply: at most ").append(difficulty.rabbitMaxChars())
                    .append(" Korean characters (spaces not counted). Keep the same meaning")
                    .append(endedEarly ? "." : " and mission_status.");
        }
        try {
            long t0 = System.nanoTime();
            String retryJson = openAiService.askWithHistory(retryPrompt.toString(), history);
            JsonNode retryRoot = objectMapper.readTree(retryJson);
            String retryReply = nullableText(retryRoot, "rabbit_reply");
            int retryLength = retryReply != null && !retryReply.isBlank() ? MissionDifficulty.countChars(retryReply) : Integer.MAX_VALUE;
            log.info("Rabbit reply retried in {}ms: tooLong={} ({} -> {} chars, limit {} {}) endedEarly={}",
                    (System.nanoTime() - t0) / 1_000_000, tooLong, length, retryLength,
                    difficulty.rabbitMaxChars(), difficulty.apiValue(), endedEarly);
            if (retryLength == Integer.MAX_VALUE) {
                return rabbitJson;
            }
            return endedEarly || retryLength < length ? retryJson : rabbitJson;
        } catch (Exception e) {
            log.warn("Rabbit retry failed, keeping the first reply: {}", e.getMessage());
            return rabbitJson;
        }
    }

    static int effectiveMinTurns(MissionSetupResponseDto.MissionDto mission) {
        return mission.getMinTurns() > 0 ? mission.getMinTurns() : DEFAULT_MIN_TURNS;
    }

    /**
     * Enforces the 3-zone rule on top of the LLM's mission_status so the rule holds regardless of the model:
     * A (t < min): in_progress only · B (min..min+1): cleared or in_progress ·
     * C (t >= min+2): cleared or failed, and at maxTurns an unfinished mission becomes failed.
     */
    static void applyZoneRules(ChatTurnResponseDto response, int minTurns, int userTurn) {
        int maxTurns = minTurns + EXTRA_TURNS_BEFORE_STOP;
        String aiStatus = response.getMissionStatus();
        String zone;
        String status;
        if (userTurn < minTurns) { // web-demo change: no clear before the minimum turns (web-demo/API_CONTRACT.md)
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
                    .severity(orDefault(nullableText(turtleRoot, "severity"), "none"))
                    .issueType(orDefault(nullableText(turtleRoot, "issue_type"), "none"))
                    .userInputProblematic(nullableText(turtleRoot, "user_input_problematic"))
                    .correctExpression(nullableText(turtleRoot, "correct_expression"))
                    .turtleFeedback(nullableText(turtleRoot, "turtle_feedback"))
                    .turtleFeedbackEn(nullableText(turtleRoot, "turtle_feedback_en"))
                    .build();

            // A correction with nothing to show would block the learner without guidance → treat as no issue
            if (!"none".equals(correction.getSeverity())
                    && correction.getCorrectExpression() == null && correction.getTurtleFeedback() == null) {
                log.warn("Turtle returned severity={} without correction/feedback -> none", correction.getSeverity());
                correction.setSeverity("none");
                correction.setIssueType("none");
                correction.setUserInputProblematic(null);
                correction.setTurtleFeedbackEn(null);
            }

            String rabbitReply = nullableText(rabbitRoot, "rabbit_reply");
            if (rabbitReply == null || rabbitReply.isBlank() || !SEVERITIES.contains(correction.getSeverity())) {
                throw new IllegalStateException("Missing rabbit_reply or unknown severity");
            }
            String missionStatus = orDefault(nullableText(rabbitRoot, "mission_status"), "in_progress");
            if (!MISSION_STATUSES.contains(missionStatus)) {
                log.warn("Unknown mission_status from AI: {} -> in_progress", missionStatus);
                missionStatus = "in_progress";
            }

            return ChatTurnResponseDto.builder()
                    .rabbitReply(rabbitReply)
                    .rabbitReplyEn(nullableText(rabbitRoot, "rabbit_reply_en"))
                    .correction(correction)
                    .missionStatus(missionStatus)
                    .praise(nullableText(turtleRoot, "praise"))
                    .praiseEn(nullableText(turtleRoot, "praise_en"))
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse ChatTurn responses. Rabbit: {}, Turtle: {}", rabbitJson, turtleJson);
            throw MissionChatException.badAiAnswer(e);
        }
    }

    /**
     * Text field or null. The model sometimes writes the STRING "null" (or "") instead of JSON null — normalize those.
     */
    private static String orDefault(String value, String fallback) {
        return value != null ? value : fallback;
    }

    static String nullableText(JsonNode node, String fieldName) {
        JsonNode field = node.path(fieldName);
        if (field.isNull() || field.isMissingNode()) {
            return null;
        }
        String text = field.asText().trim();
        if (text.isEmpty() || text.equalsIgnoreCase("null") || text.equalsIgnoreCase("none")) {
            return null;
        }
        return text;
    }
}
