package com.hdy.maru.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ReviewRequestDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.Word;
import com.hdy.maru.entity.WordCategory;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.WordCategoryRepository;
import com.hdy.maru.repository.WordRepository;
import com.hdy.maru.repository.FsrsProgressRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@ActiveProfiles("test")
@Transactional
class VocabularyIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private WordCategoryRepository categoryRepository;

    @Autowired
    private WordRepository wordRepository;

    @Autowired
    private FsrsProgressRepository progressRepository;

    @Autowired
    private UserRepository userRepository;

    private Long savedDeckId;
    private Long testUserId;
    private final String TEST_OAUTH_ID = "test_user_123";

    @BeforeEach
    void setUp() {
        progressRepository.deleteAll();
        wordRepository.deleteAll();
        categoryRepository.deleteAll();
        userRepository.deleteAll();

        // 테스트용 유저 생성
        User user = new User();
        user.setOauthId(TEST_OAUTH_ID);
        user.setOauthProvider("test");
        user.setNickname("테스트유저");
        User savedUser = userRepository.save(user);
        testUserId = savedUser.getId();

        WordCategory category = new WordCategory();
        category.setTitle("통합 테스트 덱");
        category.setLevel("Beginner");
        category.setDeckOrder(1);
        WordCategory savedCat = categoryRepository.save(category);
        savedDeckId = savedCat.getId();

        for (int i = 0; i < 5; i++) {
            Word word = new Word();
            word.setKoreanWord("단어" + i);
            word.setPrimaryMeaning("Meaning" + i);
            word.setCategory(savedCat);
            wordRepository.save(word);
        }

        // 운영의 JwtAuthenticationFilter 처럼 principal 을 oauthId 문자열로 설정 (@AuthenticationPrincipal String)
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(TEST_OAUTH_ID, null, java.util.List.of()));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("단어장 목록 조회부터 학습 결과 제출까지의 전체 흐름을 테스트한다")
    void fullVocabularyFlowTest() throws Exception {
        // 1. 덱 목록 조회
        mockMvc.perform(get("/api/v1/vocabulary/decks").param("level", "Beginner"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].title").value("통합 테스트 덱"))
                .andExpect(jsonPath("$.data[0].totalWords").value(5));

        // 2. 학습할 단어 큐 조회
        mockMvc.perform(get("/api/v1/vocabulary/due")
                        .param("deckId", savedDeckId.toString())
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(5));

        // 3. 첫 번째 단어에 대해 GOOD 평가 제출
        Long wordId = wordRepository.findAll().get(0).getId();
        ReviewRequestDto request = new ReviewRequestDto();
        request.setWordId(wordId);
        request.setRating(3); // GOOD
        request.setReviewMode("LESSON");

        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // 4. DB를 직접 조회하여 해당 단어의 학습 기록이 생성되었는지 확인
        com.hdy.maru.entity.FsrsProgress progress = progressRepository.findByUserIdAndWordId(testUserId, wordId);
        
        org.assertj.core.api.Assertions.assertThat(progress)
                .as("검토 결과가 DB에 저장되어야 합니다")
                .isNotNull();
        
        org.assertj.core.api.Assertions.assertThat(progress.getState())
                .as("신규 단어를 GOOD으로 평가하면 REVIEW(2) 상태가 되어야 합니다")
                .isEqualTo(2); // REVIEW
    }

    @Test
    @DisplayName("학습 모드 가드 및 데일리 복습 흐름 통합 테스트")
    void fsrsModeSeparationTest() throws Exception {
        Long wordId = wordRepository.findAll().get(0).getId();

        // 1. LESSON 모드 최초 학습 (New -> Review)
        ReviewRequestDto lessonRequest = new ReviewRequestDto();
        lessonRequest.setWordId(wordId);
        lessonRequest.setRating(3); // GOOD
        lessonRequest.setReviewMode("LESSON");

        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(lessonRequest)))
                .andExpect(status().isOk());

        com.hdy.maru.entity.FsrsProgress firstProgress = progressRepository.findByUserIdAndWordId(testUserId, wordId);
        double firstStability = firstProgress.getStability();
        int firstReps = firstProgress.getReps();

        // 2. 동일 단어 LESSON 모드 재학습 시도 (Guard 확인)
        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(lessonRequest)))
                .andExpect(status().isOk());

        com.hdy.maru.entity.FsrsProgress secondProgress = progressRepository.findByUserIdAndWordId(testUserId, wordId);
        org.assertj.core.api.Assertions.assertThat(secondProgress.getStability())
                .as("LESSON 모드에서 이미 학습된 단어는 stability가 변하지 않아야 함")
                .isEqualTo(firstStability);
        org.assertj.core.api.Assertions.assertThat(secondProgress.getReps())
                .as("LESSON 모드에서 이미 학습된 단어는 reps가 변하지 않아야 함")
                .isEqualTo(firstReps);

        // 3. 시간 경과 흉내: 5일 전에 학습했고 기한이 지난 것으로 조작 (데일리 리뷰에 등장)
        //    FSRS 는 경과일로 기억률을 계산하므로 last_review 도 과거로 옮겨야 안정성이 오른다
        secondProgress.setLastReview(java.time.LocalDateTime.now().minusDays(5));
        secondProgress.setNextReviewDate(java.time.LocalDateTime.now().minusDays(1));
        progressRepository.save(secondProgress);

        // 4. 데일리 리뷰 API 호출 확인
        mockMvc.perform(get("/api/v1/vocabulary/daily-review").param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(wordId));

        // 5. DAILY_REVIEW 모드 평가 수행 (데이터 갱신 확인)
        ReviewRequestDto reviewRequest = new ReviewRequestDto();
        reviewRequest.setWordId(wordId);
        reviewRequest.setRating(3); // GOOD
        reviewRequest.setReviewMode("DAILY_REVIEW");

        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reviewRequest)))
                .andExpect(status().isOk());

        com.hdy.maru.entity.FsrsProgress finalProgress = progressRepository.findByUserIdAndWordId(testUserId, wordId);
        org.assertj.core.api.Assertions.assertThat(finalProgress.getStability())
                .as("DAILY_REVIEW 모드에서는 stability가 증가해야 함")
                .isGreaterThan(firstStability);
        org.assertj.core.api.Assertions.assertThat(finalProgress.getReps())
                .as("DAILY_REVIEW 모드에서는 reps가 증가해야 함")
                .isEqualTo(firstReps + 1);
    }
}
