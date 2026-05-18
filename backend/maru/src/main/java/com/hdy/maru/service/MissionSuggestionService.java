package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.SuggestionRequestDto;
import com.hdy.maru.dto.SuggestionResponseDto;
import com.hdy.maru.util.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class MissionSuggestionService {

    private final OpenAiService openAiService;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;

    public SuggestionResponseDto getSuggestions(SuggestionRequestDto request) {
        if (request.getSetup() == null || request.getSetup().getMission() == null) {
            throw new IllegalArgumentException("Mission setup is missing.");
        }

        Map<String, String> variables = new HashMap<>();
        variables.put("mission_title", request.getSetup().getMission().getTitle() != null ? request.getSetup().getMission().getTitle() : "");
        variables.put("mission_description", request.getSetup().getMission().getDescription() != null ? request.getSetup().getMission().getDescription() : "");
        variables.put("mission_goal_condition", request.getSetup().getMission().getClearCondition().getGoalCondition() != null ? request.getSetup().getMission().getClearCondition().getGoalCondition() : "");
        variables.put("mission_language_condition", request.getSetup().getMission().getClearCondition().getLanguageCondition() != null ? request.getSetup().getMission().getClearCondition().getLanguageCondition() : "");

        String systemPrompt = promptLoader.load("turtle_suggestion_system.txt", variables);

        // Pass conversation history list directly
        List<Map<String, String>> history = request.getConversationHistory();

        String rawJson = openAiService.askWithHistory(systemPrompt, history);

        try {
            return objectMapper.readValue(rawJson, SuggestionResponseDto.class);
        } catch (Exception e) {
            log.error("Failed to parse suggestion response: {}", rawJson);
            throw new RuntimeException("Failed to parse suggestion response", e);
        }
    }
}
