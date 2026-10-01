package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.MissionClearanceResponseDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.entity.MissionClearance;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.MissionClearanceRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class MissionClearanceService {

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;
    private final MissionClearanceRepository clearanceRepository;
    private final UserRepository userRepository;

    /**
     * Issues a mission clearance certificate by calling LLM #3,
     * then saves it to DB and returns the DTO.
     */
    @Transactional
    public MissionClearanceResponseDto issueClearance(
            String oauthId,
            MissionSetupResponseDto setup,
            List<Map<String, String>> conversationHistory,
            String liveStatus) {

        if (setup == null || setup.getPersona() == null || setup.getMission() == null
                || setup.getMission().getTitle() == null || setup.getPersona().getRole() == null) {
            throw MissionChatException.badRequest();
        }
        // Look up the user before the (paid) AI call
        User user = findUser(oauthId);

        MissionSetupResponseDto.PersonaDto persona = setup.getPersona();
        MissionSetupResponseDto.MissionDto mission = setup.getMission();
        int totalTurns = countUserTurns(conversationHistory);

        // Build system prompt for clearance (use safe string conversions to avoid NPE)
        Map<String, String> promptVars = new HashMap<>();
        promptVars.put("mission_title", mission.getTitle() != null ? mission.getTitle() : "");
        promptVars.put("persona_role", persona.getRole() != null ? persona.getRole() : "");
        promptVars.put("total_turns", String.valueOf(totalTurns));
        promptVars.put("mission_description", nz(mission.getDescription()));
        promptVars.put("mission_goal_condition", goalCondition(mission));
        promptVars.put("mission_language_condition",
                mission.getClearCondition() != null ? nz(mission.getClearCondition().getLanguageCondition()) : "");
        int minTurns = ChatTurnService.effectiveMinTurns(mission);
        promptVars.put("mission_min_turns", String.valueOf(minTurns));
        promptVars.put("live_status", liveStatus != null && !liveStatus.isBlank() ? liveStatus : "unknown");
        List<String> userSentences = userSentences(conversationHistory);
        promptVars.put("student_messages", numberedList(userSentences));

        String systemPrompt = promptLoader.load("clearance_system.txt", promptVars);

        // The conversation history is the user context
        List<Map<String, String>> safeHistory = conversationHistory != null ? conversationHistory : new ArrayList<>();
        String rawJson = openAiService.askWithHistory(systemPrompt, safeHistory);

        return parseAndSave(rawJson, user, mission, persona.getRole(), totalTurns, minTurns, userSentences);
    }

    @Transactional(readOnly = true)
    public List<MissionClearanceResponseDto> getUserClearances(String oauthId) {
        User user = findUser(oauthId);
        return clearanceRepository.findByUserIdOrderByClearedAtDesc(user.getId())
                .stream()
                .map(MissionClearanceResponseDto::fromEntity)
                .toList();
    }

    private User findUser(String oauthId) {
        return userRepository.findByOauthId(oauthId)
                .orElseThrow(() -> new MissionChatException(HttpStatus.NOT_FOUND, MissionChatException.MSG_USER_NOT_FOUND));
    }

    private static String nz(String s) {
        return s != null ? s : "";
    }

    private static String goalCondition(MissionSetupResponseDto.MissionDto mission) {
        return mission.getClearCondition() != null ? nz(mission.getClearCondition().getGoalCondition()) : "";
    }

    /**
     * Final result: the coach AI's judgment, but never cleared before the judgment window (min-1 turns).
     */
    static boolean decideCleared(String aiResult, int totalTurns, int minTurns) {
        return "cleared".equals(aiResult) && totalTurns >= minTurns - 1;
    }

    private MissionClearanceResponseDto parseAndSave(String rawJson, User user,
                                                      MissionSetupResponseDto.MissionDto mission, String personaRole,
                                                      int totalTurns, int minTurns, List<String> userSentences) {
        JsonNode root;
        String aiResult;
        try {
            root = objectMapper.readTree(rawJson).path("certificate");
            aiResult = root.path("result").asText("");
            if (!root.isObject() || !(aiResult.equals("cleared") || aiResult.equals("not_cleared"))) {
                throw new IllegalStateException("Missing certificate object or result");
            }
        } catch (Exception e) {
            log.error("Failed to parse Clearance response: {}", rawJson);
            throw MissionChatException.badAiAnswer(e);
        }

        // Parse good_expressions: [{"expression":"...", "reason":"..."}]
        List<Map<String, String>> goodExpressions = new ArrayList<>();
        for (JsonNode item : root.path("good_expressions")) {
            if (!isQuotedFromUser(item.path("expression").asText(""), userSentences)) {
                log.info("Dropped good_expression not said by the user");
                continue;
            }
            goodExpressions.add(Map.of(
                    "expression", item.path("expression").asText(""),
                    "reason", item.path("reason").asText("")
            ));
        }

        // Parse incorrect_expressions: [{"wrong":"...", "correct":"...", "explanation":"..."}]
        List<Map<String, String>> incorrectExpressions = new ArrayList<>();
        for (JsonNode item : root.path("incorrect_expressions")) {
            if (!isQuotedFromUser(item.path("wrong").asText(""), userSentences)) {
                log.info("Dropped incorrect_expression not said by the user");
                continue;
            }
            incorrectExpressions.add(Map.of(
                    "wrong", item.path("wrong").asText(""),
                    "correct", item.path("correct").asText(""),
                    "explanation", item.path("explanation").asText("")
            ));
        }

        boolean cleared = decideCleared(aiResult, totalTurns, minTurns);
        String resultReason = ChatTurnService.nullableText(root, "result_reason");
        if ("cleared".equals(aiResult) && !cleared) {
            log.info("Clearance overridden: AI said cleared but only {} turns (min {})", totalTurns, minTurns);
            resultReason = "You ended the conversation before reaching the mission goal.";
        }

        // Save to DB
        MissionClearance entity = new MissionClearance();
        entity.setUser(user);
        entity.setMissionTitle(mission.getTitle());
        entity.setCleared(cleared);
        entity.setResultReason(resultReason);
        entity.setGoalCondition(goalCondition(mission));
        entity.setPersona(personaRole);
        entity.setTotalTurns(totalTurns);
        entity.setGoodExpressions(goodExpressions);
        entity.setIncorrectExpressions(incorrectExpressions);
        entity.setTurtleComment(root.path("turtle_comment").asText(""));
        entity.setNextPractice(root.path("next_practice").asText(""));

        MissionClearance saved = clearanceRepository.save(entity);
        return MissionClearanceResponseDto.fromEntity(saved);
    }

    /** The learner's own messages (role=user), trimmed, blanks skipped — the only quotable sentences. */
    static List<String> userSentences(List<Map<String, String>> history) {
        if (history == null) return List.of();
        return history.stream()
                .filter(msg -> msg != null && "user".equals(msg.get("role")))
                .map(msg -> msg.get("content"))
                .filter(c -> c != null && !c.isBlank())
                .map(String::strip)
                .toList();
    }

    private static String numberedList(List<String> sentences) {
        if (sentences.isEmpty()) return "(none)";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < sentences.size(); i++) {
            sb.append(i + 1).append(". ").append(sentences.get(i)).append('\n');
        }
        return sb.toString().stripTrailing();
    }

    /** Lowercase, NFC, and strip whitespace/punctuation/symbols so "커피 주세요!" matches "커피주세요". */
    static String normalizeForMatch(String s) {
        if (s == null) return "";
        return Normalizer.normalize(s, Normalizer.Form.NFC)
                .replaceAll("[\\s\\p{Z}\\p{P}\\p{S}]+", "")
                .toLowerCase(Locale.ROOT);
    }

    /** True when the quoted expression appears (normalized) inside one of the learner's own messages. */
    static boolean isQuotedFromUser(String quote, List<String> userSentences) {
        String q = normalizeForMatch(quote);
        if (q.isEmpty()) return false;
        return userSentences.stream().anyMatch(u -> normalizeForMatch(u).contains(q));
    }

    private int countUserTurns(List<Map<String, String>> history) {
        if (history == null) return 0;
        return (int) history.stream()
                .filter(msg -> "user".equals(msg.get("role")))
                .count();
    }
}
