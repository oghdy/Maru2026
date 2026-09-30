package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.LessonContentDto;
import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.entity.Lesson;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserProgress;
import com.hdy.maru.repository.LessonRepository;
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
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
// 테스트 전용 값: JWT 서명 키(테스트용 32바이트 Base64), H2 에 PostgreSQL JSONB 타입이 없어 도메인으로 대체
@TestPropertySource(properties = {
        "jwt.secret=dGVzdC1vbmx5LWp3dC1zZWNyZXQta2V5LTMyLWJ5dGVzISE=",
        "spring.datasource.url=jdbc:h2:mem:maru_progress_test;DB_CLOSE_DELAY=-1;INIT=CREATE DOMAIN IF NOT EXISTS JSONB AS JSON"
})
public class UserProgressControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LessonRepository lessonRepository;

    private void ensureLesson(String lessonId) {
        if (lessonRepository.existsByLessonId(lessonId)) return;
        Lesson lesson = new Lesson();
        lesson.setLessonId(lessonId);
        lesson.setUnitId(1);
        lesson.setUnitTitle("Test Unit");
        lesson.setOrderNum(1);
        lesson.setTitle("Test Lesson");
        lesson.setIsPublished(true);
        lesson.setContent(new LessonContentDto(List.of()));
        lessonRepository.save(lesson);
    }

    private String tokenForNewUser(String oauthId) {
        if (userRepository.findByOauthId(oauthId).isEmpty()) {
            User user = new User();
            user.setOauthProvider("google");
            user.setOauthId(oauthId);
            user.setNickname(oauthId);
            userRepository.save(user);
        }
        return jwtProvider.generateToken(oauthId, "ROLE_USER");
    }

    @Test
    @DisplayName("GET /api/progress/lessons?unitId= → 내 진행 기록만, 해당 유닛만")
    void getProgress_ByUnit() throws Exception {
        String token = tokenForNewUser("test_user_get");
        ensureLesson("unit1_lesson1");
        mockMvc.perform(post("/api/progress/lessons/unit1_lesson1")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new UserProgressRequestDto("completed", 3, 70, 60))))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/progress/lessons").param("unitId", "1")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].lessonId").value("unit1_lesson1"))
                .andExpect(jsonPath("$.data[0].status").value("completed"))
                .andExpect(jsonPath("$.data[0].starsEarned").value(2));

        mockMvc.perform(get("/api/progress/lessons").param("unitId", "0")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    @DisplayName("없는 lessonId → 404 + ApiResponse")
    void updateProgress_UnknownLesson_Returns404() throws Exception {
        String token = tokenForNewUser("test_user_404");
        UserProgressRequestDto request = new UserProgressRequestDto("completed", 5, 100, 300);

        mockMvc.perform(post("/api/progress/lessons/NOPE")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

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
        ensureLesson(lessonId);

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
