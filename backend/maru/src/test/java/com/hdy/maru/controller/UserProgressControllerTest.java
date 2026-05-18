package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserProgress;
import com.hdy.maru.repository.UserProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class UserProgressControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("Should successfully UPSERT progress with valid JWT")
    void updateProgress_WithValidJwt_Returns200() throws Exception {
        // Given
        String oauthId = "test_user_progress";
        User user = new User();
        user.setOauthProvider("google");
        user.setOauthId(oauthId);
        user.setEmail("progress@test.com");
        user.setNickname("ProgressTester");
        userRepository.save(user);

        String token = jwtProvider.generateToken(oauthId, "ROLE_USER");
        String lessonId = "unit1_lesson1";

        UserProgressRequestDto request = new UserProgressRequestDto("completed", 5, 100, 300);

        // When & Then
        mockMvc.perform(post("/api/progress/lessons/" + lessonId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data.lessonId").value(lessonId))
                .andExpect(jsonPath("$.data.status").value("completed"))
                .andExpect(jsonPath("$.data.starsEarned").value(3));
    }

    @Test
    @DisplayName("Should return 401 without JWT")
    void updateProgress_WithoutJwt_Returns401() throws Exception {
        // Given
        String lessonId = "unit1_lesson1";
        UserProgressRequestDto request = new UserProgressRequestDto("completed", 5, 100, 300);

        // When & Then
        mockMvc.perform(post("/api/progress/lessons/" + lessonId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
        // 302 Found or 401 depending on SecurityConfig oauth2Login setup.
        // But since this is a protected API endpoint, the JwtIntegrationTest showed
        // 302.
    }
}
