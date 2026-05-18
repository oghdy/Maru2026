package com.hdy.maru.controller;

import com.hdy.maru.domain.fsrs.ReviewRating;
import com.hdy.maru.dto.*;
import com.hdy.maru.service.VocabularyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/vocabulary")
@RequiredArgsConstructor
public class VocabularyController {

    private final VocabularyService vocabularyService;

    /**
     * 특정 레벨의 단어장(카테고리/덱) 목록을 조회합니다.
     */
    @GetMapping("/decks")
    public ResponseEntity<ApiResponse<List<WordCategoryDto>>> getDecks(@RequestParam(defaultValue = "Beginner") String level) {
        List<WordCategoryDto> categories = vocabularyService.getDecksWithCount(level);
        return ResponseEntity.ok(ApiResponse.success(categories));
    }

    /**
     * 오늘 복습 및 학습해야 할 단어 세트를 요청합니다 (최대 30개 기본값)
     */
    @GetMapping("/due")
    public ResponseEntity<ApiResponse<List<WordDueDto>>> getDueWords(
            @AuthenticationPrincipal String oauthId,
            @RequestParam Long deckId,
            @RequestParam(defaultValue = "1") int lessonNumber,
            @RequestParam(defaultValue = "30") int limit
    ) {
        List<WordDueDto> dueWords = vocabularyService.getDueWordsByLesson(oauthId, deckId, lessonNumber, limit);
        return ResponseEntity.ok(ApiResponse.success(dueWords));
    }

    @GetMapping("/daily-review")
    public ResponseEntity<ApiResponse<List<WordDueDto>>> getDailyReviewWords(
            @AuthenticationPrincipal String oauthId,
            @RequestParam(defaultValue = "30") int limit) {
        
        List<WordDueDto> words = vocabularyService.getDailyReviewWords(oauthId, limit);
        return ResponseEntity.ok(ApiResponse.success(words));
    }

    /**
     * 4x4 단어 매칭 게임을 위해 섞인 16개 타일 데이터를 요청합니다.
     */
    @GetMapping("/game/{deckId}")
    public ResponseEntity<ApiResponse<List<VocabularyGameTileDto>>> getGameTiles(
            @PathVariable Long deckId,
            @RequestParam(defaultValue = "1") int lessonNumber
    ) {
        List<VocabularyGameTileDto> tiles = vocabularyService.generateGameTiles(deckId, lessonNumber);
        return ResponseEntity.ok(ApiResponse.success(tiles));
    }

    /**
     * 단어 카드에 대해 평가를 제출합니다 (FSRS 알고리즘 갱신)
     */
    @PostMapping("/review")
    public ResponseEntity<ApiResponse<Void>> submitReview(
            @AuthenticationPrincipal String oauthId,
            @RequestBody ReviewRequestDto request) {
        
        ReviewRating rating = ReviewRating.GOOD; // 기본값
        for (ReviewRating r : ReviewRating.values()) {
            if (r.getValue() == request.getRating()) {
                rating = r;
                break;
            }
        }
        
        vocabularyService.submitReview(oauthId, request.getWordId(), rating, request.getReviewMode());
        return ResponseEntity.ok(ApiResponse.success(null));
    }
    /**
     * 특정 단어장 내의 레슨 목록(30단어 단위)을 조회합니다.
     */
    @GetMapping("/decks/{deckId}/lessons")
    public ResponseEntity<ApiResponse<List<WordLessonDto>>> getLessons(
            @AuthenticationPrincipal String oauthId,
            @PathVariable Long deckId) {
        List<WordLessonDto> lessons = vocabularyService.getLessonsByDeckId(oauthId, deckId);
        return ResponseEntity.ok(ApiResponse.success(lessons));
    }
}
