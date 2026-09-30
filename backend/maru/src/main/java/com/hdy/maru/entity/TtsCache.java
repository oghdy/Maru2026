package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/** 서버 TTS 결과(mp3) 캐시. 같은 (모델, 목소리, 지시문 버전, 텍스트) 는 OpenAI 를 다시 부르지 않는다. */
@Entity
@Table(name = "tts_cache", uniqueConstraints = {
        @UniqueConstraint(name = "uk_tts_cache_key", columnNames = { "cache_key" })
})
@Getter
@Setter
@NoArgsConstructor
public class TtsCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** sha256(model|voice|promptVersion|text) hex */
    @Column(name = "cache_key", nullable = false, length = 64)
    private String cacheKey;

    @Column(name = "input_text", nullable = false, length = 500)
    private String inputText;

    @Column(nullable = false, length = 50)
    private String model;

    @Column(nullable = false, length = 30)
    private String voice;

    @Column(name = "content_type", nullable = false, length = 30)
    private String contentType;

    @Column(nullable = false, length = 5_000_000)
    private byte[] audio;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
