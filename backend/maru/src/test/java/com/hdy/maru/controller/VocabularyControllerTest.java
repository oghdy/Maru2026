package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ReviewRequestDto;
import com.hdy.maru.dto.WordDueDto;
import com.hdy.maru.dto.WordGameDto;
import com.hdy.maru.entity.WordCategory;
import com.hdy.maru.repository.WordCategoryRepository;
import com.hdy.maru.service.VocabularyService;
import com.hdy.maru.security.JwtAuthenticationFilter;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VocabularyController.class)
@AutoConfigureMockMvc(addFilters = false)
class VocabularyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private VocabularyService vocabularyService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    @DisplayName("덱 목록을 정상적으로 반환한다")
    void getDecks() throws Exception {
        com.hdy.maru.dto.WordCategoryDto dto = com.hdy.maru.dto.WordCategoryDto.builder()
                .id(1L)
                .title("초급 테마")
                .level("Beginner")
                .totalWords(100)
                .build();
        
        given(vocabularyService.getDecksWithCount("Beginner"))
                .willReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/vocabulary/decks").param("level", "Beginner"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data[0].title").value("초급 테마"))
                .andExpect(jsonPath("$.data[0].totalWords").value(100));
    }

    @Test
    @DisplayName("오늘 학습할 단어를 정상 반환한다")
    void getDueWords() throws Exception {
        WordDueDto dto = WordDueDto.builder()
                .id(1L)
                .koreanWord("장소")
                .primaryMeaning("place")
                .state(0) // New
                .build();

        given(vocabularyService.getDueWordsByLesson(any(), anyLong(), anyInt(), anyInt()))
                .willReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/vocabulary/due")
                        .param("deckId", "100")
                        .param("limit", "30"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data[0].koreanWord").value("장소"))
                .andExpect(jsonPath("$.data[0].primaryMeaning").value("place"));
    }

    @Test
    @DisplayName("오늘 복습할 단어 목록을 정상 반환한다")
    void getDailyReviewWords() throws Exception {
        WordDueDto dto = WordDueDto.builder()
                .id(10L)
                .koreanWord("야구")
                .primaryMeaning("baseball")
                .state(2) // Review
                .build();

        given(vocabularyService.getDailyReviewWords(any(), anyInt()))
                .willReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/vocabulary/daily-review")
                        .param("limit", "30"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data[0].koreanWord").value("야구"))
                .andExpect(jsonPath("$.data[0].primaryMeaning").value("baseball"));
    }

    @Test
    @DisplayName("단어 평가 결과 전송이 200 OK를 반환한다")
    void submitReview() throws Exception {
        ReviewRequestDto request = new ReviewRequestDto();
        request.setWordId(999L);
        request.setRating(3); // GOOD

        com.hdy.maru.entity.FsrsProgress progress = new com.hdy.maru.entity.FsrsProgress();
        progress.setState(2);
        progress.setNextReviewDate(java.time.LocalDateTime.of(2026, 10, 4, 10, 0));
        given(vocabularyService.submitReview(any(), eq(999L), any(), any()))
                .willReturn(new VocabularyService.ReviewOutcome(progress, true));

        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andExpect(jsonPath("$.data.applied").value(true))
                .andExpect(jsonPath("$.data.state").value(2))
                .andExpect(jsonPath("$.data.nextReviewDate").value("2026-10-04T10:00:00"));
    }

    @Test
    @DisplayName("평가 등급이 1~4 밖이면 400 을 반환한다 (조용히 GOOD 처리하지 않음)")
    void submitReview_rejectsInvalidRating() throws Exception {
        ReviewRequestDto request = new ReviewRequestDto();
        request.setWordId(999L);
        request.setRating(9);

        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
        org.mockito.Mockito.verifyNoInteractions(vocabularyService);
    }

    @Test
    @DisplayName("wordId 가 없으면 400 을 반환한다")
    void submitReview_rejectsMissingWordId() throws Exception {
        mockMvc.perform(post("/api/v1/vocabulary/review")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rating\":3}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }
}
