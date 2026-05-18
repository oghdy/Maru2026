package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_cache", uniqueConstraints = {
                @UniqueConstraint(columnNames = { "input_text", "transformation_type" })
}, indexes = {
                @Index(name = "idx_ai_cache_lookup", columnList = "input_text, transformation_type")
})
@Getter
@Setter
@NoArgsConstructor
public class AiCache {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        @Column(name = "input_text", nullable = false, columnDefinition = "TEXT")
        private String inputText;

        @Column(name = "transformation_type", nullable = false, length = 500)
        private String transformationType; // e.g 'explore:tense' or 'combine:honorific,past,negative,nuance_only'

        @Column(name = "output_text", nullable = false, columnDefinition = "TEXT")
        private String outputText;

        @Column(name = "english_translation", columnDefinition = "TEXT")
        private String englishTranslation;

        @Column(columnDefinition = "TEXT")
        private String explanation;

        @CreationTimestamp
        @Column(name = "created_at", updatable = false)
        private LocalDateTime createdAt;
}
