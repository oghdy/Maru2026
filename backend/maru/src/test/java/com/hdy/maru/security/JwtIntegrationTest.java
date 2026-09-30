package com.hdy.maru.security;

import org.springframework.test.context.ActiveProfiles;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test") // H2 + 테스트용 jwt.secret (application-test.yml). 없으면 로컬 maru DB·JWT_SECRET 에 의존
@AutoConfigureMockMvc
class JwtIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private UserRepository userRepository;

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
        // /api/me 는 DB 에 사용자가 있어야 200 (H2 테스트 DB 에 직접 생성)
        if (userRepository.findByOauthId(testUserId).isEmpty()) {
            User user = new User();
            user.setOauthId(testUserId);
            user.setOauthProvider("apple");
            user.setNickname("JwtTester");
            userRepository.save(user);
        }
        String token = jwtProvider.generateToken(testUserId, "ROLE_USER");

        // When & Then
        mockMvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }
}
