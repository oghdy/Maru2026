package com.hdy.maru.service;

import com.hdy.maru.entity.TtsCache;
import com.hdy.maru.repository.TtsCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.Normalizer;
import java.util.HexFormat;
import java.util.Map;

/**
 * 한국어 TTS (OpenAI) + DB 캐시.
 * 같은 텍스트(정규화 후)·모델·목소리·지시문 버전이면 캐시에서 반환하고 OpenAI 를 부르지 않는다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TtsService {

    public static final int MAX_LENGTH = 200;
    public static final String CONTENT_TYPE = "audio/mpeg";

    /** 지시문을 바꾸면 이 값을 올려 기존 캐시와 섞이지 않게 한다. */
    static final String PROMPT_VERSION = "v1";
    static final String INSTRUCTIONS = "Speak in natural standard Seoul Korean at a slightly slow, clear pace "
            + "for language learners. Pronounce exactly the given text and nothing else.";

    /** 자모 한 글자는 TTS 가 불안정하므로 표준 읽기로 바꿔 읽힌다 (모음 ㅏ → 아, 자음 ㄱ → 기역). */
    static final Map<String, String> JAMO_READING = Map.ofEntries(
            Map.entry("ㄱ", "기역"), Map.entry("ㄲ", "쌍기역"), Map.entry("ㄴ", "니은"), Map.entry("ㄷ", "디귿"),
            Map.entry("ㄸ", "쌍디귿"), Map.entry("ㄹ", "리을"), Map.entry("ㅁ", "미음"), Map.entry("ㅂ", "비읍"),
            Map.entry("ㅃ", "쌍비읍"), Map.entry("ㅅ", "시옷"), Map.entry("ㅆ", "쌍시옷"), Map.entry("ㅇ", "이응"),
            Map.entry("ㅈ", "지읒"), Map.entry("ㅉ", "쌍지읒"), Map.entry("ㅊ", "치읓"), Map.entry("ㅋ", "키읔"),
            Map.entry("ㅌ", "티읕"), Map.entry("ㅍ", "피읖"), Map.entry("ㅎ", "히읗"),
            Map.entry("ㅏ", "아"), Map.entry("ㅐ", "애"), Map.entry("ㅑ", "야"), Map.entry("ㅒ", "얘"),
            Map.entry("ㅓ", "어"), Map.entry("ㅔ", "에"), Map.entry("ㅕ", "여"), Map.entry("ㅖ", "예"),
            Map.entry("ㅗ", "오"), Map.entry("ㅘ", "와"), Map.entry("ㅙ", "왜"), Map.entry("ㅚ", "외"),
            Map.entry("ㅛ", "요"), Map.entry("ㅜ", "우"), Map.entry("ㅝ", "워"), Map.entry("ㅞ", "웨"),
            Map.entry("ㅟ", "위"), Map.entry("ㅠ", "유"), Map.entry("ㅡ", "으"), Map.entry("ㅢ", "의"),
            Map.entry("ㅣ", "이"));

    private final TtsCacheRepository repository;
    private final OpenAiTtsClient client;

    @Value("${tts.model:gpt-4o-mini-tts}")
    private String model;

    @Value("${tts.voice:ash}")
    private String voice;

    /** 결과 오디오 + 캐시 적중 여부. */
    public record TtsResult(byte[] audio, boolean cacheHit) {
    }

    public TtsResult speak(String rawText) {
        String text = normalize(rawText);
        if (text.isEmpty()) {
            throw new TtsException(HttpStatus.BAD_REQUEST, "Text is required.");
        }
        if (text.codePointCount(0, text.length()) > MAX_LENGTH) {
            throw new TtsException(HttpStatus.BAD_REQUEST, "Text is too long (max " + MAX_LENGTH + " characters).");
        }
        String key = cacheKey(text);
        var cached = repository.findByCacheKey(key);
        if (cached.isPresent()) {
            return new TtsResult(cached.get().getAudio(), true);
        }

        byte[] audio = client.synthesize(JAMO_READING.getOrDefault(text, text), model, voice, INSTRUCTIONS);

        TtsCache entry = new TtsCache();
        entry.setCacheKey(key);
        entry.setInputText(text);
        entry.setModel(model);
        entry.setVoice(voice);
        entry.setContentType(CONTENT_TYPE);
        entry.setAudio(audio);
        try {
            repository.save(entry);
        } catch (DataIntegrityViolationException e) {
            // 같은 텍스트가 동시에 요청돼 다른 요청이 먼저 저장함 → 그대로 응답
            log.debug("TTS cache race for key {}", key);
        }
        return new TtsResult(audio, false);
    }

    /** 앞뒤 공백 제거, 연속 공백 1칸, 유니코드 NFC. */
    static String normalize(String raw) {
        if (raw == null) return "";
        return Normalizer.normalize(raw, Normalizer.Form.NFC).strip().replaceAll("\\s+", " ");
    }

    String cacheKey(String text) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest((model + "|" + voice + "|" + PROMPT_VERSION + "|" + text).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
