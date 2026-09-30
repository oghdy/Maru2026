package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.net.SocketTimeoutException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GeminiServiceTest {

    @Mock
    private RestTemplate restTemplate;

    private GeminiService geminiService;

    @BeforeEach
    void setUp() {
        geminiService = new GeminiService(restTemplate, new ObjectMapper());
        ReflectionTestUtils.setField(geminiService, "geminiApiKey", "test-key");
        ReflectionTestUtils.setField(geminiService, "geminiApiUrl", "http://test-url");
    }

    private void respondWith(String body) {
        when(restTemplate.postForObject(anyString(), any(HttpEntity.class), eq(String.class))).thenReturn(body);
    }

    private void failWith(RuntimeException e) {
        when(restTemplate.postForObject(anyString(), any(HttpEntity.class), eq(String.class))).thenThrow(e);
    }

    @Test
    @DisplayName("Should successfully extract text from valid Gemini API JSON response")
    void askGemini_ValidResponse_ExtractsText() {
        respondWith("""
                {
                   "candidates": [
                      {
                         "content": {
                            "parts": [ { "text": "안녕하세요 (Annyeonghaseyo)" } ],
                            "role": "model"
                         },
                         "finishReason": "STOP",
                         "index": 0
                      }
                   ]
                }
                """);

        assertThat(geminiService.askGemini("translate 'hello'")).isEqualTo("안녕하세요 (Annyeonghaseyo)");
    }

    @Test
    @DisplayName("API key is sent in the x-goog-api-key header, never in the URL")
    @SuppressWarnings("unchecked")
    void askGemini_SendsKeyInHeaderNotUrl() {
        respondWith("{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"ok\"}]}}]}");

        geminiService.askGemini("x");

        ArgumentCaptor<String> url = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<HttpEntity<?>> entity = ArgumentCaptor.forClass(HttpEntity.class);
        verify(restTemplate).postForObject(url.capture(), entity.capture(), eq(String.class));
        assertThat(url.getValue()).isEqualTo("http://test-url").doesNotContain("test-key");
        assertThat(entity.getValue().getHeaders().getFirst("x-goog-api-key")).isEqualTo("test-key");
    }

    @Test
    @DisplayName("Blocked / empty candidate -> BAD_RESPONSE (no NullPointerException)")
    void askGemini_NoText_BadResponse() {
        respondWith("{\"candidates\":[{\"finishReason\":\"SAFETY\"}],\"promptFeedback\":{}}");

        assertThatThrownBy(() -> geminiService.askGemini("x"))
                .isInstanceOf(GeminiService.GeminiException.class)
                .extracting("reason").isEqualTo(GeminiService.GeminiException.Reason.BAD_RESPONSE);
    }

    @Test
    @DisplayName("Read timeout -> TIMEOUT, and the message does not leak the URL/key")
    void askGemini_Timeout() {
        failWith(new ResourceAccessException("I/O error on POST request for \"http://test-url?key=test-key\"",
                new SocketTimeoutException("Read timed out")));

        assertThatThrownBy(() -> geminiService.askGemini("x"))
                .isInstanceOf(GeminiService.GeminiException.class)
                .hasMessageNotContaining("test-key")
                .extracting("reason").isEqualTo(GeminiService.GeminiException.Reason.TIMEOUT);
    }

    @Test
    @DisplayName("JDK HttpClient timeout (HttpTimeoutException) -> TIMEOUT")
    void askGemini_JdkClientTimeout() {
        failWith(new ResourceAccessException("I/O error", new java.net.http.HttpTimeoutException("request timed out")));

        assertThatThrownBy(() -> geminiService.askGemini("x"))
                .extracting("reason").isEqualTo(GeminiService.GeminiException.Reason.TIMEOUT);
    }

    @Test
    @DisplayName("HTTP error from Gemini (e.g. 429 quota) -> UNAVAILABLE")
    void askGemini_HttpError_Unavailable() {
        failWith(HttpClientErrorException.create(HttpStatus.TOO_MANY_REQUESTS, "Too Many Requests", null, null, null));

        assertThatThrownBy(() -> geminiService.askGemini("x"))
                .isInstanceOf(GeminiService.GeminiException.class)
                .extracting("reason").isEqualTo(GeminiService.GeminiException.Reason.UNAVAILABLE);
    }
}
