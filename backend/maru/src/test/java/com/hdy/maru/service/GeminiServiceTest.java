package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GeminiServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private GeminiService geminiService;

    @Test
    @DisplayName("Should successfully extract text from valid Gemini API JSON response")
    void askGemini_ValidResponse_ExtractsText() throws Exception {
        // Given
        ReflectionTestUtils.setField(geminiService, "geminiApiKey", "test-key");
        ReflectionTestUtils.setField(geminiService, "geminiApiUrl", "http://test-url");

        // Mocked ObjectMapper instead of real so we can control JSON, or we use real
        // ObjectMapper
        // Actually, it's easier and safer to use a REAL ObjectMapper for this parsing
        // test!
        ObjectMapper realMapper = new ObjectMapper();
        ReflectionTestUtils.setField(geminiService, "objectMapper", realMapper);

        String prompt = "translate 'hello'";
        String urlWithKey = "http://test-url?key=test-key";

        // This matches the complex Gemini 1.5 JSON response structure
        String mockJsonResponse = """
                    {
                       "candidates": [
                          {
                             "content": {
                                "parts": [
                                   {
                                      "text": "안녕하세요 (Annyeonghaseyo)"
                                   }
                                ],
                                "role": "model"
                             },
                             "finishReason": "STOP",
                             "index": 0,
                             "safetyRatings": []
                          }
                       ],
                       "promptFeedback": {}
                    }
                """;

        when(restTemplate.postForObject(eq(urlWithKey), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockJsonResponse);

        // When
        String result = geminiService.askGemini(prompt);

        // Then
        assertThat(result).isEqualTo("안녕하세요 (Annyeonghaseyo)");
    }
}
