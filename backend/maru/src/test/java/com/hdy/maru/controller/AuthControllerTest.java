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
    @DisplayName("Should return 500 when Google Token Verification fails (Mocked Exception)")
    void googleAuth_WithInvalidIdToken_Returns500Error() throws Exception {
        AuthRequestDto req = new AuthRequestDto();
        req.setIdToken("fake.invalid.token");

        // We aren't mocking the GoogleVerifier here, so the hard-coded
        // "fake.invalid.token"
        // will naturally throw an IllegalArgumentException during the verification
        // step.
        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk()) // Our GlobalExceptionHandler or ApiResponse format intercepts it.
                .andExpect(jsonPath("$.status").value(500))
                .andExpect(jsonPath("$.message").isString());
    }
}
