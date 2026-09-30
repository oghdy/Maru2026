package com.hdy.maru.controller;

import com.hdy.maru.security.JwtProvider;
import com.hdy.maru.service.TtsException;
import com.hdy.maru.service.TtsService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TtsControllerTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private JwtProvider jwtProvider;
    @MockitoBean
    private TtsService ttsService;

    private String auth() {
        return "Bearer " + jwtProvider.generateToken("tts_tester", "ROLE_USER");
    }

    @Test
    @DisplayName("인증 없으면 403")
    void requiresAuth() throws Exception {
        mockMvc.perform(get("/api/tts").param("text", "안녕하세요"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("성공 → audio/mpeg 바이트 + X-TTS-Cache")
    void returnsMp3() throws Exception {
        given(ttsService.speak("안녕하세요")).willReturn(new TtsService.TtsResult(new byte[]{9, 8, 7}, true));
        mockMvc.perform(get("/api/tts").param("text", "안녕하세요").header("Authorization", auth()))
                .andExpect(status().isOk())
                .andExpect(content().contentType("audio/mpeg"))
                .andExpect(content().bytes(new byte[]{9, 8, 7}))
                .andExpect(header().string("X-TTS-Cache", "HIT"));
    }

    @Test
    @DisplayName("TtsException → 해당 상태 + ApiResponse JSON")
    void errorAsJson() throws Exception {
        given(ttsService.speak("x")).willThrow(new TtsException(HttpStatus.BAD_GATEWAY, "Could not create audio. Please try again."));
        mockMvc.perform(get("/api/tts").param("text", "x").header("Authorization", auth()).header("Accept", "audio/mpeg"))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.status").value(502))
                .andExpect(jsonPath("$.message").value("Could not create audio. Please try again."));
    }

    @Test
    @DisplayName("text 파라미터 없으면 400 JSON (Accept: audio/mpeg 이어도)")
    void missingText() throws Exception {
        given(ttsService.speak(null)).willThrow(new TtsException(HttpStatus.BAD_REQUEST, "Text is required."));
        mockMvc.perform(get("/api/tts").header("Authorization", auth()).header("Accept", "audio/mpeg"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Text is required."));
    }
}
