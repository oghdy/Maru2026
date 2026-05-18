package com.hdy.maru.controller;

import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserStats;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.UserStatsRepository;
import com.hdy.maru.security.JwtProvider;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class UserStatsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserStatsRepository userStatsRepository;

    @Test
    @DisplayName("Should successfully return User Stats with valid JWT")
    void getMyStats_WithValidJwt_Returns200AndStats() throws Exception {
        // Given
        String oauthId = "test_user_stats";
        User user = new User();
        user.setOauthProvider("google");
        user.setOauthId(oauthId);
        user.setEmail("stats@test.com");
        user.setNickname("StatsTester");
        User savedUser = userRepository.save(user);

        UserStats stats = new UserStats();
        stats.setUser(savedUser);
        stats.setTotalLessonsCompleted(10);
        stats.setTotalStudyMinutes(120);
        stats.setCurrentStreakDays(5);
        stats.setLongestStreakDays(8);
        stats.setTotalStarsEarned(30);
        stats.setLastStudyDate(LocalDate.now());
        userStatsRepository.save(stats);

        String token = jwtProvider.generateToken(oauthId, "ROLE_USER");

        // When & Then
        mockMvc.perform(get("/api/me/stats")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data.totalLessonsCompleted").value(10))
                .andExpect(jsonPath("$.data.currentStreakDays").value(5))
                .andExpect(jsonPath("$.data.totalStarsEarned").value(30));
    }

    @Test
    @DisplayName("Should return 401/302 without JWT on Stats endpoint")
    void getMyStats_WithoutJwt_ReturnsUnauthorized() throws Exception {
        // When & Then
        mockMvc.perform(get("/api/me/stats")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }
}
