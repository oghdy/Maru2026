package com.hdy.maru.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.AiLabExploreResponseDto;
import com.hdy.maru.entity.AiCache;
import com.hdy.maru.repository.AiCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiLabService {

    private final AiCacheRepository aiCacheRepository;
    private final GeminiService geminiService;
    private final ObjectMapper objectMapper;

    /**
     * Handles single category exploration (e.g., tense, politeness)
     * Returns a cached JSON array if present, otherwise calls Gemini, parses,
     * caches, and returns.
     */
    public List<AiLabExploreResponseDto> exploreCategory(AiLabExploreRequestDto request) {
        String inputText = request.getInputText();
        String transformationType = "explore:" + request.getCategory(); // e.g., "explore:tense"

        // 1. Check Cache
        return aiCacheRepository.findByInputTextAndTransformationType(inputText, transformationType)
                .map(this::parseCacheToExploreDtoList)
                .orElseGet(() -> generateAndCacheExplore(inputText, request.getCategory(), transformationType));
    }

    private List<AiLabExploreResponseDto> parseCacheToExploreDtoList(AiCache cache) {
        log.info("CACHE HIT! Returning cached result for {}", cache.getTransformationType());
        try {
            return objectMapper.readValue(cache.getOutputText(), new TypeReference<>() {
            });
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to decode cached explore result", e);
        }
    }

    private List<AiLabExploreResponseDto> generateAndCacheExplore(String inputText, String category,
            String transformationType) {
        log.info("CACHE MISS! Calling Gemini API for category: {}", category);

        // 2. Build Prompt based on category
        String prompt = buildExplorePrompt(inputText, category);

        // 3. Call Gemini
        String geminiRawResponse = geminiService.askGemini(prompt);

        // 4. Extract pure JSON string from Gemini's markdown wrapper (if any)
        String cleanJson = extractJsonArrayString(geminiRawResponse);

        try {
            // 5. Verify it parses to DTO list successfully
            List<AiLabExploreResponseDto> results = objectMapper.readValue(cleanJson, new TypeReference<>() {
            });

            // 6. Save back to cache
            AiCache newCache = new AiCache();
            newCache.setInputText(inputText);
            newCache.setTransformationType(transformationType);
            newCache.setOutputText(cleanJson);
            // English translation and explanation are kept null here because the list
            // itself contains explanations
            aiCacheRepository.save(newCache);

            return results;
        } catch (JsonProcessingException e) {
            log.error("Failed to parse Gemini output: {}", cleanJson);
            throw new RuntimeException("Gemini returned invalid JSON format", e);
        }
    }

    private String buildExplorePrompt(String inputText, String category) {
        return """
                You are the world's best Korean grammar expert.
                Modify the following Korean sentence into 3 different versions based on the given [Category].
                You must respond ONLY with a pure JSON Array format. Do not attach any markdown (like ```json), intro, or additional text.

                Input Sentence: "%s"
                Category: "%s"

                Expected JSON Array Structure:
                [
                  {"text": "Modified Korean sentence 1", "type": "Type name in English (e.g., Honorific)", "explanation": "A one-line explanation in English about when to use this sentence"},
                  {"text": "Modified Korean sentence 2", "type": "Type name in English (e.g., Formal)", "explanation": "Explanation in English..."},
                  {"text": "Modified Korean sentence 3", "type": "Type name in English (e.g., Casual)", "explanation": "Explanation in English..."}
                ]
                """
                .formatted(inputText, category);
    }

    private String extractJsonArrayString(String raw) {
        // Gemini might wrap the response in ```json ... ```
        String cleaned = raw.trim();
        if (cleaned.startsWith("```json")) {
            cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith("```")) {
            cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        return cleaned.trim();
    }

    /**
     * Handles combining multiple grammar rules (e.g., past + honorific + negative)
     */
    public com.hdy.maru.dto.AiLabCombineResponseDto combineModifiers(com.hdy.maru.dto.AiLabCombineRequestDto request) {
        String inputText = request.getInputText();

        // 1. Sort modifiers to create a deterministic cache key regardless of selection
        // order
        List<String> sortedModifiers = request.getModifiers().stream().sorted().toList();
        String modifierString = String.join(",", sortedModifiers);
        String transformationType = "combine:" + modifierString;

        // 2. Check Cache
        return aiCacheRepository.findByInputTextAndTransformationType(inputText, transformationType)
                .map(this::parseCacheToCombineDto)
                .orElseGet(() -> generateAndCacheCombine(inputText, modifierString, transformationType));
    }

    private com.hdy.maru.dto.AiLabCombineResponseDto parseCacheToCombineDto(AiCache cache) {
        log.info("CACHE HIT! Returning combined result for {}", cache.getTransformationType());
        return com.hdy.maru.dto.AiLabCombineResponseDto.builder()
                .text(cache.getOutputText())
                .englishTranslation(cache.getEnglishTranslation())
                .explanation(cache.getExplanation())
                .build();
    }

    private com.hdy.maru.dto.AiLabCombineResponseDto generateAndCacheCombine(String inputText, String modifierString,
            String transformationType) {
        log.info("CACHE MISS! Calling Gemini API for combined modifiers: {}", modifierString);

        String prompt = buildCombinePrompt(inputText, modifierString);
        String geminiRawResponse = geminiService.askGemini(prompt);
        String cleanJson = extractJsonArrayString(geminiRawResponse);

        try {
            com.hdy.maru.dto.AiLabCombineResponseDto result = objectMapper.readValue(cleanJson,
                    com.hdy.maru.dto.AiLabCombineResponseDto.class);

            // Save to DB
            AiCache newCache = new AiCache();
            newCache.setInputText(inputText);
            newCache.setTransformationType(transformationType);
            newCache.setOutputText(result.getText());
            newCache.setEnglishTranslation(result.getEnglishTranslation());
            newCache.setExplanation(result.getExplanation());
            aiCacheRepository.save(newCache);

            return result;
        } catch (JsonProcessingException e) {
            log.error("Failed to parse Gemini combine output: {}", cleanJson);
            throw new RuntimeException("Gemini returned invalid JSON format for combination", e);
        }
    }

    private String buildCombinePrompt(String inputText, String modifierString) {
        return """
                You are a top-tier AI experimental lab specializing in Korean agglutinative grammar.
                The user will provide a Korean sentence and a list of structural [Modifiers].
                You must strictly combine ALL the modifiers perfectly into a SINGLE, natural-sounding modified Korean sentence.
                You must respond ONLY with a pure JSON Object format. Do not attach any markdown (like ```json), intro, or additional text.

                Original Sentence: "%s"
                Modifiers to apply: "%s"

                Expected JSON Object Structure:
                {
                  "text": "The single final modified Korean sentence with all modifiers applied (e.g., 나는 음악을 안 좋아했어)",
                  "englishTranslation": "The literal English translation of the modified sentence (e.g., I didn't like music)",
                  "explanation": "A one-line explanation in English about who uses this sentence, its nuance, and the situation."
                }
                """
                .formatted(inputText, modifierString);
    }
}
