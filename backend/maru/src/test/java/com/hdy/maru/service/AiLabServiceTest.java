package com.hdy.maru.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.AiLabExploreResponseDto;
import com.hdy.maru.entity.AiCache;
import com.hdy.maru.repository.AiCacheRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiLabServiceTest {

    @Mock
    private AiCacheRepository aiCacheRepository;

    @Mock
    private GeminiService geminiService;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private AiLabService aiLabService;

    @Test
    @DisplayName("Should return CACHED result without calling Gemini")
    void exploreCategory_CacheHit_DoesNotCallGemini() throws Exception {
        // Given
        AiLabExploreRequestDto request = new AiLabExploreRequestDto();
        request.setInputText("공부하다");
        request.setCategory("tense");

        String cachedJson = "[{\"text\": \"공부해요\", \"type\": \"현재\", \"explanation\": \"...\"}]";
        AiCache cache = new AiCache();
        cache.setOutputText(cachedJson);

        AiLabExploreResponseDto resDto = AiLabExploreResponseDto.builder()
                .text("공부해요")
                .type("현재")
                .explanation("...")
                .build();

        when(aiCacheRepository.findByInputTextAndTransformationType("공부하다", "explore:tense"))
                .thenReturn(Optional.of(cache));
        when(objectMapper.readValue(eq(cachedJson), any(TypeReference.class)))
                .thenReturn(List.of(resDto));

        // When
        List<AiLabExploreResponseDto> result = aiLabService.exploreCategory(request);

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getText()).isEqualTo("공부해요");

        // Ensure Gemini API was NEVER called because cache existed
        verify(geminiService, never()).askGemini(anyString());
    }

    @Test
    @DisplayName("Should call Gemini API when cache MISSES and save the result")
    void exploreCategory_CacheMiss_CallsGeminiAndSaves() throws Exception {
        // Given
        AiLabExploreRequestDto request = new AiLabExploreRequestDto();
        request.setInputText("사과를 먹다");
        request.setCategory("politeness");

        String geminiResponse = "```json\n[{\"text\": \"사과를 먹어요\", \"type\": \"존댓말\", \"explanation\": \"...\"}]\n```";
        String cleanJson = "[{\"text\": \"사과를 먹어요\", \"type\": \"존댓말\", \"explanation\": \"...\"}]";

        AiLabExploreResponseDto resDto = AiLabExploreResponseDto.builder()
                .text("사과를 먹어요")
                .type("존댓말")
                .explanation("...")
                .build();

        when(aiCacheRepository.findByInputTextAndTransformationType("사과를 먹다", "explore:politeness"))
                .thenReturn(Optional.empty()); // Cache miss
        when(geminiService.askGemini(anyString())).thenReturn(geminiResponse);
        when(objectMapper.readValue(eq(cleanJson), any(TypeReference.class)))
                .thenReturn(List.of(resDto));

        // When
        List<AiLabExploreResponseDto> result = aiLabService.exploreCategory(request);

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getText()).isEqualTo("사과를 먹어요");

        // Verify Gemini was called EXACTLY ONCE
        verify(geminiService, times(1)).askGemini(anyString());
        // Verify we saved the newly fetched result to the database cache
        verify(aiCacheRepository, times(1)).save(any(AiCache.class));
    }

    @Test
    @DisplayName("Should return CACHED result for Combine when sorted modifiers match")
    void combineModifiers_CacheHit_DoesNotCallGemini() throws Exception {
        // Given
        com.hdy.maru.dto.AiLabCombineRequestDto request = new com.hdy.maru.dto.AiLabCombineRequestDto();
        request.setInputText("공부하다");
        request.setModifiers(java.util.List.of("negative", "honorific", "past"));

        String cachedJson = "테스트 결과";
        AiCache cache = new AiCache();
        cache.setOutputText(cachedJson);
        cache.setEnglishTranslation("english");
        cache.setExplanation("explanation");

        // The service should SORT the modifiers alphabetically:
        // "honorific,negative,past"
        String expectedTransformationString = "combine:honorific,negative,past";
        when(aiCacheRepository.findByInputTextAndTransformationType("공부하다", expectedTransformationString))
                .thenReturn(Optional.of(cache));

        // When
        com.hdy.maru.dto.AiLabCombineResponseDto result = aiLabService.combineModifiers(request);

        // Then
        assertThat(result.getText()).isEqualTo("테스트 결과");
        verify(geminiService, never()).askGemini(anyString());
    }

    @Test
    @DisplayName("Should call Gemini and store combined result when cache misses")
    void combineModifiers_CacheMiss_CallsGeminiAndSaves() throws Exception {
        // Given
        com.hdy.maru.dto.AiLabCombineRequestDto request = new com.hdy.maru.dto.AiLabCombineRequestDto();
        request.setInputText("먹다");
        request.setModifiers(java.util.List.of("z_modifier", "a_modifier"));

        String geminiResponse = "```json\n{\"text\":\"안 먹을래\",\"englishTranslation\":\"won't eat\",\"explanation\":\"설명\"}\n```";
        String expectedTransformationString = "combine:a_modifier,z_modifier"; // Sorted!

        when(aiCacheRepository.findByInputTextAndTransformationType("먹다", expectedTransformationString))
                .thenReturn(Optional.empty());
        when(geminiService.askGemini(anyString())).thenReturn(geminiResponse);

        com.hdy.maru.dto.AiLabCombineResponseDto mockDto = com.hdy.maru.dto.AiLabCombineResponseDto.builder()
                .text("안 먹을래")
                .englishTranslation("won't eat")
                .explanation("설명")
                .build();

        when(objectMapper.readValue(anyString(), eq(com.hdy.maru.dto.AiLabCombineResponseDto.class)))
                .thenReturn(mockDto);

        // When
        com.hdy.maru.dto.AiLabCombineResponseDto result = aiLabService.combineModifiers(request);

        // Then
        assertThat(result.getText()).isEqualTo("안 먹을래");
        verify(geminiService, times(1)).askGemini(anyString());
        verify(aiCacheRepository, times(1)).save(any(AiCache.class));
    }
}
