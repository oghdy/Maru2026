package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.AuthRequestDto;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private JwtProvider jwtProvider;

    @Test
    @DisplayName("Should return 400 Bad Request when idToken is blank or missing")
    void googleAuth_WithoutIdToken_ReturnsBadRequest() throws Exception {
        AuthRequestDto req = new AuthRequestDto();
        req.setIdToken("");

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    @DisplayName("Invalid Google token → HTTP 401 + English message, no exception text (PM-1.P.1)")
    void googleAuth_WithInvalidIdToken_Returns401() throws Exception {
        AuthRequestDto req = new AuthRequestDto();
        req.setIdToken("fake.invalid.token");

        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.message").value("Google sign-in failed. Please try again."))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    @DisplayName("Invalid Apple token → HTTP 401 + English message (PM-1.P.1)")
    void appleAuth_WithInvalidIdToken_Returns401() throws Exception {
        AuthRequestDto req = new AuthRequestDto();
        req.setIdToken("fake.invalid.token");

        mockMvc.perform(post("/api/auth/apple")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.message").value("Apple sign-in failed. Please try again."));
    }
}
