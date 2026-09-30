package com.hdy.maru.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class OpenAiService {

    private static final int CONNECT_TIMEOUT_MS = 5_000;
    private static final int READ_TIMEOUT_MS = 30_000;

    // Own RestTemplate with timeouts (the shared bean in config has none)
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public OpenAiService(ObjectMapper objectMapper) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(CONNECT_TIMEOUT_MS);
        factory.setReadTimeout(READ_TIMEOUT_MS);
        this.restTemplate = new RestTemplate(factory);
        this.objectMapper = objectMapper;
    }

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
     * @throws MissionChatException with a user-facing message on key/timeout/API/response errors
     */
    public String askWithHistory(String systemPrompt, List<Map<String, String>> history) {
        if (openAiApiKey == null || openAiApiKey.isBlank()) {
            log.error("OpenAI API key is not configured (openai.api.key)");
            throw new MissionChatException(HttpStatus.SERVICE_UNAVAILABLE, MissionChatException.MSG_AI_UNAVAILABLE);
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

        String rawResponse;
        try {
            long t0 = System.nanoTime();
            rawResponse = restTemplate.postForObject(OPENAI_CHAT_URL, entity, String.class);
            log.info("OpenAI call ({}) took {}ms", modelName, (System.nanoTime() - t0) / 1_000_000);
        } catch (ResourceAccessException e) {
            // I/O errors incl. connect/read timeouts
            log.error("OpenAI API not reachable or timed out: {}", e.getMessage());
            throw new MissionChatException(HttpStatus.GATEWAY_TIMEOUT, MissionChatException.MSG_AI_TIMEOUT, e);
        } catch (RestClientResponseException e) {
            log.error("OpenAI API returned HTTP {}", e.getStatusCode().value());
            throw new MissionChatException(HttpStatus.BAD_GATEWAY, MissionChatException.MSG_AI_FAILED, e);
        } catch (Exception e) {
            log.error("OpenAI API call failed: {}", e.getMessage());
            throw new MissionChatException(HttpStatus.BAD_GATEWAY, MissionChatException.MSG_AI_FAILED, e);
        }
        return extractContent(rawResponse);
    }

    /**
     * Extracts the text content from OpenAI's response JSON.
     * Path: choices[0].message.content
     */
    private String extractContent(String rawResponse) {
        JsonNode content;
        try {
            content = objectMapper.readTree(rawResponse)
                    .path("choices")
                    .path(0)
                    .path("message")
                    .path("content");
        } catch (Exception e) {
            log.error("Failed to parse OpenAI response envelope: {}", e.getMessage());
            throw MissionChatException.badAiAnswer(e);
        }
        if (!content.isTextual() || content.asText().isBlank()) {
            log.error("Unexpected OpenAI response structure (no choices[0].message.content)");
            throw MissionChatException.badAiAnswer(null);
        }
        return content.asText();
    }
}
