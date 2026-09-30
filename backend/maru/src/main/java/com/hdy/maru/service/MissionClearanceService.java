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

import java.util.ArrayList;
import java.util.List;
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
            List<Map<String, String>> conversationHistory) {

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
        java.util.Map<String, String> promptVars = new java.util.HashMap<>();
        promptVars.put("mission_title", mission.getTitle() != null ? mission.getTitle() : "");
        promptVars.put("persona_role", persona.getRole() != null ? persona.getRole() : "");
        promptVars.put("total_turns", String.valueOf(totalTurns));

        String systemPrompt = promptLoader.load("clearance_system.txt", promptVars);

        // The conversation history is the user context
        List<Map<String, String>> safeHistory = conversationHistory != null ? conversationHistory : new ArrayList<>();
        String rawJson = openAiService.askWithHistory(systemPrompt, safeHistory);

        return parseAndSave(rawJson, user, mission.getTitle(), persona.getRole(), totalTurns);
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

    private MissionClearanceResponseDto parseAndSave(String rawJson, User user,
                                                      String missionTitle, String personaRole, int totalTurns) {
        JsonNode root;
        try {
            root = objectMapper.readTree(rawJson).path("certificate");
            if (!root.isObject()) {
                throw new IllegalStateException("Missing certificate object");
            }
        } catch (Exception e) {
            log.error("Failed to parse Clearance response: {}", rawJson);
            throw MissionChatException.badAiAnswer(e);
        }

        // Parse good_expressions: [{"expression":"...", "reason":"..."}]
        List<Map<String, String>> goodExpressions = new ArrayList<>();
        for (JsonNode item : root.path("good_expressions")) {
            goodExpressions.add(Map.of(
                    "expression", item.path("expression").asText(""),
                    "reason", item.path("reason").asText("")
            ));
        }

        // Parse incorrect_expressions: [{"wrong":"...", "correct":"...", "explanation":"..."}]
        List<Map<String, String>> incorrectExpressions = new ArrayList<>();
        for (JsonNode item : root.path("incorrect_expressions")) {
            incorrectExpressions.add(Map.of(
                    "wrong", item.path("wrong").asText(""),
                    "correct", item.path("correct").asText(""),
                    "explanation", item.path("explanation").asText("")
            ));
        }

        // Save to DB
        MissionClearance entity = new MissionClearance();
        entity.setUser(user);
        entity.setMissionTitle(missionTitle);
        entity.setPersona(personaRole);
        entity.setTotalTurns(totalTurns);
        entity.setGoodExpressions(goodExpressions);
        entity.setIncorrectExpressions(incorrectExpressions);
        entity.setTurtleComment(root.path("turtle_comment").asText(""));
        entity.setNextPractice(root.path("next_practice").asText(""));

        MissionClearance saved = clearanceRepository.save(entity);
        return MissionClearanceResponseDto.fromEntity(saved);
    }

    private int countUserTurns(List<Map<String, String>> history) {
        if (history == null) return 0;
        return (int) history.stream()
                .filter(msg -> "user".equals(msg.get("role")))
                .count();
    }
}
