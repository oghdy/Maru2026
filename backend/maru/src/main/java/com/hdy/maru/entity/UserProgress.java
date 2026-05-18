package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_progress", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "user_id", "lesson_id" })
}, indexes = {
        @Index(name = "idx_progress_user_id", columnList = "user_id"),
        @Index(name = "idx_progress_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
public class UserProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Many UserProgress records can belong to one User.
    // ON DELETE CASCADE is typically handled by the DB or JPA's
    // orphanRemoval/CascadeType.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "lesson_id", nullable = false, length = 50)
    private String lessonId;

    @Column(length = 20)
    private String status = "not_started"; // e.g., 'not_started', 'in_progress', 'completed'

    @Column(name = "current_step")
    private Integer currentStep = 0;

    private Integer score;

    @Column(name = "stars_earned")
    private Integer starsEarned;

    private Integer attempts = 0;

    @Column(name = "time_spent_seconds")
    private Integer timeSpentSeconds = 0;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
