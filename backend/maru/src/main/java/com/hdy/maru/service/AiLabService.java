package com.hdy.maru.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.AiLabExploreResponseDto;
import com.hdy.maru.entity.AiCache;
import com.hdy.maru.repository.AiCacheRepository;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiLabService {

    static final int EXPLORE_RESULT_COUNT = 3;

    static final String MSG_TIMEOUT = "The AI took too long to respond. Please try again.";
    static final String MSG_UNAVAILABLE = "The AI service is unavailable right now. Please try again in a moment.";
    static final String MSG_BAD_RESPONSE = "The AI returned an unexpected answer. Please try again.";

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

        // 1. Check Cache (an unreadable cached row is treated as a miss and overwritten)
        Optional<AiCache> cached = aiCacheRepository.findByInputTextAndTransformationType(inputText, transformationType);
        if (cached.isPresent()) {
            List<AiLabExploreResponseDto> results = parseExploreResults(cached.get().getOutputText());
            if (results != null) {
                log.info("CACHE HIT! Returning cached result for {}", transformationType);
                return results;
            }
            log.warn("Cached result for {} is invalid, regenerating (cache id={})", transformationType,
                    cached.get().getId());
        }
        return generateAndCacheExplore(inputText, request.getCategory(), transformationType, cached.orElse(null));
    }

    private List<AiLabExploreResponseDto> generateAndCacheExplore(String inputText, String category,
            String transformationType, AiCache staleCache) {
        log.info("CACHE MISS! Calling Gemini API for category: {}", category);

        // 2. Build Prompt based on category
        String prompt = buildExplorePrompt(inputText, category);

        // 3. Call Gemini
        String geminiRawResponse = callGemini(prompt);

        // 4. Extract pure JSON string from Gemini's markdown wrapper (if any)
        String cleanJson = extractJsonArrayString(geminiRawResponse);

        // 5. Verify it parses to exactly 3 complete variations
        List<AiLabExploreResponseDto> results = parseExploreResults(cleanJson);
        if (results == null) {
            log.warn("Gemini explore output rejected for {} ({} chars)", transformationType, cleanJson.length());
            throw new AiLabException(HttpStatus.BAD_GATEWAY, MSG_BAD_RESPONSE);
        }

        // 6. Save back to cache (normalized JSON of the validated results)
        AiCache newCache = staleCache != null ? staleCache : new AiCache();
        newCache.setInputText(inputText);
        newCache.setTransformationType(transformationType);
        newCache.setOutputText(toJson(results));
        // English translation and explanation are kept null here because the list
        // itself contains explanations
        saveCache(newCache);

        return results;
    }

    /**
     * Returns the first 3 variations if all are complete, otherwise null.
     */
    private List<AiLabExploreResponseDto> parseExploreResults(String json) {
        List<AiLabExploreResponseDto> results;
        try {
            results = objectMapper.readValue(json, new TypeReference<List<AiLabExploreResponseDto>>() {
            });
        } catch (JsonProcessingException | IllegalArgumentException e) {
            return null;
        }
        if (results == null || results.size() < EXPLORE_RESULT_COUNT) {
            return null;
        }
        List<AiLabExploreResponseDto> firstThree = results.subList(0, EXPLORE_RESULT_COUNT);
        boolean complete = firstThree.stream().allMatch(r -> r != null
                && !isBlank(r.getText()) && !isBlank(r.getType()) && !isBlank(r.getExplanation()));
        return complete ? List.copyOf(firstThree) : null;
    }

    private String callGemini(String prompt) {
        try {
            return geminiService.askGemini(prompt);
        } catch (GeminiService.GeminiException e) {
            switch (e.getReason()) {
                case TIMEOUT -> throw new AiLabException(HttpStatus.GATEWAY_TIMEOUT, MSG_TIMEOUT);
                case BAD_RESPONSE -> throw new AiLabException(HttpStatus.BAD_GATEWAY, MSG_BAD_RESPONSE);
                default -> throw new AiLabException(HttpStatus.SERVICE_UNAVAILABLE, MSG_UNAVAILABLE);
            }
        }
    }

    private void saveCache(AiCache cache) {
        try {
            aiCacheRepository.save(cache);
        } catch (DataIntegrityViolationException e) {
            // Same request finished concurrently and was cached first; the result is still valid
            log.info("Cache row for {} already saved by another request", cache.getTransformationType());
        }
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new AiLabException(HttpStatus.BAD_GATEWAY, MSG_BAD_RESPONSE);
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
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
        String cleaned = raw == null ? "" : raw.trim();
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
        Optional<AiCache> cached = aiCacheRepository.findByInputTextAndTransformationType(inputText, transformationType);
        if (cached.isPresent()) {
            AiCache cache = cached.get();
            com.hdy.maru.dto.AiLabCombineResponseDto result = com.hdy.maru.dto.AiLabCombineResponseDto.builder()
                    .text(cache.getOutputText())
                    .englishTranslation(cache.getEnglishTranslation())
                    .explanation(cache.getExplanation())
                    .build();
            if (isCompleteCombine(result)) {
                log.info("CACHE HIT! Returning combined result for {}", transformationType);
                return result;
            }
            log.warn("Cached result for {} is invalid, regenerating (cache id={})", transformationType, cache.getId());
        }
        return generateAndCacheCombine(inputText, modifierString, transformationType, cached.orElse(null));
    }

    private com.hdy.maru.dto.AiLabCombineResponseDto generateAndCacheCombine(String inputText, String modifierString,
            String transformationType, AiCache staleCache) {
        log.info("CACHE MISS! Calling Gemini API for combined modifiers: {}", modifierString);

        String prompt = buildCombinePrompt(inputText, modifierString);
        String geminiRawResponse = callGemini(prompt);
        String cleanJson = extractJsonArrayString(geminiRawResponse);

        com.hdy.maru.dto.AiLabCombineResponseDto result;
        try {
            result = objectMapper.readValue(cleanJson, com.hdy.maru.dto.AiLabCombineResponseDto.class);
        } catch (JsonProcessingException | IllegalArgumentException e) {
            result = null;
        }
        if (!isCompleteCombine(result)) {
            log.warn("Gemini combine output rejected for {} ({} chars)", transformationType, cleanJson.length());
            throw new AiLabException(HttpStatus.BAD_GATEWAY, MSG_BAD_RESPONSE);
        }

        // Save to DB
        AiCache newCache = staleCache != null ? staleCache : new AiCache();
        newCache.setInputText(inputText);
        newCache.setTransformationType(transformationType);
        newCache.setOutputText(result.getText());
        newCache.setEnglishTranslation(result.getEnglishTranslation());
        newCache.setExplanation(result.getExplanation());
        saveCache(newCache);

        return result;
    }

    private static boolean isCompleteCombine(com.hdy.maru.dto.AiLabCombineResponseDto r) {
        return r != null && !isBlank(r.getText()) && !isBlank(r.getEnglishTranslation())
                && !isBlank(r.getExplanation());
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

    /**
     * Lab request failure with an HTTP status and a message that is safe to show users.
     */
    @Getter
    public static class AiLabException extends RuntimeException {
        private final HttpStatus status;

        public AiLabException(HttpStatus status, String userMessage) {
            super(userMessage);
            this.status = status;
        }
    }
}
