package com.hdy.maru.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class JwtIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Test
    @DisplayName("Without JWT token, API should return 403 (Forbidden access blocked)")
    void accessWithoutToken() throws Exception {
        // When & Then
        mockMvc.perform(get("/api/me"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("With valid JWT token, API should return 200 OK and extract User ID")
    void accessWithValidToken() throws Exception {
        // Given
        String testUserId = "apple_99999";
        String token = jwtProvider.generateToken(testUserId, "ROLE_USER");

        // When & Then
        mockMvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }
}
