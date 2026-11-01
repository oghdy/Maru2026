package com.hdy.maru.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.demo.DemoAiGate;
import com.hdy.maru.dto.MissionScenarioDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Ready-made scenario cards. Starting one builds the same setup object as the AI does, with no AI call:
 * steady quality and no cost. It still counts as a mission start in the demo. A broken data file stops the server at
 * startup instead of failing in front of a visitor.
 */
@Service
public class MissionScenarioService {

    static final String MSG_UNKNOWN_SCENARIO = "That scenario isn't available. Please choose another one.";
    private static final String DATA_FILE = "scenarios/mission_scenarios.json";

    private final Map<String, MissionScenarioDto> scenarios = new LinkedHashMap<>();

    @Autowired(required = false)
    private DemoAiGate demoAiGate = DemoAiGate.passThrough();

    public MissionScenarioService(ObjectMapper objectMapper) {
        try (InputStream in = new ClassPathResource(DATA_FILE).getInputStream()) {
            for (MissionScenarioDto scenario : objectMapper.readValue(in, new TypeReference<List<MissionScenarioDto>>() { })) {
                validate(scenario);
                if (scenarios.put(scenario.getId(), scenario) != null) {
                    throw new IllegalStateException("Duplicate scenario id: " + scenario.getId());
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + DATA_FILE, e);
        }
    }

    private static void validate(MissionScenarioDto scenario) {
        for (MissionDifficulty difficulty : MissionDifficulty.values()) {
            MissionScenarioDto.Level level = scenario.getLevels() != null ? scenario.getLevels().get(difficulty.apiValue()) : null;
            String where = "Scenario " + scenario.getId() + " " + difficulty.apiValue();
            if (level == null || isBlank(level.getFirstMessage()) || isBlank(level.getMissionTitle())
                    || isBlank(level.getGoalCondition()) || level.getSteps() == null || level.getSteps().size() < 2) {
                throw new IllegalStateException(where + " is incomplete");
            }
            if (difficulty.clampMinTurns(level.getMinTurns()) != level.getMinTurns()) {
                throw new IllegalStateException(where + " has minTurns outside its range");
            }
        }
    }

    public List<MissionScenarioDto> list() {
        return List.copyOf(scenarios.values());
    }

    /** Builds the setup for a card. Unknown id: 400 and no mission counted. */
    public MissionSetupResponseDto startMission(String scenarioId, String requestedDifficulty) {
        MissionScenarioDto scenario = scenarios.get(scenarioId);
        if (scenario == null) {
            throw new MissionChatException(HttpStatus.BAD_REQUEST, MSG_UNKNOWN_SCENARIO);
        }
        MissionDifficulty difficulty = MissionDifficulty.from(demoAiGate.enforceDifficulty(requestedDifficulty));
        demoAiGate.reserveMissionStart();

        MissionScenarioDto.Level level = scenario.getLevels().get(difficulty.apiValue());
        return MissionSetupResponseDto.builder()
                .persona(MissionSetupResponseDto.PersonaDto.builder()
                        .role(scenario.getRole())
                        .personality(scenario.getPersonality())
                        .speechStyle(scenario.getSpeechStyle())
                        .honorificLevel(scenario.getHonorificLevel())
                        .firstMessage(level.getFirstMessage())
                        .firstMessageEn(level.getFirstMessageEn())
                        .build())
                .mission(MissionSetupResponseDto.MissionDto.builder()
                        .title(level.getMissionTitle())
                        .description(level.getMissionDescription())
                        .clearCondition(MissionSetupResponseDto.MissionDto.ClearConditionDto.builder()
                                .goalCondition(level.getGoalCondition())
                                .languageCondition(level.getLanguageCondition())
                                .build())
                        .minTurns(level.getMinTurns())
                        .build())
                .difficulty(difficulty.apiValue())
                .steps(level.getSteps())
                .learnerSpeechLevel(scenario.getLearnerSpeechLevel())
                .scenarioId(scenario.getId())
                .build();
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
