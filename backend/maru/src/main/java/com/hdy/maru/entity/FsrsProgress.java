package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "fsrs_progress", 
    uniqueConstraints = {
        @UniqueConstraint(name = "unique_user_word_progress", columnNames = {"user_id", "word_id"})
    },
    indexes = {
        @Index(name = "idx_fsrs_user_word", columnList = "user_id, word_id"),
        @Index(name = "idx_fsrs_next_review", columnList = "next_review_date")
    }
)
@Getter
@Setter
@NoArgsConstructor
public class FsrsProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId; // 연관관계 매핑 (User)를 직접 맺지 않고 ID만 저장하여 강결합 회피 가능

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private Word word;

    @Column(nullable = false)
    private Integer state = 0; // 0: New, 1: Learning, 2: Review, 3: Relearning

    @Column(nullable = false)
    private Double stability = 0.0;

    @Column(nullable = false)
    private Double difficulty = 0.0;

    @Column(nullable = false)
    private Integer reps = 0;

    @Column(nullable = false)
    private Integer lapses = 0;

    @Column(name = "last_review")
    private LocalDateTime lastReview;

    @Column(name = "next_review_date", nullable = false)
    private LocalDateTime nextReviewDate;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    public void prePersist() {
        if (nextReviewDate == null) {
            nextReviewDate = LocalDateTime.now();
        }
    }
}
