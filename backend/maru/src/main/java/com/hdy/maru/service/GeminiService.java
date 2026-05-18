package com.hdy.maru.service;

import com.fasterxml.jackson.core.JsonProcessingException;
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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api.key:dummy}")
    private String geminiApiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent}")
    private String geminiApiUrl;

    /**
     * Sends a prompt (instruction) to Gemini API and returns the raw JSON string
     * response
     */
    public String askGemini(String prompt) {
        String urlWithKey = geminiApiUrl + "?key=" + geminiApiKey;

        // Gemini API Request Body Specification
        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> parts = new HashMap<>();
        parts.put("text", prompt);

        Map<String, Object> contents = new HashMap<>();
        contents.put("parts", List.of(parts));

        requestBody.put("contents", List.of(contents));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            log.info("Sending request to Gemini API...");
            String rawResponse = restTemplate.postForObject(urlWithKey, entity, String.class);
            return extractTextFromGeminiResponse(rawResponse);
        } catch (Exception e) {
            log.error("Failed to fetch response from Gemini API", e);
            throw new RuntimeException("AI Transformation failed: " + e.getMessage());
        }
    }

    /**
     * Extracts the raw assistant message text from the Gemini JSON response wrapper
     */
    private String extractTextFromGeminiResponse(String responseJson) throws JsonProcessingException {
        JsonNode root = objectMapper.readTree(responseJson);
        // The path in Gemini response is typically: candidates[0].content.parts[0].text
        JsonNode candidates = root.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode textNode = candidates.get(0)
                    .path("content")
                    .path("parts")
                    .get(0)
                    .path("text");
            return textNode.asText();
        }
        throw new RuntimeException("Invalid Gemini API Response structure");
    }
}
