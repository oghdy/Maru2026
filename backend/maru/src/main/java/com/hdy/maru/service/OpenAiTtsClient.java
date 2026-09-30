package com.hdy.maru.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/** OpenAI /v1/audio/speech 호출만 담당 (미션의 OpenAiService 와 분리). */
@Slf4j
@Component
public class OpenAiTtsClient {

    private static final String URL = "https://api.openai.com/v1/audio/speech";

    private final RestTemplate restTemplate;

    @Value("${openai.api.key:}")
    private String apiKey;

    public OpenAiTtsClient() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);
        factory.setReadTimeout(30_000);
        this.restTemplate = new RestTemplate(factory);
    }

    /** @return mp3 바이트. 실패 시 TtsException(사용자용 메시지, 적절한 상태 코드). */
    public byte[] synthesize(String text, String model, String voice, String instructions) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new TtsException(HttpStatus.SERVICE_UNAVAILABLE, "Audio is not available right now.");
        }
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(apiKey);
        headers.setContentType(MediaType.APPLICATION_JSON);
        Map<String, Object> body = Map.of(
                "model", model,
                "voice", voice,
                "input", text,
                "instructions", instructions,
                "response_format", "mp3");
        try {
            ResponseEntity<byte[]> res = restTemplate.exchange(URL, HttpMethod.POST, new HttpEntity<>(body, headers), byte[].class);
            byte[] audio = res.getBody();
            if (audio == null || audio.length == 0) {
                throw new TtsException(HttpStatus.BAD_GATEWAY, "Could not create audio. Please try again.");
            }
            return audio;
        } catch (ResourceAccessException e) {
            log.warn("OpenAI TTS timeout/network error: {}", e.getClass().getSimpleName());
            throw new TtsException(HttpStatus.GATEWAY_TIMEOUT, "Audio took too long. Please try again.");
        } catch (RestClientResponseException e) {
            log.warn("OpenAI TTS error status {}", e.getStatusCode().value());
            throw new TtsException(HttpStatus.BAD_GATEWAY, "Could not create audio. Please try again.");
        }
    }
}
