package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class OpenAiService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${openai.api.key:}")
    private String openAiApiKey;

    @Value("${openai.api.model:gpt-4o}")
    private String modelName;

    private static final String OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";

    /**
     * Sends a request to OpenAI chat/completions with a system prompt and
     * multi-turn conversation history, expecting a JSON-format response.
     *
     * @param systemPrompt the system-level instruction for the model
     * @param history      list of {"role": "user"|"assistant", "content": "..."} maps
     * @return raw JSON string extracted from the model's response
     */
    public String askWithHistory(String systemPrompt, List<Map<String, String>> history) {
        if (openAiApiKey == null || openAiApiKey.isBlank()) {
            throw new IllegalStateException("OpenAI API key is not configured. Please set openai.api.key in application.yaml");
        }

        List<Map<String, String>> messages = new ArrayList<>();

        // System prompt is always first
        messages.add(Map.of("role", "system", "content", systemPrompt));

        // Append conversation history if provided
        if (history != null && !history.isEmpty()) {
            messages.addAll(history);
        }

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", modelName);
        requestBody.put("messages", messages);
        requestBody.put("response_format", Map.of("type", "json_object")); // Force JSON output

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(openAiApiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            log.info("Sending request to OpenAI API with model: {}", modelName);
            String rawResponse = restTemplate.postForObject(OPENAI_CHAT_URL, entity, String.class);
            return extractContent(rawResponse);
        } catch (Exception e) {
            log.error("Failed to fetch response from OpenAI API: {}", e.getMessage());
            throw new RuntimeException("OpenAI API call failed: " + e.getMessage(), e);
        }
    }

    /**
     * Extracts the text content from OpenAI's response JSON.
     * Path: choices[0].message.content
     */
    private String extractContent(String rawResponse) {
        try {
            JsonNode root = objectMapper.readTree(rawResponse);
            JsonNode content = root
                    .path("choices")
                    .get(0)
                    .path("message")
                    .path("content");
            if (content.isMissingNode()) {
                throw new RuntimeException("Unexpected OpenAI response structure: " + rawResponse);
            }
            return content.asText();
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse OpenAI response: " + e.getMessage(), e);
        }
    }
}
