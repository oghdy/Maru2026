package com.hdy.maru.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.net.SocketTimeoutException;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeminiService {

    // Server gives up before the app's 60s receive timeout so the user gets a clear message
    static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);
    static final Duration READ_TIMEOUT = Duration.ofSeconds(40);

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api.key:dummy}")
    private String geminiApiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent}")
    private String geminiApiUrl;

    /**
     * Uses its own RestTemplate with timeouts (the shared bean has none).
     */
    @Autowired
    public GeminiService(RestTemplateBuilder restTemplateBuilder, ObjectMapper objectMapper) {
        this(restTemplateBuilder.connectTimeout(CONNECT_TIMEOUT).readTimeout(READ_TIMEOUT).build(), objectMapper);
    }

    GeminiService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * Sends a prompt (instruction) to Gemini API and returns the raw JSON string
     * response
     */
    public String askGemini(String prompt) {
        // Gemini API Request Body Specification
        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> parts = new HashMap<>();
        parts.put("text", prompt);

        Map<String, Object> contents = new HashMap<>();
        contents.put("parts", List.of(parts));

        requestBody.put("contents", List.of(contents));
        // Ask for raw JSON so the reply is not wrapped in markdown or prose
        requestBody.put("generationConfig", Map.of("responseMimeType", "application/json"));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        // Key goes in a header, not the URL query string, so it never shows up in URLs or error messages
        headers.set("x-goog-api-key", geminiApiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        String rawResponse;
        long start = System.nanoTime();
        try {
            log.info("Sending request to Gemini API...");
            rawResponse = restTemplate.postForObject(geminiApiUrl, entity, String.class);
            log.info("Gemini API responded in {}ms", (System.nanoTime() - start) / 1_000_000);
        } catch (ResourceAccessException e) {
            // Only log the cause type; the full message is not needed for users
            // JDK HttpClient (Boot default) -> HttpTimeoutException, others -> SocketTimeoutException
            if (e.getCause() instanceof SocketTimeoutException || e.getCause() instanceof HttpTimeoutException) {
                log.warn("Gemini API timed out");
                throw new GeminiException(GeminiException.Reason.TIMEOUT, "Gemini API timed out");
            }
            log.warn("Gemini API unreachable: {}", e.getCause() == null ? "-" : e.getCause().getClass().getSimpleName());
            throw new GeminiException(GeminiException.Reason.UNAVAILABLE, "Gemini API unreachable");
        } catch (RestClientResponseException e) {
            log.warn("Gemini API returned HTTP {}", e.getStatusCode().value());
            throw new GeminiException(GeminiException.Reason.UNAVAILABLE, "Gemini API HTTP " + e.getStatusCode().value());
        } catch (RuntimeException e) {
            log.warn("Gemini API call failed: {}", e.getClass().getSimpleName());
            throw new GeminiException(GeminiException.Reason.UNAVAILABLE, "Gemini API call failed");
        }
        return extractTextFromGeminiResponse(rawResponse);
    }

    /**
     * Extracts the raw assistant message text from the Gemini JSON response wrapper
     */
    private String extractTextFromGeminiResponse(String responseJson) {
        JsonNode root;
        try {
            root = objectMapper.readTree(responseJson == null ? "" : responseJson);
        } catch (JsonProcessingException e) {
            throw new GeminiException(GeminiException.Reason.BAD_RESPONSE, "Gemini response is not JSON");
        }
        // The path in Gemini response is typically: candidates[0].content.parts[0].text
        JsonNode candidate = root.path("candidates").path(0);
        JsonNode textNode = candidate.path("content").path("parts").path(0).path("text");
        if (!textNode.isTextual() || textNode.asText().isBlank()) {
            // e.g. blocked by safety filters: no content, only finishReason / promptFeedback
            log.warn("Gemini response has no text (finishReason={}, blockReason={})",
                    candidate.path("finishReason").asText("-"),
                    root.path("promptFeedback").path("blockReason").asText("-"));
            throw new GeminiException(GeminiException.Reason.BAD_RESPONSE, "Gemini response has no text");
        }
        return textNode.asText();
    }

    /**
     * Gemini call failure. The message is for logs only, not for users.
     */
    @Getter
    public static class GeminiException extends RuntimeException {
        public enum Reason { TIMEOUT, UNAVAILABLE, BAD_RESPONSE }

        private final Reason reason;

        public GeminiException(Reason reason, String message) {
            super(message);
            this.reason = reason;
        }
    }
}
