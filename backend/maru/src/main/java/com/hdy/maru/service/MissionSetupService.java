package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.MissionSetupRequestDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class MissionSetupService {

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;

    /**
     * Generates a persona and mission based on user-selected settings.
     * Calls LLM Call #1.
     */
    public MissionSetupResponseDto generateMission(MissionSetupRequestDto request) {
        if (request == null || isBlank(request.getHierarchy()) || isBlank(request.getIntimacy())) {
            throw new MissionChatException(HttpStatus.BAD_REQUEST, "Please choose the relationship and how close you are.");
        }
        MissionDifficulty difficulty = MissionDifficulty.from(request.getDifficulty());
        // Build the system prompt with variable substitution
        String systemPrompt = promptLoader.load("mission_setup_system.txt", Map.of(
                "hierarchy", request.getHierarchy(),
                "intimacy", request.getIntimacy(),
                "role", !isBlank(request.getRole()) ? request.getRole() : "any role",
                "personality", !isBlank(request.getPersonality()) ? request.getPersonality() : "natural",
                "difficulty", difficulty.apiValue(),
                "difficulty_rules", difficulty.setupRules()
        ));

        // Call OpenAI with no prior history (this is the first call)
        String rawJson = openAiService.askWithHistory(systemPrompt, null);

        return parseResponse(rawJson, difficulty);
    }

    private MissionSetupResponseDto parseResponse(String rawJson, MissionDifficulty difficulty) {
        try {
            JsonNode root = objectMapper.readTree(rawJson);

            JsonNode personaNode = root.path("persona");
            JsonNode missionNode = root.path("mission");
            JsonNode clearCondNode = missionNode.path("clear_condition");

            MissionSetupResponseDto.PersonaDto persona = MissionSetupResponseDto.PersonaDto.builder()
                    .role(personaNode.path("role").asText())
                    .personality(personaNode.path("personality").asText())
                    .speechStyle(personaNode.path("speech_style").asText())
                    .honorificLevel(personaNode.path("honorific_level").asText())
                    .firstMessage(personaNode.path("first_message").asText())
                    .firstMessageEn(personaNode.path("first_message_en").asText())
                    .build();

            MissionSetupResponseDto.MissionDto.ClearConditionDto clearCondition =
                    MissionSetupResponseDto.MissionDto.ClearConditionDto.builder()
                            .goalCondition(clearCondNode.path("goal_condition").asText())
                            .languageCondition(clearCondNode.path("language_condition").asText())
                            .build();

            MissionSetupResponseDto.MissionDto mission = MissionSetupResponseDto.MissionDto.builder()
                    .title(missionNode.path("title").asText())
                    .description(missionNode.path("description").asText())
                    .clearCondition(clearCondition)
                    .minTurns(difficulty.clampMinTurns(missionNode.path("min_turns").asInt(0)))
                    .build();

            String adjustmentNotice = ChatTurnService.nullableText(root, "adjustment_notice");

            if (isBlank(persona.getFirstMessage()) || isBlank(mission.getTitle())
                    || isBlank(clearCondition.getGoalCondition())) {
                throw new IllegalStateException("Missing first_message, title or goal_condition");
            }

            return MissionSetupResponseDto.builder()
                    .persona(persona)
                    .mission(mission)
                    .adjustmentNotice(adjustmentNotice)
                    .difficulty(difficulty.apiValue())
                    .build();

        } catch (Exception e) {
            log.error("Failed to parse MissionSetup response: {}", rawJson);
            throw MissionChatException.badAiAnswer(e);
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
